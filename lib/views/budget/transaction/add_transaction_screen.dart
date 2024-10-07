import 'package:budget_management/services/budget/add_transaction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';  // Pour formater les dates

class AddTransactionScreen extends StatefulWidget {
  final String? budgetId;

  const AddTransactionScreen({Key? key, this.budgetId}) : super(key: key);

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  double _allocatedAmount = 0.0; // Montant alloué à la catégorie
  double _spentAmount = 0.0; // Montant déjà dépensé dans la catégorie
  double _remainingAmountForCategory = 0.0;  // Montant restant dans la catégorie
  bool _useSavings = false;
  bool _isRecurring = false; // Nouveau champ pour définir si la transaction est récurrente

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _amountController.addListener(_updateRemainingAmountWithInput);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateRemainingAmountWithInput);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      if (widget.budgetId != null) {
        final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(widget.budgetId).get();
        final List<dynamic> categories = budgetDoc.data()?['categories'] ?? [];

        setState(() {
          _categories = categories.map((category) => category as Map<String, dynamic>).toList();
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _isLoadingCategories = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Budget non trouvé.")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des catégories: $e")),
      );
    }
  }

  void _calculateRemainingAmount(String categoryName) {
    final selectedCategoryData = _categories.firstWhere(
          (category) => category['name'] == categoryName,
      orElse: () => {},
    );

    if (selectedCategoryData.isNotEmpty) {
      setState(() {
        _allocatedAmount = (selectedCategoryData['allocatedAmount'] as num?)?.toDouble() ?? 0.0;
        _spentAmount = (selectedCategoryData['spentAmount'] as num?)?.toDouble() ?? 0.0;
        _remainingAmountForCategory = _allocatedAmount - _spentAmount;

        // Recalculer le montant restant en fonction du montant actuel de la transaction
        _updateRemainingAmountWithInput();
      });
    }
  }

  void _updateRemainingAmountWithInput() {
    final inputAmount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _remainingAmountForCategory = _allocatedAmount - _spentAmount - inputAmount;
    });
  }

  Future<void> _addTransaction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _descriptionController.text.isNotEmpty && _amountController.text.isNotEmpty && _selectedCategory != null) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final date = DateTime.tryParse(_dateController.text) ?? DateTime.now();

      bool isRecurring = false;  // À ajuster en fonction de la logique utilisateur (par exemple, via un checkbox)

      String? selectedSavingCategory;  // Ajouter une option pour la catégorie d'économies

      if (_useSavings) {
        // Logique pour sélectionner la catégorie d'économies
        selectedSavingCategory = await _selectSavingCategory();
      }

      try {
        await addTransaction(
          description: _descriptionController.text,
          amount: amount,
          categoryId: _selectedCategory!,
          budgetId: widget.budgetId!,
          useSavings: _useSavings,
          isRecurring: isRecurring,
          savingCategoryId: selectedSavingCategory,  // Passer la catégorie d'économies sélectionnée
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${e.toString()}")),
        );
      }
    }
  }

  Future<String?> _selectSavingCategory() async {
    // Logique pour afficher une boîte de dialogue permettant à l'utilisateur de choisir la catégorie d'économies
    final selectedCategory = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisissez une catégorie d\'économies'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _categories.map((category) {
              return ListTile(
                title: Text(category['name']),
                onTap: () {
                  Navigator.pop(context, category['id']);
                },
              );
            }).toList(),
          ),
        );
      },
    );
    return selectedCategory;
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
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date'),
              keyboardType: TextInputType.datetime,
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (selectedDate != null) {
                  _dateController.text = DateFormat.yMd().format(selectedDate);
                }
              },
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
                  if (_selectedCategory != null) {
                    _calculateRemainingAmount(_selectedCategory!);
                  }
                });
              },
              hint: const Text('Sélectionner une catégorie'),
            ),
            if (_selectedCategory != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  'Montant restant dans la catégorie: \$${_remainingAmountForCategory.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: _remainingAmountForCategory < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: const Text("Transaction récurrente"),
              value: _isRecurring,
              onChanged: (bool? value) {
                setState(() {
                  _isRecurring = value ?? false;
                });
              },
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
