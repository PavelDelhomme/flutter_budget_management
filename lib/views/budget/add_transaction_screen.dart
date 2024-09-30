import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import '../../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  void _addTransaction() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && _descriptionController.text.isNotEmpty && _amountController.text.isNotEmpty) {
      final transaction = TransactionModel(
        id: generateTransactionId(),
        userId: user.uid,
        description: _descriptionController.text,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        categoryId: 'default', // à remplacer par la sélection réelle de catégorie
        date: Timestamp.fromDate(_selectedDate),
      );

      await FirebaseFirestore.instance.collection('transactions').doc(transaction.id).set(transaction.toMap());

      Navigator.pop(context); // Retour à la page précédente après l'ajout
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  String generateTransactionId() {
    final random = Random();
    return 'transac_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une transaction')),
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
              decoration: const InputDecoration(labelText: 'Montant'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Date : ${_selectedDate.toLocal()}'.split(' ')[0]),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Choisir une date'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addTransaction,
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}
