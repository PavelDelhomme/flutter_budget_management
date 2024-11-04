import 'package:cloud_firestore/cloud_firestore.dart' as fs;
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

  // Fonction pour calculer les économies par mois et les économies totales
  Future<void> _calculateSavings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('Calcul des économies pour l\'utilisateur : ${user.uid}');

      // Récupérer toutes les transactions de l'utilisateur
      final debitsSnapshot = await fs.FirebaseFirestore.instance
          .collection('debits')
          .where('user_id', isEqualTo: user.uid)
          .get();

      final creditsSnapshot = await fs.FirebaseFirestore.instance
          .collection('credits')
          .where('user_id', isEqualTo: user.uid)
          .get();

      // Calcul des économies par mois
      Map<String, double> savingsPerMonth = {};
      double totalSavings = 0.0;

      void addTransactionToMonth(
          String monthKey, double amount, bool isDebit) {
        if (!savingsPerMonth.containsKey(monthKey)) {
          savingsPerMonth[monthKey] = 0.0;
        }
        savingsPerMonth[monthKey] =
            savingsPerMonth[monthKey]! + (isDebit ? -amount : amount);
      }

      // Traiter les débits
      for (var doc in debitsSnapshot.docs) {
        Debit debit = Debit.fromMap(doc.data());
        String monthKey = DateFormat('yyyy-MM').format(debit.date);
        addTransactionToMonth(monthKey, debit.amount, true);
      }

      // Traiter les crédits
      for (var doc in creditsSnapshot.docs) {
        Credit credit = Credit.fromMap(doc.data());
        String monthKey = DateFormat('yyyy-MM').format(credit.date);
        addTransactionToMonth(monthKey, credit.amount, false);
      }

      // Calcul des économies totales
      savingsPerMonth.forEach((month, savings) {
        if (savings > 0) totalSavings += savings;
      });

      setState(() {
        this.totalSavings = totalSavings;
        monthlySavings = savingsPerMonth;
      });

      print('Économies totales : $totalSavings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Résumé des Économies')),
      drawer: const CustomDrawer(activeItem: 'savings'), // Ajoutez le CustomDrawer ici
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
