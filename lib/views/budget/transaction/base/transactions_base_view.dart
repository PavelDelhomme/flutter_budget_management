import 'dart:developer';

import 'package:budget_management/views/budget/transaction/transaction_details_view.dart';
import 'package:budget_management/views/budget/transaction/transaction_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionsBaseView extends StatefulWidget {
  final bool showRecurring; // Indique si l'on affiche uniquement les récurrentes

  const TransactionsBaseView({
    Key? key,
    required this.showRecurring,
  }) : super(key: key);

  @override
  _TransactionsBaseViewState createState() => _TransactionsBaseViewState();
}

class _TransactionsBaseViewState extends State<TransactionsBaseView> {
  DateTime selectedMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();
  bool showOnlyRecurring = false;
  bool isViewingMonth = false; // Etat pour la vue mensuelle
  double totalDebit = 0.0;
  double totalCredit = 0.0;
  String transactionFilter = "all"; // "all", "debits", "credits"
  Map<String, String> categoryMap = {};
  Map<DateTime, bool> debitDays = {};
  Map<DateTime, bool> creditDays = {};

  @override
  void initState() {
    super.initState();
    _getDaysWithTransactions(); // Charge les jours avec des transactions
  }

  Stream<Map<String, dynamic>> _getTransactions() {
    return isViewingMonth
        ? _getTransactionsForSelectedMonth()
        : _getTransactionsForSelectedDate();
  }


