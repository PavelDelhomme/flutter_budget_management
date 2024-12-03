import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BudgetMonthDetailsScreen extends StatefulWidget {
  final DateTime selectedMonth;

  const BudgetMonthDetailsScreen({super.key, required this.selectedMonth});

  @override
  BudgetMonthDetailsScreenState createState() => BudgetMonthDetailsScreenState();
}

class BudgetMonthDetailsScreenState extends State<BudgetMonthDetailsScreen> {
  Future<Map<String, List<Map<String, dynamic>>>> _getTransactionsByCategory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    DateTime startOfMonth = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
    DateTime endOfMonth = DateTime(widget.selectedMonth.year, widget.selectedMonth.month + 1, 1);

    // Récupère les transactions de débit et crédit
    var debitSnapshot = await FirebaseFirestore.instance
        .collection('debits')
        .where('user_id', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    var creditSnapshot = await FirebaseFirestore.instance
        .collection('credits')
        .where('user_id', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    Map<String, List<Map<String, dynamic>>> transactionsByCategory = {};

    // Traiter les transactions de débit
    for (var doc in debitSnapshot.docs) {
      var transaction = doc.data();
      String category = transaction['categorie_id'] ?? 'Inconnu';
      if (!transactionsByCategory.containsKey(category)) {
        transactionsByCategory[category] = [];
      }
      transactionsByCategory[category]!.add(transaction);
    }

    // Traiter les transactions de crédit
    for (var doc in creditSnapshot.docs) {
      var transaction = doc.data();
      String category = transaction['categorie_id'] ?? 'Inconnu';
      if (!transactionsByCategory.containsKey(category)) {
        transactionsByCategory[category] = [];
      }
      transactionsByCategory[category]!.add(transaction);
    }

    return transactionsByCategory;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transactions - ${DateFormat.yMMMM('fr_FR').format(widget.selectedMonth)}',
        ),
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _getTransactionsByCategory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactionsByCategory = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: transactionsByCategory.keys.map((category) {
                double totalAmount = transactionsByCategory[category]!
                    .map((transaction) => transaction['amount'] as double)
                    .fold(0, (sum, amount) => sum + amount);

                return ExpansionTile(
                  title: Text(
                    '$category - Total : \$${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: transactionsByCategory[category]!.map((transaction) {
                    bool isDebit = transaction['type'] == true;  // or based on your model
                    return ListTile(
                      title: Text(
                        '${isDebit ? "Débit" : "Crédit"}: \$${transaction['amount'].toStringAsFixed(2)}',
                        style: TextStyle(color: isDebit ? Colors.red : Colors.green),
                      ),
                      subtitle: Text(transaction['notes'] ?? 'Pas de note'),
                      trailing: Text(
                        DateFormat('dd/MM/yyyy').format((transaction['date'] as Timestamp).toDate()),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}