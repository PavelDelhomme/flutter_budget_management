import 'package:cloud_firestore/cloud_firestore.dart' as fs;
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
  double totalSavings = 0.0;
  double futureCredit = 0.0;
  double futureDebit = 0.0;
  double projectedRemainingAmount = 0.0;

  Future<void> _calculateTotalSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      List<Transaction> transactions = await _getAllTransactions();
      double debitTotal = 0.0;
      double creditTotal = 0.0;
      double futureDebitTotal = 0.0;
      double futureCreditTotal = 0.0;
      double savingsTotal = 0.0;

      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);

      for (var transaction in transactions) {
        // Vérifier les transactions validées
        if (transaction is Debit && transaction.isValidated) {
          debitTotal += transaction.amount;
        } else if (transaction is Credit && transaction.isValidated) {
          creditTotal += transaction.amount;
        }

        // Inclure les transactions récurrentes non validées comme prévisions
        if (transaction.isRecurring && transaction.date.isBefore(startOfMonth)) {
          if (transaction is Debit && !transaction.isValidated) {
            futureDebitTotal += transaction.amount;
          } else if (transaction is Credit && !transaction.isValidated) {
            futureCreditTotal += transaction.amount;
          }
        }
      }

      // Récupérer les économies de SavingsPage
      final savingsSnapshot = await fs.FirebaseFirestore.instance
          .collection('savings')
          .where('user_id', isEqualTo: user.uid)
          .get();

      for (var doc in savingsSnapshot.docs) {
        savingsTotal += (doc['amount'] as num).toDouble();
      }

      // Vérifier si le widget est monté avant d'appeler setState()
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

  Future<List<Transaction>> _getAllTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    List<Transaction> transactions = [];

    if (user != null) {
      final debitSnapshot = await fs.FirebaseFirestore.instance
          .collection('debits')
          .where('user_id', isEqualTo: user.uid)
          .get();

      final creditSnapshot = await fs.FirebaseFirestore.instance
          .collection('credits')
          .where('user_id', isEqualTo: user.uid)
          .get();

      for (var doc in debitSnapshot.docs) {
        transactions.add(Debit.fromMap(doc.data()));
      }
      for (var doc in creditSnapshot.docs) {
        transactions.add(Credit.fromMap(doc.data()));
      }
    }

    return transactions;
  }

  @override
  void initState() {
    super.initState();
    _calculateTotalSummary();
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
