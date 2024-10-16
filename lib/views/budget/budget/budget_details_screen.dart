import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetDetailsScreen extends StatefulWidget {
  final String budgetId;

  const BudgetDetailsScreen({Key? key, required this.budgetId}) : super(key: key);

  @override
  _BudgetDetailsScreenState createState() => _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends State<BudgetDetailsScreen> {
  Future<Map<String, dynamic>> _getBudgetDetails() async {
    final budgetSnapshot = await FirebaseFirestore.instance.collection('budgets').doc(widget.budgetId).get();
    return budgetSnapshot.data() as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> _getTransactions() async {
    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('transactions')
        .where('budgetId', isEqualTo: widget.budgetId)
        .get();

    return transactionsSnapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du budget'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getBudgetDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgetData = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mois: ${budgetData['month'].toDate().month}/${budgetData['year'].toDate().year}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Débit: \$${budgetData['total_debit'].toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, color: Colors.red),
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Crédit: \$${budgetData['total_credit'].toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, color: Colors.green),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Transactions:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getTransactions(),
                    builder: (context, transactionSnapshot) {
                      if (!transactionSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final transactions = transactionSnapshot.data!;
                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final isDebit = transaction['type'];
                          final transactionType = isDebit ? "Débit" : "Crédit";
                          final amount = isDebit
                              ? transaction['amount'].toStringAsFixed(2)
                              : transaction['amount'].toStringAsFixed(2);

                          return ListTile(
                            title: Text(
                              '$transactionType: \$${amount}',
                              style: TextStyle(
                                color: isDebit ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Catégorie: ${transaction['categorie_id']}'),
                            trailing: Text(
                              '${transaction['date'].toDate().day}/${transaction['date'].toDate().month}/${transaction['date'].toDate().year}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
