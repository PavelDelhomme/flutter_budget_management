import 'package:budget_management/views/budget/logix/add_transaction.dart';
import 'package:flutter/material.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: ListView.builder(
        itemCount: 5, // Remplacer par la longueur réelle de la liste de transactions
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Transaction ${index + 1}'),
            subtitle: const Text('Montant: \$100'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Action pour voir les détails de la transaction
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()  async {
          await addTransaction(
            description: 'Nouvelle Transaction',
            amount: 50.0
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
