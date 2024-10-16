import 'dart:developer';
import 'package:budget_management/views/budget/transaction/transaction_form_screen.dart';
import 'package:budget_management/views/budget/transaction/transaction_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({Key? key}) : super(key: key);

  @override
  _TransactionsViewState createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  void _editTransaction(BuildContext context, DocumentSnapshot transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(transaction: transaction),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _addNewTransaction(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionFormScreen(),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  void _deleteTransaction(BuildContext context, DocumentSnapshot transaction) async {
    // Confirmation avant suppression
    bool confirm = await _showDeleteConfirmation(context);
    if (!confirm) return;  // Si l'utilisateur annule

    // Supprimer la transaction de la collection Firestore
    await FirebaseFirestore.instance.collection('transactions').doc(transaction.id).delete();

    // Afficher un message de succès après suppression et rafraichir la liste
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction supprimée avec succès.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("transactions")
            .where("userId", isEqualTo: user?.uid)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var transactions = snapshot.data!.docs;
          Map<String, List<DocumentSnapshot>> transactionsByMonth = {};

          for (var transaction in transactions) {
            DateTime date = (transaction['date'] as Timestamp).toDate();
            String monthKey = DateFormat.yMMMM('fr_FR').format(date);

            if (!transactionsByMonth.containsKey(monthKey)) {
              transactionsByMonth[monthKey] = [];
            }
            transactionsByMonth[monthKey]!.add(transaction);
          }

          if (transactionsByMonth.isEmpty) {
            return const Center(child: Text("Aucune transaction disponible."));
          }

          return ListView.builder(
            itemCount: transactionsByMonth.keys.length,
            itemBuilder: (context, index) {
              String monthKey = transactionsByMonth.keys.elementAt(index);
              var monthTransactions = transactionsByMonth[monthKey]!;

              return ExpansionTile(
                title: Text(monthKey),
                children: monthTransactions.isEmpty
                    ? [
                  ListTile(
                    title: Text(
                      "Aucune transaction pour le mois de $monthKey.",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ]
                    : monthTransactions.map((transaction) {
                  DateTime date = (transaction['date'] as Timestamp).toDate();
                  return Slidable(
                    key: Key(transaction.id),
                    startActionPane: ActionPane(
                      motion: const StretchMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            _editTransaction(context, transaction);
                          },
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          label: "Modifier",
                        ),
                      ],
                    ),
                    endActionPane: ActionPane(
                      motion: const StretchMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (BuildContext ctx) async {
                            bool confirm = await _showDeleteConfirmation(context);
                            if (confirm) {
                              _deleteTransaction(ctx, transaction);
                            }
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Supprimer',
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(transaction['description']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Description : ${transaction['description']}"),
                          Text("Montant : \$${transaction['amount'].toStringAsFixed(2)}"),
                        ],
                      ),
                      trailing: Text(DateFormat('dd MMM yyyy').format(date)),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                          ),
                          builder: (context) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: TransactionDetailsModal(transaction: transaction),
                            );
                          },
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNewTransaction(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: const Text("Êtes-vous sûr de vouloir supprimer cette transaction ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
