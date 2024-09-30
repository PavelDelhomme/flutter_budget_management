import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer mes Budgets'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('budgets').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var budgets = snapshot.data!.docs;

          if (budgets.isEmpty) {
            return const Center(child: Text('Aucun budget disponible.'));
          }

          return ListView.builder(
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              var budget = budgets[index];
              return ListTile(
                title: Text(budget['description']),
                subtitle: Text('Montant: \$${budget['totalAmount']}'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  // Action pour afficher les détails du budget
                },
              );
            },
          );
        },
      ),
    );
  }
}
