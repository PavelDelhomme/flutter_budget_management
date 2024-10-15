import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/dead_saving.dart';


class DeadSavingsPage extends StatefulWidget {
  @override
  _DeadSavingsPageState createState() => _DeadSavingsPageState();
}

class _DeadSavingsPageState extends State<DeadSavingsPage> {
  List<DeadSavingsModel> savings = [];

  Future<void> _loadSavings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final savingsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savings')
          .get();

      setState(() {
        savings = savingsSnapshot.docs.map((doc) => DeadSavingsModel.fromMap(doc.data(), doc.id)).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mes Économies')),
      body: Column(
        children: [
          Text('Économies totales: \$${savings.fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(2)}'),
          Expanded(
            child: ListView.builder(
              itemCount: savings.length,
              itemBuilder: (context, index) {
                final saving = savings[index];
                return ListTile(
                  title: Text(saving.category),
                  subtitle: Text('Montant: \$${saving.amount.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      // Logique pour retirer des fonds d'une catégorie de savings
                      _deductFromSavings(saving.id, 50.0); // Exemple : déduire 50
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deductFromSavings(String savingId, double amountToDeduct) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final savingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savings')
          .doc(savingId)
          .get();

      if (savingDoc.exists) {
        final currentAmount = (savingDoc.data()?['amount'] as num?)?.toDouble() ?? 0.0;
        final newAmount = currentAmount - amountToDeduct;

        if (newAmount >= 0) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('savings')
              .doc(savingId)
              .update({'amount': newAmount});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Pas assez de fonds dans cette catégorie d'économies.")),
          );
        }
      }
    }
  }
}