  Stream<Map<String, dynamic>> _getTransactionsForSelectedDate() {
    final user = FirebaseAuth.instance.currentUser;
    DateTime startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    var debitStream = FirebaseFirestore.instance
        .collection("debits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("date", isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();

    var creditStream = FirebaseFirestore.instance
        .collection("credits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where("date", isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots();

    return debitStream.asyncMap((debitSnapshot) async {
      final creditSnapshot = await creditStream.first;

      double debitTotal = debitSnapshot.docs
          .fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
      double creditTotal = creditSnapshot.docs
          .fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());

      List<QueryDocumentSnapshot> transactions = [
        ...debitSnapshot.docs,
        ...creditSnapshot.docs,
      ];

      if (showOnlyRecurring) {
        transactions = transactions.where((transaction) => transaction['isRecurring'] == true).toList();
      }

      transactions.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp)); // Tri des transactions par date croissante

      return {
        'transactions': transactions,
        'totalDebit': debitTotal,
        'totalCredit': creditTotal,
      };
    });
  }
  // Vue mensuelle
  Stream<Map<String, dynamic>> _getTransactionsForSelectedMonth() {
    final user = FirebaseAuth.instance.currentUser;
    DateTime startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    var debitStream = FirebaseFirestore.instance
        .collection("debits")
        .where('user_id', isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots();

    var creditStream = FirebaseFirestore.instance
        .collection("credits")
        .where('user_id', isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots();

    return  debitStream.asyncMap((debitSnapshot) async {
      final creditSnapshot = await creditStream.first;

      double debitTotal = debitSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
      double creditTotal = creditSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());

      List<QueryDocumentSnapshot> transactions = [
        ...debitSnapshot.docs,
        ...creditSnapshot.docs,
      ];

      transactions.sort((a,  b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp)); // Tri des transactions par date décroissantes
      return {
        'transactions': transactions,
        'totalDebit': debitTotal,
        'totalCredit': creditTotal,
      };
    });
  }
  // Charge les jours avec des transactions de débit ou de crédit
  Future<void> _getDaysWithTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    DateTime startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    DateTime endOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);

    var debitSnapshot = await FirebaseFirestore.instance
        .collection("debits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    var creditSnapshot = await FirebaseFirestore.instance
        .collection("credits")
        .where("user_id", isEqualTo: user?.uid)
        .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    setState(() {
      debitDays = {for (var doc in debitSnapshot.docs) (doc['date'] as Timestamp).toDate(): true};
      creditDays = {for (var doc in creditSnapshot.docs) (doc['date'] as Timestamp).toDate(): true};
    });
  }


  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
  }

  void _toggleTransactionFilter(String filter) {
    setState(() {
      transactionFilter = filter;
    });
  }

  Future<String> getCategoryName(String categoryId) async {
    if (categoryMap.containsKey(categoryId)) {
      return categoryMap[categoryId]!;
    } else {
      try {
        final categorySnapshot = await FirebaseFirestore.instance
            .collection("categories")
            .doc(categoryId)
            .get();
        if (categorySnapshot.exists) {
          String categoryName = categorySnapshot['name'];
          categoryMap[categoryId] = categoryName;
          return categoryName;
        }
      } catch (e) {
        log("Erreur lors de la récupération de la catégorie : $e");
      }
      return "Sans catégorie";
    }
  }

  Future<String> getCategoryNameOrNotes(DocumentSnapshot transaction) async {
    bool isDebit = transaction.reference.parent.id == 'debits';

    if (isDebit) {
      // Si c'est un débit, on suppose qu'il y a une catégorie ID
      String? categoryId = transaction['categorie_id'];
      if (categoryId != null) {
        return await getCategoryName(categoryId);
      } else {
        return "Sans catégorie";
      }
    } else {
      // Si c'est un crédit et qu'il n'y a pas de catégorie, affiche les notes
      return (transaction['notes'] ?? "Sans notes").toString();
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
      setState(() {}); // Rafraîchit l'interface après l'édition
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
      setState(() {}); // Rafraîchit l'interface après l'ajout
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
    setState(() {}); // Forcer le rafraîchissement
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
    ) ?? false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(DateTime.now().year - 1),
                  lastDate: DateTime(DateTime.now().year + 1),
                  locale: const Locale("fr", "FR"),
                  selectableDayPredicate: (day) => debitDays.containsKey(day) || creditDays.containsKey(day),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.blue,
                        ),
                      ),
                      child: child ?? SizedBox(),
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                    isViewingMonth = false; // Basculer en vue journalière
                  });
                }
              },
              child: Text(
                DateFormat.yMMMMd('fr_FR').format(selectedDate),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            IconButton(
              icon: Icon(isViewingMonth ? Icons.calendar_view_day : Icons.calendar_view_month),
              onPressed: () {
                setState(() {
                  isViewingMonth = !isViewingMonth;
                });
              },
            ),
            // Affichage de la vue actuelle
            Text(
              isViewingMonth ? " (Mois)" : " (Jour)",
              style: const TextStyle(color: Colors.grey),
            ),
            IconButton(
              icon: Icon(
                showOnlyRecurring ? Icons.repeat : Icons.repeat_on,
                color: showOnlyRecurring ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  showOnlyRecurring = !showOnlyRecurring;
                });
              },
              tooltip: showOnlyRecurring ? "Afficher toutes les transactions": "Afficher les transactions réccurentes",
            )
          ],
        ),
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
            StreamBuilder<Map<String, dynamic>>(
              stream: _getTransactions(), // Utilise les transactions du jour
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Erreur: ${snapshot.error}"));
                }

                var data = snapshot.data ?? {};
                totalDebit = data['totalDebit'] ?? 0.0;
                totalCredit = data['totalCredit'] ?? 0.0;

                List<QueryDocumentSnapshot> transactions = data['transactions'] ?? [];
                transactions = transactions.where((transaction) {
                  bool isDebit = transaction.reference.parent.id == 'debits';
                  if (transactionFilter == "debits") return isDebit;
                  if (transactionFilter == "credits") return !isDebit;
                  return true;
                }).toList();

                return Expanded(
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
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            var transaction = transactions[index];
                            bool isDebit = transaction.reference.parent.id == 'debits';
                            double amount = transaction['amount'].toDouble();
                            String sign = isDebit ? '-' : '+';
                            DateTime transactionDate = (transaction['date'] as Timestamp).toDate();
                            String formattedDate = DateFormat('d MMMM', 'fr_FR').format(transactionDate);

                            return Dismissible(
                              key: Key(transaction.id),
                              direction: DismissDirection.horizontal,
                              // Swipe sur la droite pour supprimer
                              background: Container(
                                color: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerLeft,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              // Swipe sur la droite pour éditer
                              secondaryBackground: Container(
                                color: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerRight,
                                child: const Icon(Icons.edit, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  // Confirmer la suppression
                                  _deleteTransaction(context, transaction);
                                  return false; // Ne pas supprimer automatiquement car géré par _deleteTransaction
                                } else if (direction == DismissDirection.endToStart) {
                                  // Ouvre l'écran de modification
                                  _editTransaction(context, transaction);
                                  return false; // Ne supprime pas lors de l'édition
                                }
                                return false;
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 4,
                                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  leading: Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  title: Text(
                                    "$sign${amount.toStringAsFixed(2)} €",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDebit ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  subtitle: FutureBuilder<String>(
                                    future: getCategoryNameOrNotes(transaction),
                                    builder: (context, snapshot) {
                                      String categoryName = snapshot.data ?? 'Sana catégorie';
                                      return Text(
                                        categoryName,
                                        style: const TextStyle(fontSize: 14),
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TransactionDetailsView(transaction: transaction),
                                      ),
                                    );
                                  },
                                ),
                              )
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
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
