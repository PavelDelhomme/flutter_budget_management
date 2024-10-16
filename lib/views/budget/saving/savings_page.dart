import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SavingsPage extends StatefulWidget {
  @override
  _SavingsPageState createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  double totalCredit = 0.0;
  double totalDebit = 0.0;

  Future<void> _calculateTotals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Récupérer les transactions de l'utilisateur par mois
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('user_id', isEqualTo: user.uid)
          .get();

      // Calculer les crédits et débits
      double totalCredits = 0.0;
      double totalDebits = 0.0;

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num).toDouble();
        final isDebit = data['type'] ?? true;

        if (isDebit) {
          totalDebits += amount;
        } else {
          totalCredits += amount;
        }
      }

      setState(() {
        totalCredit = totalCredits;
        totalDebit = totalDebits;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _calculateTotals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Résumé des transactions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total des crédits: \$${totalCredit.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total des débits: \$${totalDebit.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  // Vous pouvez ajouter plus de détails ici si vous souhaitez afficher les transactions individuelles.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
