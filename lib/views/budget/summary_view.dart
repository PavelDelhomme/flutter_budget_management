import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_color/random_color.dart';  // Importation pour générer des couleurs aléatoires

class SummaryView extends StatefulWidget {
  const SummaryView({Key? key}) : super(key: key);

  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  final RandomColor _randomColor = RandomColor();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('debits')
              .where('user_id', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, debitSnapshot) {
            if (debitSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('credits')
                  .where('user_id', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, creditSnapshot) {
                if (creditSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Fusionner les données des deux collections
                List<QueryDocumentSnapshot> transactions = [
                  ...debitSnapshot.data?.docs ?? [],
                  ...creditSnapshot.data?.docs ?? [],
                ];

                double totalDebit = 0.0;
                double totalCredit = 0.0;
                Map<String, double> categorySpending = {};

                for (var doc in transactions) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data['categorie_id'] ?? 'Inconnu';
                  final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                  final isDebit = doc.reference.parent.id == 'debits';

                  if (isDebit) {
                    totalDebit += amount;
                    if (categorySpending.containsKey(category)) {
                      categorySpending[category] = categorySpending[category]! + amount;
                    } else {
                      categorySpending[category] = amount;
                    }
                  } else {
                    totalCredit += amount;
                  }
                }

                return ListView(
                  children: [
                    _buildBudgetCard("Total Débit", totalDebit.toStringAsFixed(2), Colors.red),
                    _buildBudgetCard("Total Crédit", totalCredit.toStringAsFixed(2), Colors.green),
                    const SizedBox(height: 20),
                    const Text(
                      "Dépenses par Catégorie",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...categorySpending.entries.map((entry) {
                      final color = _randomColor.randomColor();
                      return _buildBudgetCard(entry.key, entry.value.toStringAsFixed(2), color);
                    }).toList(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBudgetCard(String title, String amount, Color color) {
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text(
              "\$$amount",
              style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
