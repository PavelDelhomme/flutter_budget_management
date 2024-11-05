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
      //List<Transaction> transactions = await _getAllTransactions();
      double debitTotal = 0.0;
      double creditTotal = 0.0;
      double futureDebitTotal = 0.0;
      double futureCreditTotal = 0.0;
      double savingsTotal = 0.0;

      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);

      final transactionsSnapshot = await fs.FirebaseFirestore.instance
          .collectionGroup('transactions')
          .where('user_id', isEqualTo: user.uid)
          .get();

      for (var doc in transactionsSnapshot.docs) {
        var transactionData = doc.data();
        var isDebit = transactionData['type'] == 'debit';
        var isValidated = transactionData['isValidated'] ?? false;
        var amount = (transactionData['amount'] as num).toDouble();
        var isRecurring = transactionData['isRecurring'] ?? false;
        var transactionDate = (transactionData['date'] as Timestamp).toDate();

        // Calculer les totaux actuels validés
        if (isValidated) {
          if (isDebit) {
            debitTotal += amount;
          } else {
            creditTotal += amount;
          }
        }

        // Ajouter les transactions récurrentes futures comme prévisions
        if (isRecurring && !isValidated && transactionDate.isBefore(startOfMonth)) {
          if (isDebit) {
            futureDebitTotal += amount;
          } else {
            futureCreditTotal += amount;
          }
        }

        // Récupérer les économies de la collection `savings`
        final savingsSnapshot = await fs.FirebaseFirestore.instance
            .collection('savings')
            .where('user_id', isEqualTo: user.uid)
            .get();

        for (var doc in savingsSnapshot.docs) {
          savingsTotal += (doc['amount'] as num).toDouble();
        }

        if (mounted) {
          setState(() {
            totalDebit = debitTotal;
            totalCredit = creditTotal;
            remainingAmount = totalCredit - totalDebit;
            futureDebit = futureDebitTotal;
            futureCredit = futureCreditTotal;
            totalSavings = savingsTotal;
            projectedRemainingAmount = remainingAmount + futureCredit - futureDebit + totalSavings;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: Text('Résumé au $formattedDate')),
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
              const SizedBox(height: 20),
              _buildBudgetCard("Total Crédits Prévu", futureCredit.toStringAsFixed(2), Colors.green),
              _buildBudgetCard("Total Débits Prévu", futureDebit.toStringAsFixed(2), Colors.red),
              _buildBudgetCard("Montant Restant Prévu", projectedRemainingAmount.toStringAsFixed(2), Colors.purple),
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
            Text(
              "€$amount",
              style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
