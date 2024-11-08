import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/general.dart';

class SummaryView extends StatefulWidget {
  const SummaryView({super.key});

  @override
  SummaryViewState createState() => SummaryViewState();
}

class SummaryViewState extends State<SummaryView> {
  double totalSavings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTotalSavings();
  }

  Future<void> _loadTotalSavings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      totalSavings = await _getTotalSavingsFromPreviousMonths(user.uid);
      setState(() {});
    }
  }

  Stream<Map<String, double>> _getBudgetStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({});
    }

    final now = DateTime.now();
    final budgetStream = fs.FirebaseFirestore.instance
        .collection("budgets")
        .where("user_id", isEqualTo: user.uid)
        .where("month", isEqualTo: now.month)
        .where("year", isEqualTo: now.year)
        .snapshots();

    return budgetStream.map((snapshot) {
      if (snapshot.docs.isEmpty) return {};

      final budget = snapshot.docs.first;
      double totalCredit = (budget['total_credit'] as num?)?.toDouble() ?? 0.0;
      double totalDebit = (budget['total_debit'] as num?)?.toDouble() ?? 0.0;
      double remainingAmount = (budget['remaining'] as num?)?.toDouble() ?? 0.0;
      double cumulativeRemainingAmount =
          (budget['cumulativeRemaining'] as num?)?.toDouble() ?? 0.0;

      return {
        'totalCredit': totalCredit,
        'totalDebit': totalDebit,
        'remainingAmount': remainingAmount,
        'cumulativeRemainingAmount': cumulativeRemainingAmount,
      };
    });
  }

  Stream<Map<String, double>> _getSummaryStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({});
    }

    final now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

    // Stream des transactions "debits" et "credits"
    final debitStream = FirebaseFirestore.instance
        .collection("debits")
        .where("user_id", isEqualTo: user.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots();

    final creditStream = FirebaseFirestore.instance
        .collection("credits")
        .where("user_id", isEqualTo: user.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots();

    return debitStream.asyncMap((debitSnapshot) async {
      double debitTotal = debitSnapshot.docs
          .fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
      double creditTotal = 0.0;

      await for (var creditSnapshot in creditStream) {
        creditTotal = creditSnapshot.docs
            .fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
        break;
      }

      double remainingAmount = creditTotal - debitTotal;
      double projectedRemainingAmount = remainingAmount + totalSavings;

      return {
        'totalCredit': creditTotal,
        'totalDebit': debitTotal,
        'remainingAmount': remainingAmount,
        'projectedRemainingAmount': projectedRemainingAmount,
        'savings': totalSavings,
      };
    });
  }

  Future<double> _getTotalSavingsFromPreviousMonths(String userId) async {
    final previousBudgets = await FirebaseFirestore.instance
        .collection("budgets")
        .where("user_id", isEqualTo: userId)
        .where("month", isLessThan: DateTime.now().month)
        .where("year", isEqualTo: DateTime.now().year)
        .get();

    double savingsSum = 0.0;
    for (var budget in previousBudgets.docs) {
      double remaining = (budget['total_credit'] as num).toDouble() -
          (budget['total_debit'] as num).toDouble();
      if (remaining > 0) {
        savingsSum += remaining;
      }
    }
    return savingsSum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, double>>(
        stream: _getSummaryStream(),
        builder: (context, snapshot) {
          Widget? checkResult = checkSnapshot(snapshot,
              errorMessage: "Erreur lors du chargement des données de résumé");
          if (checkResult != null) return checkResult;

          final data = snapshot.data!;
          double totalCredit = data['totalCredit'] ?? 0.0;
          double totalDebit = data['totalDebit'] ?? 0.0;
          double remainingAmount = data['remainingAmount'] ?? 0.0;
          double projectedRemainingAmount =
              data['projectedRemainingAmount'] ?? 0.0;
          double totalSavings = data['savings'] ?? 0.0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBudgetCard("Total Crédits",
                      totalCredit.toStringAsFixed(2), Colors.green),
                  _buildBudgetCard("Total Débits",
                      totalDebit.toStringAsFixed(2), Colors.red),
                  _buildBudgetCard("Montant Restant",
                      remainingAmount.toStringAsFixed(2), Colors.blue),
                  _buildBudgetCard("Economies déjà acquises",
                      totalSavings.toStringAsFixed(2), Colors.grey),
                  _buildBudgetCard(
                      "Montant Restant avec Economies",
                      projectedRemainingAmount.toStringAsFixed(2),
                      Colors.orange),
                ],
              ),
            ),
          );
        },
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
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text("€$amount",
                style: TextStyle(
                    fontSize: 20, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
