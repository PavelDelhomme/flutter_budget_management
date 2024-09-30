import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../models/budget.dart';
import '../../models/category.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({Key? key}) : super(key: key);

  @override
  _AddBudgetScreenState createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  List<CategoryModel> categories = [];
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateDefaultCategories();
  }

  void _generateDefaultCategories() {
    categories = [
      CategoryModel(name: 'Loyer', allocatedAmount: 0.0),
      CategoryModel(name: 'Alimentation', allocatedAmount: 0.0),
      CategoryModel(name: 'Santé', allocatedAmount: 0.0),
      CategoryModel(name: 'Transports', allocatedAmount: 0.0),
      CategoryModel(name: 'Loisirs', allocatedAmount: 0.0),
    ];
  }

  void _addCategory() {
    if (_categoryNameController.text.isNotEmpty && _categoryAmountController.text.isNotEmpty) {
      setState(() {
        categories.add(CategoryModel(
          name: _categoryNameController.text,
          allocatedAmount: double.tryParse(_categoryAmountController.text) ?? 0.0,
        ));
        _categoryNameController.clear();
        _categoryAmountController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir le nom et le montant de la catégorie.")),
      );
    }
  }

  void _removeCategory(int index) {
    setState(() {
      categories.removeAt(index);
    });
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var category in categories) {
      total += category.allocatedAmount;
    }
    return total;
  }

  void _addBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    double totalAmount = _calculateTotalAmount();

    if (user != null && _descriptionController.text.isNotEmpty && categories.isNotEmpty) {
      final budget = BudgetModel(
        id: generateBudgetId(),
        userId: user.uid,
        description: _descriptionController.text,
        totalAmount: totalAmount,
        startDate: Timestamp.fromDate(DateTime.now()),
        endDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        categories: categories,
      );

      await FirebaseFirestore.instance.collection('budgets').doc(budget.id).set(budget.toMap());

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs et ajouter au moins une catégorie.")),
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
              decoration: const InputDecoration(labelText: 'Description du budget'),
            ),
            const SizedBox(height: 20),
            const Text(
              "Ajouter ou modifier des catégories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _categoryNameController,
              decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
            ),
            TextField(
              controller: _categoryAmountController,
              decoration: const InputDecoration(labelText: 'Montant alloué'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Ajouter une catégorie'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    title: Text(category.name),
                    subtitle: Text('Montant alloué: \$${category.allocatedAmount.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeCategory(index),
                    ),
                  );
                },
              ),
            ),
            Text(
              'Total Budget Estimé: \$${_calculateTotalAmount().toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addBudget,
              child: const Text('Créer le budget'),
            ),
          ],
        ),
      ),
    );
  }
}