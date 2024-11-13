import 'package:budget_management/utils/general.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../budget/budget_details_screen.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  TransactionsViewState createState() => TransactionsViewState();
}

class TransactionsViewState extends State<TransactionsView> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transactions"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getTransactionsForSelectedMonth(),
        builder: (context, snapshot) {
          // Utilisez `checkSnapshot` pour vérifier l’état du snapshot
          Widget? checkResult = checkSnapshot(snapshot,
              errorMessage: "Erreur lors du chargement des transactions");
          if (checkResult != null) return checkResult;

          // Si checkSnapshot ne retourne rien, nous pouvons afficher les données
          var data = snapshot.data!;
          List<QueryDocumentSnapshot> transactions = data['transactions'] ?? [];
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
                child: ListTile(
                  title: Text(
                    'Total Crédit : €${totalCredit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Total Débit : €${totalDebit.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    'Économies : €${(totalCredit - totalDebit).toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Total: €${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      children: transactionsForDay.map((transaction) {
                        bool isDebit =
                            transaction.reference.parent.id == 'debits';
                        String transactionType = isDebit ? 'Débit' : 'Crédit';

                        return ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${transaction['amount'].toStringAsFixed(2)} €',
                                style: TextStyle(
                                    color: isDebit ? Colors.red : Colors.green),
                              ),
                              Text(transactionType),
                            ],
                          ),
                          subtitle: Text(transaction['notes'] ?? 'Aucune note'),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
