import 'package:budget_management/views/budget/transaction/transaction_form_screen.dart';
import 'package:budget_management/views/budget/transaction/transaction_details_modal.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionsBaseView extends StatefulWidget {
  final bool showRecurring; // Indique si l'on affiche uniquement les récurrentes
  final String title;

  const TransactionsBaseView({
    Key? key,
    required this.showRecurring,
    required this.title,
  }) : super(key: key);

  @override
  _TransactionsBaseViewState createState() => _TransactionsBaseViewState();
}

class _TransactionsBaseViewState extends State<TransactionsBaseView> {
  DateTime selectedMonth = DateTime.now();
  double totalDebit = 0.0;
  double totalCredit = 0.0;
  //String transactionFilter = "all"; // "all", "debits", "credits"
  Map<String, String> categoryMap = {};

  Future<Map<String, dynamic>> _getTransactionsForSelectedMonth() async {
    final user = FirebaseAuth.instance.currentUser;
    DateTime startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    List<QueryDocumentSnapshot> transactions = [];
    double debitTotal = 0.0;
    double creditTotal = 0.0;

    var debitQuery = FirebaseFirestore.instance
        .collection("debits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth));

    var creditQuery = FirebaseFirestore.instance
        .collection("credits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth));

    if (widget.showRecurring) {
      debitQuery = debitQuery.where("isRecurring", isEqualTo: true);
      creditQuery = creditQuery.where("isRecurring", isEqualTo: true);
    }

    var debitSnapshot = await debitQuery.get();
    var creditSnapshot = await creditQuery.get();

    for (var doc in debitSnapshot.docs) {
      debitTotal += (doc['amount'] as num).toDouble();
      transactions.add(doc);
    }
    for (var doc in creditSnapshot.docs) {
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

  @override
  void initState() {
    super.initState();
    _updateMonthlyTotals();
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

  Future<String> getCategoryName(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) {
      return "Sans catégorie";
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

    bool isRecurring = transaction['isRecurring'];
    if (isRecurring) {
      bool deleteAll = await _showDeleteAllOccurrencesDialog(context);
      if (deleteAll) {
        DateTime transactionDate = (transaction['date'] as Timestamp).toDate();
        await FirebaseFirestore.instance
              .collection(transaction.reference.parent.id)
              .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('isRecurring', isEqualTo: true)
              .where('date', isGreaterThan: Timestamp.fromDate(transactionDate))
              .get()
              .then((snapshot) async {
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }
              });
        }
    }
    await FirebaseFirestore.instance.collection(transaction.reference.parent.id).doc(transaction.id).delete();
    _updateMonthlyTotals();
  }

  Future<bool> _showDeleteAllOccurrencesDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Voulez-vous supprimer toutes les occurrences futures de cette transaction ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Non"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Oui"),
            ),
          ],
        );
      },
    ) ??
    false;
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
    ) ??
    false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {},
          child: Text(widget.title),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.arrow_back), onPressed: _previousMonth),
          IconButton(
              icon: const Icon(Icons.arrow_forward), onPressed: _nextMonth),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
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
                  List<QueryDocumentSnapshot> transactions =
                      data['transactions'] ?? [];
                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      var transaction = transactions[index];
                      bool isDebit = transaction.reference.parent.id == 'debits';
                      String transactionType = isDebit ? 'Débit' : 'Crédit';

                      return ListTile(
                        title: Text(
                          '${transaction['amount'].toStringAsFixed(2)} €',
                          style: TextStyle(color: isDebit ? Colors.red : Colors.green),
                        ),
                        subtitle: Text(transactionType),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => TransactionDetailsModal(transaction: transaction),
                          );
                        },
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
        onPressed: () => _addNewTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
