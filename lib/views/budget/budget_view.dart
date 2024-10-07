import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'budget_details_screen.dart';

class BudgetView extends StatefulWidget {
  const BudgetView({Key? key}) : super(key: key);

  @override
  _BudgetViewState createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  final int _currentMonth = DateTime.now().month;
  final int _currentYear = DateTime.now().year;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<QuerySnapshot> _getBudgets() async {
    final user = _auth.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .where('month', isEqualTo: _currentMonth)
          .where('year', isEqualTo: _currentYear)
          .get();
    } else {
      return Future.error("User not found");
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
      body: FutureBuilder<QuerySnapshot>(
        future: _getBudgets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgets = snapshot.data?.docs ?? [];

          if (budgets.isEmpty) {
            return const Center(child: Text("Aucun budget disponible pour ce mois."));
          }

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
    );
  }
}