import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../views/budget/add_budget_screen.dart';

class SummaryView extends StatefulWidget {
  const SummaryView({Key? key}) : super(key: key);

  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  Future<Map<String, dynamic>?> _getBudgetSummary() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final budgetSnapshot = await FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user.uid)
            .get();

        double totalBudget = 0.0;
        double totalExpenses = 0.0;
        double monthlyIncome = 0.0; // Variable pour stocker les revenus mensuels
        List<Map<String, dynamic>> categoriesData = [];

        // Récupération des données des budgets
        for (var doc in budgetSnapshot.docs) {
          totalBudget += doc['totalAmount'];
          for (var category in doc['categories']) {
            categoriesData.add({
              'name': category['name'],
              'allocatedAmount': category['allocatedAmount'],
              'spentAmount': category['spentAmount'] ?? 0.0,
            });
            totalExpenses += category['spentAmount'] ?? 0.0;
          }
        }

        // Récupération du revenu mensuel de l'utilisateur
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          monthlyIncome = userDoc['income'] ?? 0.0;
        }

        // Calcul du solde restant en tenant compte du revenu mensuel
        double remainingBalance = (totalBudget + monthlyIncome) - totalExpenses;

        return {
          'totalBudget': totalBudget,
          'totalExpenses': totalExpenses,
          'remainingBalance': remainingBalance,
          'categoriesData': categoriesData,
          'monthlyIncome': monthlyIncome,
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
      appBar: AppBar(
        title: const Text('Résumé du budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _getBudgetSummary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("Aucune donnée disponible pour le résumé du budget."));
            }

            final data = snapshot.data!;
            final totalBudget = data['totalBudget'] ?? 0.0;
            final totalExpenses = data['totalExpenses'] ?? 0.0;
            final remainingBalance = data['remainingBalance'] ?? 0.0;
            final monthlyIncome = data['monthlyIncome'] ?? 0.0;
            final categoriesData = data['categoriesData'] as List<Map<String, dynamic>>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenu mensuel: \$${monthlyIncome.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Budget: \$${totalBudget.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Dépenses: \$${totalExpenses.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  'Solde restant: \$${remainingBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: remainingBalance < 0 ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Répartition des catégories',
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
                        );
                      }).toList(),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
                    );
                  },
                  child: const Text('Créer un nouveau budget'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
