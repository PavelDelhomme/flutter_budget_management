import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/saving.dart';

class SavingsPage extends StatefulWidget {
  @override
  _SavingsPageState createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<SavingsModel> savings = [];

  Future<void> _loadSavings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final savingsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savings')
          .get();

      setState(() {
        savings = savingsSnapshot.docs.map((doc) => SavingsModel.fromMap(doc.data())).toList();
      });
    }
  }

  Future<void> _addSaving(String category, double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final newSaving = SavingsModel(
        id: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('savings').doc().id,
        userId: user.uid,
        category: category,
        amount: amount,
      );

      await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .doc(newSaving.id)
        .set(newSaving.toMap());

      _loadSavings();
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
          Text('Économies totales: \$${savings.fold(0, (sum, item) => sum + item.amount).toStringAsFixed(2)}'),
          Expanded(
            child: ListView.builder(
              itemCount: savings.length,
              itemBuilder: (context, index) {
                final saving = savings[index];
                return ListTile(
                  title: Text(saving.category),
                  subtitle: Text('Montant: \$${saving.amount.toStringAsFixed(2)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}