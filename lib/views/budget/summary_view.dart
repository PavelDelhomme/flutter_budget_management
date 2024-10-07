import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../views/budget/add_budget_screen.dart';
import '../../services/income_service.dart';

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
            .where('month', isEqualTo: DateTime.now().month)
            .where('year', isEqualTo: DateTime.now().year)
            .get();

        if (budgetSnapshot.docs.isEmpty) return null;

        double totalBudget = 0.0;
        double totalExpenses = 0.0;
        double monthlyIncome = 0.0;
        double totalAllocated = 0.0; // Montants alloués
        List<Map<String, dynamic>> categoriesData = [];

        for (var doc in budgetSnapshot.docs) {
          totalBudget += (doc['totalAmount'] as num).toDouble();  // Somme des budgets prévus
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
        double remainingBalance = monthlyIncome - totalExpenses;
        double forecastBalance = monthlyIncome - totalAllocated; // Solde prévisionnel

        return {
          'totalBudget': totalBudget,
          'totalExpenses': totalExpenses,
          'remainingBalance': remainingBalance,
          'forecastBalance': forecastBalance,
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
            final forecastBalance = data['forecastBalance'] ?? 0.0;
            final categoriesData = data['categoriesData'] as List<Map<String, dynamic>>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Budget (Prévu): \$${totalBudget.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Dépenses (Réelles): \$${totalExpenses.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  'Solde restant: \$${remainingBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: remainingBalance < 0 ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  'Solde prévisionnel en fin de mois: \$${forecastBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    color: forecastBalance < 0 ? Colors.red : Colors.green,
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
              ],
            );
          },
        ),
      ),
    );
  }
}
