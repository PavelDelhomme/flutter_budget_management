import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:budget_management/models/good_models.dart';
import 'package:intl/intl.dart';

class SummaryView extends StatefulWidget {
  const SummaryView({Key? key}) : super(key: key);

  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  double totalCredit = 0.0;
  double totalDebit = 0.0;
  double remainingAmount = 0.0;
  double projectedRemainingAmount = 0.0;
  double futureCredit = 0.0;
  double futureDebit = 0.0;
  double totalSavings = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotalSummary();
  }



  Future<void> _calculateTotalSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final now = DateTime.now();

      final budgetSnapshot = await fs.FirebaseFirestore.instance
          .collection('budgets')
          .where('user_id', isEqualTo: user.uid)
          .where('month', isEqualTo: now.month)
          .where('year', isEqualTo: now.year)
          .get();

      print("Budget Snapshot for ${now.month}/${now.year}: ${budgetSnapshot.docs}");

      if (budgetSnapshot.docs.isNotEmpty) {
        // Budget existe pour le mois
        final budgetData = budgetSnapshot.docs.first.data();
        setState(() {
          totalDebit = (budgetData['total_debit'] as num?)?.toDouble() ?? 0.0;
          totalCredit = (budgetData['total_credit'] as num?)?.toDouble() ?? 0.0;
          remainingAmount = totalCredit - totalDebit;
          //projectedRemainingAmount = remainingAmount + futureCredit - futureDebit + totalSavings;
          projectedRemainingAmount = remainingAmount + totalSavings;
        });
      } else {
        // Calcule des valeurs à aprtir des transactiosn
        double debitTotal = 0.0;
        double creditTotal = 0.0;

        var debitQuery = await FirebaseFirestore.instance
            .collection("debits")
            .where("user_id", isEqualTo: user.uid)
            .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, 1)))
            .where("date", isLessThan: Timestamp.fromDate(DateTime(now.year, now.month + 1, 1)))
            .get();

        var creditQuery = await FirebaseFirestore.instance
            .collection("credits")
            .where("user_id", isEqualTo: user.uid)
            .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, 1)))
            .where("date", isLessThan: Timestamp.fromDate(DateTime(now.year, now.month + 1, 1)))
            .get();

        for (var doc in debitQuery.docs) {
          debitTotal += (doc['amount'] as num).toDouble();
        }

        for (var doc in creditQuery.docs) {
          creditTotal += (doc['amount'] as num).toDouble();
        }

        setState(() {
          totalDebit = debitTotal;
          totalCredit = creditTotal;
          remainingAmount = totalCredit - totalDebit;
          projectedRemainingAmount = remainingAmount + totalSavings;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: Text('Résumé au ${DateFormat('dd/MM/yyyy').format(DateTime.now())}')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBudgetCard("Total Crédits", totalCredit.toStringAsFixed(2), Colors.green),
              _buildBudgetCard("Total Débits", totalDebit.toStringAsFixed(2), Colors.red),
              _buildBudgetCard("Montant Restant", remainingAmount.toStringAsFixed(2), Colors.blue),
              _buildBudgetCard("Montant Restant avec Économies", projectedRemainingAmount.toStringAsFixed(2), Colors.orange),
            ],
          ),
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
            Text("€$amount", style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
