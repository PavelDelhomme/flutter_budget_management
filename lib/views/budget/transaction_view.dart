import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var transactions = snapshot.data!.docs;

          if (transactions.isEmpty) {
            return const Center(child: Text('Aucune transaction disponible.'));
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              var transaction = transactions[index];
              return ListTile(
                title: Text(transaction['description']),
                subtitle: Text('Montant: \$${transaction['amount']}'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  // Action pour afficher les détails de la transaction
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action pour ajouter une nouvelle transaction
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
