import 'package:budget_management/views/budget/add_transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionsView extends StatelessWidget {
  final String? budgetId;

  const TransactionsView({Key? key, this.budgetId}) : super(key: key);

  Future<String?> _getDefaultBudgetId(BuildContext context) async {
    if (budgetId != null && budgetId!.isNotEmpty) {
      return budgetId;  // Utilise le budget actuel s'il est défini
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Récupère le premier budget de l'utilisateur
        final budgetsSnapshot = await FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (budgetsSnapshot.docs.isNotEmpty) {
          return budgetsSnapshot.docs.first.id;
        }
      }
      return null;
    }
  }

  void _editTransaction(DocumentSnapshot transaction) {
    // Logique pour éditer une transaction
    // Par exemple, ouvrir une page d'édition similaire à AddTransactionScreen
  }

  void _deleteTransaction(BuildContext context, DocumentSnapshot transaction) async {
    // Suppression de la transaction
    await FirebaseFirestore.instance.collection('transactions').doc(transaction.id).delete();

    // Mise à jour du montant dépensé dans la catégorie associée
    final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(transaction['budgetId']).get();
    if (budgetDoc.exists) {
      final List<dynamic> categories = budgetDoc.data()?['categories'] ?? [];
      final selectedCategoryData = categories.firstWhere(
            (category) => category['name'] == transaction['category'],
        orElse: () => {},
      );

      if (selectedCategoryData.isNotEmpty) {
        final updatedCategory = {
          ...selectedCategoryData,
          'spentAmount': (selectedCategoryData['spentAmount'] ?? 0.0) - transaction['amount'],
        };

        await FirebaseFirestore.instance.collection('budgets').doc(transaction['budgetId']).update({
          'categories': FieldValue.arrayRemove([selectedCategoryData]),
        });

        await FirebaseFirestore.instance.collection('budgets').doc(transaction['budgetId']).update({
          'categories': FieldValue.arrayUnion([updatedCategory]),
        });
      }
    }

    // Afficher une notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaction supprimée avec succès.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: budgetId != null
            ? FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user?.uid)
            .where('budgetId', isEqualTo: budgetId)
            .snapshots()
            : FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
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
                subtitle: Text('Montant: \$${transaction['amount'].toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editTransaction(transaction);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteTransaction(context, transaction);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  // Afficher les détails de la transaction
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? selectedBudgetId = await _getDefaultBudgetId(context);

          if (selectedBudgetId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTransactionScreen(budgetId: selectedBudgetId)
              ),
            );
          } else {
            // Aucun budget disponible
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Aucun budget disponible pour ajouter une transaction.")),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
