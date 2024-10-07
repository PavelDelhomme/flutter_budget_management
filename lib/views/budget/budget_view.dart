import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../utils.dart';
import 'budget_details_screen.dart';

class BudgetView extends StatefulWidget {
  const BudgetView({Key? key}) : super(key: key);

  @override
  _BudgetViewState createState() => _BudgetViewState();
}


class _BudgetViewState extends State<BudgetView> {
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<QuerySnapshot> _getBudgets(int month, int year) async {
    final user = _auth.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();
    } else {
      return Future.error("User not found");
    }
  }

  void _changeMonth(int change) {
    setState(() {
      _currentMonth += change;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear += 1;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear -= 1;
      }

      // Charger les budgets du nouveau mois sélectionné
      _checkAndCreateSimulateBudget(_currentMonth, _currentYear);
    });
  }

  Future<void> _checkAndCreateSimulateBudget(int month, int year) async {
    final user = _auth.currentUser;
    if (user != null) {
      final budgetSnapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .get();

      // Si aucun budget n'existe pour le mois sélectionné, créer un budget simulé
      if (budgetSnapshot.docs.isEmpty) {
        final previousMonth = month == 1 ? 12 : month - 1;
        final previousYear = month == 1 ? year - 1 : year;

        final previousBudgetSnapshot = await FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user.uid)
            .where('month', isEqualTo: previousMonth)
            .where('year', isEqualTo: previousYear)
            .get();

        if (previousBudgetSnapshot.docs.isNotEmpty) {
          final previousBudget = previousBudgetSnapshot.docs.first;

          final newBudget = BudgetModel(
            id: generateBudgetId(),
            userId: user.uid,
            description: 'Budget du mois de ${DateFormat.MMMM('fr_FR').format(DateTime(year, month))} $year',
            totalAmount: previousBudget['totalAmount'],
            savings: previousBudget['savings'],
            month: month,
            year: year,
            startDate: Timestamp.fromDate(DateTime(year, month, 1)),
            endDate: Timestamp.fromDate(DateTime(year, month + 1, 0)),
            categories: (previousBudget['categories'] as List)
                .map((category) => CategoryModel.fromMap(category))
                .toList(),
          );

          // Simule la création du budget pour ce mois
          await FirebaseFirestore.instance.collection('budgets').doc(newBudget.id).set(newBudget.toMap());

          // Copier les transactions récurrentes du mois précédent
          await copyRecurringTransactions(previousBudget.id, newBudget.id);
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gérer mes Budgets"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // todo logique pour ajouter un nouveau budget
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation entre les mois
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                "${DateFormat.MMMM('fr_FR').format(DateTime(_currentYear, _currentMonth))} $_currentYear",
                style: const TextStyle(fontSize: 20),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),

          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: _getBudgets(_currentMonth, _currentYear),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final budgets = snapshot.data?.docs ?? [];

                if (budgets.isEmpty) {
                  // Afficher un message indiquant l'absence de budget, mais garder la navigation active
                  return const Center(child: Text("Aucun budget disponible pour ce mois."));
                }

                // Afficher les budgets disponibles
                return ListView.builder(
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    return ListTile(
                      title: Text(budget["description"]),
                      subtitle: Text("Montant total: \$${budget['totalAmount'].toStringAsFixed(2)}"),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BudgetDetailsScreen(budgetId: budget.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}