import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_color/random_color.dart';  // Importation pour générer des couleurs aléatoires
import '../../services/income_service.dart';

class SummaryView extends StatefulWidget {
  const SummaryView({Key? key}) : super(key: key);

  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  final RandomColor _randomColor = RandomColor();  // Instance de RandomColor

  @override
  void initState() {
    super.initState();
    setState(() {
      _getBudgetSummary();
    });
  }

  Future<Map<String, dynamic>?> _getBudgetSummary() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final budgetSnapshot = await FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user.uid)
            .where('month', isEqualTo: DateTime.now().month)
            .where('year', isEqualTo: DateTime.now().year)
            .get();

        if (budgetSnapshot.docs.isEmpty) return null;

        double totalBudget = 0.0;
        double totalExpenses = 0.0;
        double monthlyIncome = 0.0;
        double totalAllocated = 0.0;
        double remainingBalance = 0.0;
        double forecastBalance = 0.0;
        List<Map<String, dynamic>> categoriesData = [];

        for (var doc in budgetSnapshot.docs) {
          totalBudget += (doc['totalAmount'] as num).toDouble();
          for (var category in doc['categories']) {
            categoriesData.add({
              'name': category['name'],
              'allocatedAmount': (category['allocatedAmount'] as num).toDouble(),
              'spentAmount': (category['spentAmount'] as num?)?.toDouble() ?? 0.0,
            });
            totalExpenses += (category['spentAmount'] as num?)?.toDouble() ?? 0.0;
            totalAllocated += (category['allocatedAmount'] as num).toDouble();
          }
        }

        final incomes = await getUserIncomes(user.uid, DateTime.now().month, DateTime.now().year);
        monthlyIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
        forecastBalance = monthlyIncome - totalAllocated;
        remainingBalance = totalAllocated - totalExpenses;

        return {
          'totalBudget': totalBudget,
          'totalExpenses': totalExpenses,
          'monthlyIncome': monthlyIncome,
          'forecastBalance': forecastBalance,
          'totalAllocated': totalAllocated,
          'remainingBalance': remainingBalance,
          'categoriesData': categoriesData,
        };
      } catch (e) {
        print("Erreur lors de la récupération des données du budget : $e");
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("transactions")
              .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("Aucune donnée disponible pour le résumé du budget."));
            }

            final transactionsData = snapshot.data!;


            return FutureBuilder<Map<String, dynamic>?>(
              future: _getBudgetSummary(),
              builder: (context, budgetSnapshot) {
                if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!budgetSnapshot.hasData || budgetSnapshot.data == null) {
                  return const Center(child: Text("Aucune donnée disponible pour le résumé du budget."));
                }

                final data = budgetSnapshot.data!;
                final totalBudget = data['totalBudget'] ?? 0.0;
                final totalExpenses = data['totalExpenses'] ?? 0.0;
                final monthlyIncome = data['monthlyIncome'] ?? 0.0;
                final forecastBalance = data['forecastBalance'] ?? 0.0;
                final totalAllocated = data['totalAllocated'] ?? 0.0;
                final remainingBalance = data['remainingBalance'] ?? 0.0;
                final categoriesData = data['categoriesData'] as List<Map<String, dynamic>>;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budget : \$${totalBudget.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Dépenses Réelles : \$${totalExpenses.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      'Revenu Mensuel Total : \$${monthlyIncome.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      'Solde Restant : \$${remainingBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        color: remainingBalance < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    Text(
                      'Solde Prévisionnel : \$${forecastBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        color: forecastBalance < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    Text(
                      'Dépenses Restantes : \$${(totalAllocated - totalExpenses).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        color: (totalAllocated - totalExpenses) < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Répartition des Catégories',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: categoriesData.map((category) {
                            return PieChartSectionData(
                              value: category['allocatedAmount'],
                              title: category['name'],
                              color: _randomColor.randomColor(),  // Génération de couleurs uniques
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
