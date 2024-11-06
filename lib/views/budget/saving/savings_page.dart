import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:budget_management/models/good_models.dart';

import '../../navigation/custom_drawer.dart';

class SavingsPage extends StatefulWidget {
  @override
  _SavingsPageState createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  double totalSavings = 0.0;
  Map<String, double> monthlySavings = {};

  @override
  void initState() {
    super.initState();
    _calculateSavings();
  }

  Future<void> _calculateSavings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final budgetsSnapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .where('user_id', isEqualTo: user.uid)
          .get();

      double totalSavings = 0.0;
      Map<String, double> savingsPerMonth = {};

      for (var doc in budgetsSnapshot.docs) {
        Budget budget = Budget.fromMap(doc.data());
        String monthKey = '${budget.year}-${budget.month.toString().padLeft(2, '0')}';

        double remaining = budget.remaining;
        savingsPerMonth[monthKey] = remaining;
        totalSavings += remaining;
      }

      setState(() {
        this.totalSavings = totalSavings;
        monthlySavings = savingsPerMonth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résumé des Économies')),
      drawer: const CustomDrawer(activeItem: 'savings'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total des Économies: €${totalSavings.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: monthlySavings.keys.length,
                itemBuilder: (context, index) {
                  String monthKey = monthlySavings.keys.elementAt(index);
                  double savings = monthlySavings[monthKey] ?? 0.0;
                  DateTime monthDate =
                  DateFormat('yyyy-MM').parse(monthKey); // Convertir en DateTime

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        'Économies de ${DateFormat('MMMM yyyy').format(monthDate)}',
                      ),
                      subtitle: Text('Reste: €${savings.toStringAsFixed(2)}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
