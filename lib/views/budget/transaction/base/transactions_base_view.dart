import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  String transactionFilter = "all"; // "all", "debits", "credits"
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
                          // Ajoute ici le code pour l'affichage des détails de la transaction
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
        onPressed: () {
          // Ajoute ici la logique d'ajout d'une nouvelle transaction
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
