import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_color/random_color.dart';  // Importation pour générer des couleurs aléatoires
import 'package:budget_management/models/good_models.dart';

class SummaryView extends StatefulWidget {
  const SummaryView({Key? key}) : super(key: key);

  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  double totalCredit = 0.0;
  double totalDebit = 0.0;
  double remainingAmount = 0.0;

  Future<void> _calculateMonthlySummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);

      final budgetSnapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .where('user_id', isEqualTo: user.uid)
          .where('month', isEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      if (budgetSnapshot.docs.isNotEmpty) {
        Budget budget = Budget.fromMap(budgetSnapshot.docs.first.data());

        totalDebit = await budget.calculateDebit();
        totalCredit = await budget.calculateCredit();
        remainingAmount = totalCredit - totalDebit;

        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _calculateMonthlySummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résumé du Mois en Cours')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetCard("Total Crédits", totalCredit.toStringAsFixed(2), Colors.green),
            _buildBudgetCard("Total Débits", totalDebit.toStringAsFixed(2), Colors.red),
            const SizedBox(height: 20),
            _buildBudgetCard("Montant Restant", remainingAmount.toStringAsFixed(2), Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(String title, String amount, Color color) {
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text(
              "\$$amount",
              style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
