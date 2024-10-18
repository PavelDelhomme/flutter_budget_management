import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budget_management/models/good_models.dart';
class SavingsPage extends StatefulWidget {
  @override
  _SavingsPageState createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  double totalSavings = 0.0;
  List<Budget> budgets = [];

  Future<void> _calculateSavings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final budgetsSnapshot = await fs.FirebaseFirestore.instance
          .collection('budgets')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('month', descending: true)
          .get();

      double savings = 0.0;
      List<Budget> loadedBudgets = [];

      for (var doc in budgetsSnapshot.docs) {
        Budget budget = Budget.fromMap(doc.data());

        // Récupérer les transactions pour ce budget/mois
        List<Transaction> transactions = await _getTransactionsForBudget(budget);

        // Calculer les débits et crédits en passant les transactions
        double totalDebit = budget.calculateDebit(transactions);
        double totalCredit = budget.calculateCredit(transactions);
        double remaining = totalCredit - totalDebit;

        // Ajouter le reste aux économies
        savings += remaining;
        loadedBudgets.add(budget);
      }

      if (mounted) {
        setState(() {
          totalSavings = savings;
          budgets = loadedBudgets;
        });
      }
    }
  }

  /// Récupère les transactions pour un budget donné
  Future<List<Transaction>> _getTransactionsForBudget(Budget budget) async {
    final user = FirebaseAuth.instance.currentUser;
    List<Transaction> transactions = [];

    if (user != null) {
      // Récupérer les transactions de débit
      final debitSnapshot = await fs.FirebaseFirestore.instance
          .collection('debits')
          .where('user_id', isEqualTo: user.uid)
          .where('budget_id', isEqualTo: budget.id)
          .get();

      // Récupérer les transactions de crédit
      final creditSnapshot = await fs.FirebaseFirestore.instance
          .collection('credits')
          .where('user_id', isEqualTo: user.uid)
          .where('budget_id', isEqualTo: budget.id)
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
    _calculateSavings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résumé des Économies')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total des Économies: \$${totalSavings.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  Budget budget = budgets[index];
                  double remaining = budget.total_credit - budget.total_debit;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        'Budget du ${DateFormat('MMMM yyyy').format(budget.month.toDate())}',
                      ),
                      subtitle: Text('Reste: \$${remaining.toStringAsFixed(2)}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
