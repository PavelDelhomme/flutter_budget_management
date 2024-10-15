import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_color/random_color.dart';  // Importation pour générer des couleurs aléatoires
import '../../services/income_service.dart';

class SummaryView extends StatefulWidget {
  const SummaryView({Key? key}) : super(key: key);

  @override
  _SummaryViewState createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  final RandomColor _randomColor = RandomColor();  // Instance de RandomColor

  @override
  void initState() {
    super.initState();
    setState(() {
      _getBudgetSummary();
    });
  }

  Future<Map<String, dynamic>?> _getBudgetSummary() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final budgetSnapshot = await FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user.uid)
            .where('month', isEqualTo: DateTime.now().month)
            .where('year', isEqualTo: DateTime.now().year)
            .get();

        if (budgetSnapshot.docs.isEmpty) return null;

        return {
        };
      } catch (e) {
        print("Erreur lors de la récupération des données du budget : $e");
        return null;
      }
    }
    return null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("transactions")
              .where("userId", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("Aucune donnée disponible pour le résumé du budget."));
            }

            final transactionsData = snapshot.data!;


            return FutureBuilder<Map<String, dynamic>?>(
              future: _getBudgetSummary(),
              builder: (context, budgetSnapshot) {
                if (budgetSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!budgetSnapshot.hasData || budgetSnapshot.data == null) {
                  return const Center(child: Text("Aucune donnée disponible pour le résumé du budget."));
                }

                final data = budgetSnapshot.data!;

                return ListView(
                  children: [
                    _buildBudgetCard('Total Budget', 100.0.toStringAsFixed(2), Colors.blue),
                    _buildBudgetCard('Revenu Mensuel Total', 100.0.toStringAsFixed(2), Colors.purple),
                    _buildBudgetCard('Dépenses Réelles', 100.0.toStringAsFixed(2), Colors.orange),
                    _buildBudgetCard('Solde Restant', 100.0.toStringAsFixed(2), Colors.green),
                    const SizedBox(height: 20),
                    const Text(
                      "Répartition des Catégories",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
