import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? budgetId;

  const AddTransactionScreen({Key? key, this.budgetId}) : super(key: key);

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(widget.budgetId).get();
      final List<dynamic> categories = budgetDoc.data()?['categories'] ?? [];

      setState(() {
        _categories = categories.map((category) => category as Map<String, dynamic>).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des catégories: $e")),
      );
    }
  }

  void _addTransaction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _descriptionController.text.isNotEmpty && _amountController.text.isNotEmpty && _selectedCategory != null) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      await FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid,
        'budgetId': widget.budgetId,
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'amount': amount,
        'date': Timestamp.now(),
      });

      // Mettre à jour directement le montant dépensé dans la catégorie
      final budgetRef = FirebaseFirestore.instance.collection('budgets').doc(widget.budgetId);
      final budgetDoc = await budgetRef.get();
      if (budgetDoc.exists) {
        final List<dynamic> categories = budgetDoc.data()?['categories'] ?? [];
        final categoryIndex = categories.indexWhere((category) => category['name'] == _selectedCategory);

        if (categoryIndex != -1) {
          final updatedCategory = {
            ...categories[categoryIndex],
            'spentAmount': (categories[categoryIndex]['spentAmount'] ?? 0.0) + amount,
          };
          categories[categoryIndex] = updatedCategory;

          // Mise à jour des catégories
          await budgetRef.update({'categories': categories});
        }
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
            DropdownButton<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['name'],
                  child: Text(category['name']),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              hint: const Text('Sélectionner une catégorie'),
            ),
            ElevatedButton(
              onPressed: _addTransaction,
              child: const Text('Ajouter la transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
