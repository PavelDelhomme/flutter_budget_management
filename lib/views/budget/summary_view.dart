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
  //double totalCredit = 0.0;
  //double totalDebit = 0.0;
  //double remainingAmount = 0.0;
  //double projectedRemainingAmount = 0.0;
  //double futureCredit = 0.0;
  //double futureDebit = 0.0;
  double totalSavings = 0.0;

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
      double debitTotal = debitSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
      double creditTotal = 0.0;

      await for (var creditSnapshot in creditStream) {
        creditTotal = creditSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
        break;
      }

      double remainingAmount = creditTotal - debitTotal;
      double projectedRemainingAmount = remainingAmount + totalSavings;

      return {
        'totalCredit': creditTotal,
        'totalDebit': debitTotal,
        'remainingAmount': remainingAmount,
        'projectedRemainingAmount': projectedRemainingAmount,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, double>>(
        stream: _getSummaryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Erreur lors du chargement des données de résumé"));
          }

          final data = snapshot.data!;
          double totalCredit = data['totalCredit'] ?? 0.0;
          double totalDebit = data['totalDebit'] ?? 0.0;
          double remainingAmount = data['remainingAmount'] ?? 0.0;
          double projectedRemainingAmount = data['projectedRemainingAmount'] ?? 0.0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBudgetCard("Total Crédits", totalCredit.toStringAsFixed(2), Colors.green),
                  _buildBudgetCard("Total Débits", totalDebit.toStringAsFixed(2), Colors.red),
                  _buildBudgetCard("Montant Restant", remainingAmount.toStringAsFixed(2), Colors.blue),
                  _buildBudgetCard("Montant Restant avec Economies", projectedRemainingAmount.toStringAsFixed(2), Colors.orange),
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
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text("€$amount", style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
