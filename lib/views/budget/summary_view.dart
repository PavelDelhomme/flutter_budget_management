import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  Future<void> _calculateTotalSummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Récupérer toutes les transactions depuis le début
      List<Transaction> transactions = await _getAllTransactions();

      if (transactions.isNotEmpty) {
        // Calculer les débits et crédits pour tous les mois
        double debitTotal = 0.0;
        double creditTotal = 0.0;

        for (var transaction in transactions) {
          if (transaction is Debit) {
            debitTotal += transaction.amount;
          } else if (transaction is Credit) {
            creditTotal += transaction.amount;
          }
        }

        print('Total Crédit = $creditTotal, Total Débit = $debitTotal, Montant restant = ${creditTotal - debitTotal}');

        setState(() {
          totalDebit = debitTotal;
          totalCredit = creditTotal;
          remainingAmount = totalCredit - totalDebit;
        });
      }
    }
  }


  Future<List<Transaction>> _getAllTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    List<Transaction> transactions = [];

    if (user != null) {
      // Récupérer toutes les transactions de débit
      final debitSnapshot = await fs.FirebaseFirestore.instance
          .collection('debits')
          .where('user_id', isEqualTo: user.uid)
          .get();

      // Récupérer toutes les transactions de crédit
      final creditSnapshot = await fs.FirebaseFirestore.instance
          .collection('credits')
          .where('user_id', isEqualTo: user.uid)
          .get();

      // Ajouter toutes les transactions récupérées à la liste
      for (var doc in debitSnapshot.docs) {
        transactions.add(Debit.fromMap(doc.data()));
      }
      for (var doc in creditSnapshot.docs) {
        transactions.add(Credit.fromMap(doc.data()));
      }
    }

    return transactions;
  }

  Future<void> _calculateMonthlySummary() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Récupérer les transactions pour le mois courant
      List<Transaction> transactions = await _getTransactionsForCurrentMonth();

      if (transactions.isNotEmpty) {
        // Calculer les débits et crédits
        double debitTotal = 0.0;
        double creditTotal = 0.0;

        for (var transaction in transactions) {
          if (transaction is Debit) {
            debitTotal += transaction.amount;
          } else if (transaction is Credit) {
            creditTotal += transaction.amount;
          }
        }

        setState(() {
          totalDebit = debitTotal;
          totalCredit = creditTotal;
          remainingAmount = totalCredit - totalDebit;
        });
      }
    }
  }

  Future<List<Transaction>> _getTransactionsForCurrentMonth() async {
    final user = FirebaseAuth.instance.currentUser;
    List<Transaction> transactions = [];

    if (user != null) {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

      // Récupérer les transactions de débit
      final debitSnapshot = await fs.FirebaseFirestore.instance
          .collection('debits')
          .where('user_id', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: fs.Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: fs.Timestamp.fromDate(endOfMonth))
          .get();

      // Récupérer les transactions de crédit
      final creditSnapshot = await fs.FirebaseFirestore.instance
          .collection('credits')
          .where('user_id', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: fs.Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: fs.Timestamp.fromDate(endOfMonth))
          .get();

      // Ajouter toutes les transactions récupérées à la liste
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
