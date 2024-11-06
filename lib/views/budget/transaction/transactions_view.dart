import 'dart:developer';
import 'package:budget_management/utils/budgets.dart';
import 'package:budget_management/utils/general.dart';
import 'package:budget_management/views/budget/transaction/transaction_form_screen.dart';
import 'package:budget_management/views/budget/transaction/transaction_details_modal.dart';
import 'package:budget_management/views/budget/transaction/transactions_reccuring_view.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../budget/budget_details_screen.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({Key? key}) : super(key: key);

  @override
  _TransactionsViewState createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  DateTime selectedMonth = DateTime.now();
  double totalDebit = 0.0;
  double totalCredit = 0.0;
  String transactionFilter = "all"; // "all", "debits", "credits"
  Map<String, String> categoryMap = {}; // Stocker les noms des catégories

  Future<Map<String, dynamic>> _getTransactionsForSelectedMonth() async {
    final creditsData = await _getCreditTransactionsForSelectedMonth();
    final debitsData = await _getDebitTransactionsForSelectedMonth();

    // Combinaison des transactions de crédits et de débits
    List<QueryDocumentSnapshot> transactions = [
      ...creditsData['transactions'],
      ...debitsData['transactions']
    ];

    return {
      'transactions': transactions,
      'totalDebit': totalDebit,
      'totalCredit': totalCredit,
    };
  }
  Future<Map<String, dynamic>> _getCreditTransactionsForSelectedMonth() {
    return _getTypeTransactionsForSelectedMonth('credits');
  }
  Future<Map<String, dynamic>> _getDebitTransactionsForSelectedMonth() {
    return _getTypeTransactionsForSelectedMonth('debits');
  }
  Future<Map<String, dynamic>> _getTypeTransactionsForSelectedMonth(String collection) async {
    final user = FirebaseAuth.instance.currentUser;
    DateTime startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    List<QueryDocumentSnapshot> transactions = [];
    double total = 0.0;

    var transactionsQuery = await FirebaseFirestore.instance
        .collection(collection)
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    // Calcul des totaux et ajout des transactions récupérées
    for (var doc in transactionsQuery.docs) {
      total += (doc['amount'] as num).toDouble();
      transactions.add(doc);
    }

    return {
      'transactions': transactions,
      'total': total,
    };
  }


  /*
  Future<Map<String, dynamic>> _getDebitTransactionsForSelectedMonth() async {

    final user = FirebaseAuth.instance.currentUser;
    DateTime startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    List<QueryDocumentSnapshot> transactions = [];

    var debitQuery = await FirebaseFirestore.instance
        .collection("debits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .get();
  }

  Future<Map<String, dynamic>> _getTransactionsForSelectedMonth() async {
    final user = FirebaseAuth.instance.currentUser;
    DateTime startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    List<QueryDocumentSnapshot> transactions = [];
    double debitTotal = 0.0;
    double creditTotal = 0.0;

    // Charger les transactions de débit et crédit du mois sélectionné
    var debitQuery = await FirebaseFirestore.instance
        .collection("debits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    var creditQuery = await FirebaseFirestore.instance
        .collection("credits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
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
  */

  void _updateMonthlyTotals() async {
    final data = await _getTransactionsForSelectedMonth();
    setState(() {
      totalCredit = data['totalCredit'] ?? 0.0;
      totalDebit = data['totalDebit'] ?? 0.0;
    });
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
    if (categoryId == null || categoryId.isEmpty) return "Sans catégorie";

    if (categoryMap.containsKey(categoryId)) {
      return categoryMap[categoryId]!;
    } else {
      var categorySnapshot = await FirebaseFirestore.instance.collection("categories").doc(categoryId).get();
      if (categorySnapshot.exists) {
        String categoryName = categorySnapshot['name'];
        categoryMap[categoryId] = categoryName; // Cache le nom pour les prochaines utilisations
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
  void _toggleTransactionFilter(String filter) {
    setState(() {
      transactionFilter = filter;
    });
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
    bool confirm = await _showDeleteConfirmation(context);
    if (!confirm) return;

    bool isDebit = transaction.reference.parent.id == 'debits';
    String collection = isDebit ? 'debits' : 'credits';
    double amount = transaction['amount'] as double;

    // Supprimer la transaction de la collection appropriée
    await FirebaseFirestore.instance.collection(collection).doc(transaction.id).delete();

    // Mettre  à jour le budget après suppression
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await updateBudgetAfterTransactionDeletion(user.uid, amount, isDebit: isDebit);
    }

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
            _showMonthDetails(context);
          },
          child: Text(DateFormat.yMMMM('fr_FR').format(selectedMonth)),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: _previousMonth),
          IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _nextMonth),
          // Buton pour accèder aux transactions récurrentes
          IconButton(
            icon: const Icon(Icons.repeat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionsReccuringView(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _toggleTransactionFilter("all"),
                  child: const Text("Tous"),
                ),
                ElevatedButton(
                  onPressed: () => _toggleTransactionFilter("debits"),
                  child: const Text("Débits"),
                ),
                ElevatedButton(
                  onPressed: () => _toggleTransactionFilter("credits"),
                  child: const Text("Crédits"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(
                  'Total Crédit : €${totalCredit.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Total Débit : €${totalDebit.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  'Économies : €${(totalCredit - totalDebit).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _getTransactionsForSelectedMonth(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Erreur: ${snapshot.error}"));
                  }

                  var data = snapshot.data!;
                  List<QueryDocumentSnapshot> transactions = data['transactions'] ?? [];
                  transactions = transactions.where((transaction) {
                    bool isDebit = transaction.reference.parent.id == 'debits';
                    if (transactionFilter == "debits") return isDebit;
                    if (transactionFilter == "credits") return !isDebit;
                    return true;
                  }).toList();

                  Map<String, List<QueryDocumentSnapshot>> transactionsByDays = {};
                  for (var transaction in transactions) {
                    DateTime date = (transaction['date'] as Timestamp).toDate();
                    String dayKey = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(date);
                    if (!transactionsByDays.containsKey(dayKey)) {
                      transactionsByDays[dayKey] = [];
                    }
                    transactionsByDays[dayKey]!.add(transaction);
                  }

                  return ListView.builder(
                    itemCount: transactionsByDays.keys.length,
                    itemBuilder: (context, index) {
                      String dayKey = transactionsByDays.keys.elementAt(index);
                      var transactionsForDay = transactionsByDays[dayKey]!;
                      double totalAmount = transactionsForDay.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());

                      return ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(dayKey, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Text('Total: €${totalAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        children: transactionsForDay.map((transaction) {
                          bool isDebit = transaction.reference.parent.id == 'debits';
                          String transactionType = isDebit ? 'Débit' : 'Crédit';
                          return FutureBuilder<String>(
                            future: getCategoryName(transaction['categorie_id']),
                            builder: (context, snapshot) {
                              String categoryName = snapshot.data ?? 'Sans catégorie';
                              Color backgroundColor = isDebit ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1);
                              return Container(
                                color: backgroundColor,
                                child: ListTile(
                                  title: Row(
                                    children: [
                                      Text(
                                        '${transaction['amount'].toStringAsFixed(2)} €',
                                        style: TextStyle(color: isDebit ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(transactionType),
                                    ],
                                  ),
                                  subtitle: Text(categoryName),
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) => TransactionDetailsModal(transaction: transaction),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
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

  void _showMonthDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetDetailsScreen(selectedMonth: selectedMonth),
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