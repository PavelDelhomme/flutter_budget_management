import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import '../../models/budget.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({Key? key}) : super(key: key);

  @override
  _AddBudgetScreenState createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  void _addBudget() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && _descriptionController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      final budget = BudgetModel(
        id: generateBudgetId(),
        userId: user.uid,
        description: _descriptionController.text,
        totalAmount: double.tryParse(_amountController.text) ?? 0.0,
        categoryId: 'default', // Remplacez par la sélection réelle de la catégorie
        startDate: Timestamp.fromDate(DateTime.now()),
        endDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))), // Période de 30 jours par défaut
      );

      await FirebaseFirestore.instance.collection('budgets').doc(budget.id).set(budget.toMap());

      Navigator.pop(context); // Retour à la page précédente après l'ajout
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
    }
  }

  String generateBudgetId() {
    final random = Random();
    return 'budget_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un budget')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Montant total'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addBudget,
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
