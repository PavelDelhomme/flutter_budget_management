import 'dart:developer';

import 'package:budget_management/views/budget/transaction/transaction_details_modal.dart';
import 'package:budget_management/views/budget/transaction/transaction_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TransactionsReccuringView extends StatefulWidget {
  const TransactionsReccuringView({super.key});

  @override
  TransactionsReccuringViewSate createState() =>
      TransactionsReccuringViewSate();
}

class TransactionsReccuringViewSate extends State<TransactionsReccuringView> {
  /*
  Les transactions de crédit récurrrente soint afficher ici et permettre de supprimer la réccurence à partir du mois ou je veux supprimer la réccurence
  Il faut donc juste avoir a décocher la récurrence et supprimer le caractère récuren ou la suppprimer pour le mois et alors cela supprimer pour les mois suivant
   */
  DateTime selectedMonth = DateTime.now();
  double totalDebit = 0.0;
  double totalCredit = 0.0;
  Map<String, String> categoryMap = {}; // Stocker les noms des catégories

  Future<Map<String, dynamic>> _getTransactionsForSelectedMonth() async {
    final user = FirebaseAuth.instance.currentUser;
    DateTime startOfMonth =
        DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime endOfMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    List<QueryDocumentSnapshot> transactions = [];
    double debitTotal = 0.0;
    double creditTotal = 0.0;

    // Charger les transactions de débit et crédit du mois sélectionné
    var debitQuery = await FirebaseFirestore.instance
        .collection("debits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .where("isRecurring", isEqualTo: true)
        .get();

    var creditQuery = await FirebaseFirestore.instance
        .collection("credits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .where("isRecurring", isEqualTo: true)
        .get();

    // Calcul des totaux et ajout des transactions récupérées
    for (var doc in debitQuery.docs) {
      debitTotal += (doc['amount'] as num).toDouble();
      transactions.add(doc);
    }
    for (var doc in creditQuery.docs) {
      creditTotal += (doc['amount'] as num).toDouble();
      transactions.add(doc);
    }

    return {
      'transactions': transactions,
      'totalDebit': debitTotal,
      'totalCredit': creditTotal,
    };
  }

  void _updateMonthlyTotals() async {
    final data = await _getTransactionsForSelectedMonth();
    setState(() {
      totalDebit = data['totalDebit'] ?? 0.0;
      totalCredit = data['totalCredit'] ?? 0.0;
    });
  }

  Future<void> _toggleRecurrence(DocumentSnapshot transaction) async {
    bool isRecurring = transaction['isRecurring'];
    String collection = transaction.reference.parent.id;

    await FirebaseFirestore.instance
        .collection(collection)
        .doc(transaction.id)
        .update({'isRecurring': !isRecurring});

    setState(() {}); // Rafraîchir la vue
  }

  Future<void> deleteTransactionAndFutureOccurrences(
      DocumentSnapshot transaction) async {
    bool confirm = await _showDeleteConfirmation(context);
    if (!confirm) return;

    String collection = transaction.reference.parent.id;
    DateTime transactionDate = (transaction['date'] as Timestamp).toDate();

    await FirebaseFirestore.instance
        .collection(collection)
        .doc(transaction.id)
        .delete();

    // Supprimer les occurrences futures de la transaction
    final futureTransactions = await FirebaseFirestore.instance
        .collection(collection)
        .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('isRecurring', isEqualTo: true)
        .where('date', isGreaterThan: Timestamp.fromDate(transactionDate))
        .where('categorie_id', isEqualTo: transaction['categorie_id'])
        .get();

    for (var futureTransaction in futureTransactions.docs) {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(futureTransaction.id)
          .delete();
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Transactions futures supprimées avec succès.")),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _updateMonthlyTotals();
  }

  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final categorySnapshot = await FirebaseFirestore.instance
          .collection("categories")
          .where("userId", isEqualTo: user.uid)
          .get();

      setState(() {
        for (var doc in categorySnapshot.docs) {
          categoryMap[doc.id] = doc['name'];
        }
      });
    }
  }

  Future<String> getCategoryName(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) {
      return "Sans catégorie"; // Retourne "Sans catégorie" si l'id est absent
    }

    if (categoryMap.containsKey(categoryId)) {
      return categoryMap[categoryId]!;
    } else {
      var categorySnapshot = await FirebaseFirestore.instance
          .collection("categories")
          .doc(categoryId)
          .get();
      if (categorySnapshot.exists) {
        String categoryName = categorySnapshot['name'];
        categoryMap[categoryId] =
            categoryName; // Cache le nom pour les prochaines utilisations
        return categoryName;
      } else {
        return "Sans catégorie";
      }
    }
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
      _updateMonthlyTotals();
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
      _updateMonthlyTotals();
    });
  }

  void _editTransaction(
      BuildContext context, DocumentSnapshot transaction) async {
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

  void _deleteTransaction(
      BuildContext context, DocumentSnapshot transaction) async {
    bool confirm = await _showDeleteConfirmation(context);
    if (!confirm) return;

    bool isDebit = transaction.reference.parent.id == 'debits';
    String collection = isDebit ? 'debits' : 'credits';

    // Supprimer la transaction de la collection appropriée
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(transaction.id)
        .delete();

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
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            log("Clique sur le mois");
          },
          child: Text(DateFormat.yMMMM('fr_FR').format(selectedMonth)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _previousMonth,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _nextMonth,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getTransactionsForSelectedMonth(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                  child: Text("Erreur lors du chargements des transactions"));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                  child: Text("Aucune transaction disponible."));
            }

            var data = snapshot.data!;
            List<QueryDocumentSnapshot> transactions =
                data['transactions'] ?? [];
            totalDebit = data['totalDebit'] ?? 0.0;
            totalCredit = data['totalCredit'] ?? 0.0;

            // transactions par jour
            Map<String, List<QueryDocumentSnapshot>> transactionsByDays = {};

            for (var transaction in transactions) {
              DateTime date = (transaction['date'] as Timestamp).toDate();
              String dayKey =
                  DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);

              if (!transactionsByDays.containsKey(dayKey)) {
                transactionsByDays[dayKey] = [];
              }
              transactionsByDays[dayKey]!.add(transaction);
            }

            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transactions récurrentes',
                          style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Crédit : €${totalCredit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Total Débit : €${totalDebit.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            'Économies : €${(totalCredit - totalDebit).toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: transactionsByDays.keys.length,
                    itemBuilder: (context, index) {
                      String dayKey = transactionsByDays.keys.elementAt(index);
                      var transactionsForDay = transactionsByDays[dayKey]!;

                      // Calculer le montant total des transactions pour chaque jour
                      double totalAmount = 0;
                      for (var transaction in transactionsForDay) {
                        totalAmount += transaction['amount'];
                      }

                      return ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                dayKey,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Total: €${totalAmount.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        children: transactionsForDay.map((transaction) {
                          bool isDebit =
                              transaction.reference.parent.id == 'debits';
                          String transactionType = isDebit ? 'Débit' : 'Crédit';

                          return FutureBuilder<String>(
                            future: isDebit
                                ? getCategoryName(transaction['categorie_id'])
                                : Future.value("Sans catégorie"),
                            builder: (context, snapshot) {
                              String categoryName =
                                  snapshot.data ?? 'Sans catégorie';
                              Color backgroundColor =
                                  Colors.greenAccent.withOpacity(0.2);

                              return Container(
                                color: backgroundColor,
                                child: Slidable(
                                  key: Key(transaction.id),
                                  startActionPane: ActionPane(
                                    motion: const StretchMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) {
                                          _editTransaction(
                                              context, transaction);
                                        },
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit,
                                        label: 'Modifier',
                                      ),
                                    ],
                                  ),
                                  endActionPane: ActionPane(
                                    motion: const StretchMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) async {
                                          bool confirm =
                                              await _showDeleteConfirmation(
                                                  context);
                                          if (confirm) {
                                            _deleteTransaction(
                                                context, transaction);
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${transaction['amount'].toStringAsFixed(2)} €',
                                          style: TextStyle(
                                              color: isDebit
                                                  ? Colors.red
                                                  : Colors.green),
                                        ),
                                        Text(transactionType),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(categoryName),
                                        Text(transaction['notes'] ??
                                            'Aucune note'),
                                      ],
                                    ),
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20.0)),
                                        ),
                                        builder: (context) {
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              bottom: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom,
                                            ),
                                            child: TransactionDetailsModal(
                                                transaction: transaction),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                )
              ],
            );
          },
        ),
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
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirmer la suppression"),
              content: const Text(
                  "Êtes-vous sûr de vouloir supprimer cette transaction ?"),
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
          context: context,
        ) ??
        false;
  }
}
