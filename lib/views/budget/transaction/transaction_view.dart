import 'dart:developer';
import 'package:budget_management/views/budget/transaction/transaction_form_screen.dart';
import 'package:budget_management/views/budget/transaction/transaction_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({Key? key}) : super(key: key);

  @override
  _TransactionsViewState createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  Future<List<QueryDocumentSnapshot>> _getTransactionsForCurrentMonth() async {
    final user = FirebaseAuth.instance.currentUser;
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);

    // Récupérer les débits
    var debitQuery = await FirebaseFirestore.instance
        .collection("debits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(DateTime(now.year, now.month + 1, 1)))
        .get();

    // Récupérer les crédits
    var creditQuery = await FirebaseFirestore.instance
        .collection("credits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(DateTime(now.year, now.month + 1, 1)))
        .get();

    // Combiner les deux listes de documents
    return [...debitQuery.docs, ...creditQuery.docs];
  }



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
    return Scaffold(
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _getTransactionsForCurrentMonth(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var transactions = snapshot.data!;
          Map<String, Map<String, List<QueryDocumentSnapshot>>> transactionsByDay = {};

          // Organiser les transactions par jour
          for (var transaction in transactions) {
            DateTime date = (transaction['date'] as Timestamp).toDate();
            String dayKey = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
            String timeKey = DateFormat('HH:mm').format(date);

            if (!transactionsByDay.containsKey(dayKey)) {
              transactionsByDay[dayKey] = {};
            }

            if (!transactionsByDay[dayKey]!.containsKey(timeKey)) {
              transactionsByDay[dayKey]![timeKey] = [];
            }

            transactionsByDay[dayKey]![timeKey]!.add(transaction);
          }

          if (transactionsByDay.isEmpty) {
            return const Center(child: Text("Aucune transaction disponible."));
          }

          return ListView.builder(
            itemCount: transactionsByDay.keys.length,
            itemBuilder: (context, index) {
              String dayKey = transactionsByDay.keys.elementAt(index);
              var transactionsForDay = transactionsByDay[dayKey]!;

              // Calculer le montant total des transactions pour chaque jour
              double totalAmount = 0;
              transactionsForDay.forEach((timeKey, trans) {
                for (var transaction in trans) {
                  totalAmount += transaction['amount'];
                }
              });

              return ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dayKey),
                    Text('Total: \$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                children: transactionsForDay.entries.map((entry) {
                  String timeKey = entry.key;
                  List<QueryDocumentSnapshot> transactionsAtTime = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: transactionsAtTime.map((transaction) {
                      bool isDebit = transaction.reference.parent.id == 'debits';
                      String? category = isDebit ? transaction['categorie_id'] : null;

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
                              onPressed: (context) async {
                                bool confirm = await _showDeleteConfirmation(context);
                                if (confirm) {
                                  _deleteTransaction(context, transaction);
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
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$timeKey'),
                              Text('\$${transaction['amount'].toStringAsFixed(2)}'),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isDebit && category != null)
                                Text('Catégorie: $category'),
                              Text(transaction['notes'] ?? 'Aucune note'),
                            ],
                          ),
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
