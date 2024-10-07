import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../services/income_service.dart';
import '../../utils.dart';  // Service pour gérer les revenus

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({Key? key}) : super(key: key);

  @override
  _AddBudgetScreenState createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryAmountController = TextEditingController();
  List<CategoryModel> _categories = [];
  double _totalIncome = 0.0;
  double _remainingIncome = 0.0;

  // Variables pour le mois et l'année
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadUserIncome();
  }

  Future<void> _loadUserIncome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final incomes = await getUserIncomes(user.uid, _selectedMonth, _selectedYear);
      setState(() {
        _totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
        _remainingIncome = _totalIncome;
      });
    }
  }

  void _addCategory() {
    final categoryName = _categoryNameController.text;
    final categoryAmount = double.tryParse(_categoryAmountController.text) ?? 0.0;

    if (categoryName.isNotEmpty && categoryAmount > 0 && categoryAmount <= _remainingIncome) {
      setState(() {
        _categories.add(CategoryModel(name: categoryName, allocatedAmount: categoryAmount));
        _remainingIncome -= categoryAmount;
        _categoryNameController.clear();
        _categoryAmountController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer des informations valides pour la catégorie.")),
      );
    }
  }

  void _editCategory(int index) {
    final category = _categories[index];
    final _editNameController = TextEditingController(text: category.name);
    final _editAmountController = TextEditingController(text: category.allocatedAmount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Modifier la catégorie"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _editNameController,
                decoration: const InputDecoration(labelText: "Nom de la catégorie"),
              ),
              TextField(
                controller: _editAmountController,
                decoration: const InputDecoration(labelText: "Montant alloué"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newName = _editNameController.text;
                final newAmount = double.tryParse(_editAmountController.text) ?? category.allocatedAmount;

                if (newName.isNotEmpty && newAmount > 0 && newAmount <= (_remainingIncome + category.allocatedAmount)) {
                  setState(() {
                    _remainingIncome += category.allocatedAmount - newAmount;
                    _categories[index] = CategoryModel(name: newName, allocatedAmount: newAmount);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Montant alloué supérieur au revenu restant.")),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        );
      },
    );
  }

  void _removeCategory(int index) {
    setState(() {
      _remainingIncome += _categories[index].allocatedAmount;
      _categories.removeAt(index);
    });
  }

  Future<void> _createBudget() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && _categories.isNotEmpty && _descriptionController.text.isNotEmpty) {
      final budget = BudgetModel(
        id: generateBudgetId(),
        userId: user.uid,
        description: _descriptionController.text,
        totalAmount: _totalIncome - _remainingIncome,
        savings: _remainingIncome,
        month: _selectedMonth,
        year: _selectedYear,
        startDate: Timestamp.fromDate(DateTime(_selectedYear, _selectedMonth, 1)),
        endDate: Timestamp.fromDate(DateTime(_selectedYear, _selectedMonth + 1, 0)),
        categories: _categories,
      );

      await FirebaseFirestore.instance.collection('budgets').doc(budget.id).set(budget.toMap());

      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    bool shouldLeave = false;
    if (_categories.isEmpty) {
      shouldLeave = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quitter sans créer un budget?'),
          content: const Text('Vous n\'avez pas encore créé de budget. Êtes-vous sûr de vouloir quitter cette page?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Oui'),
            ),
          ],
        ),
      );
    } else {
      shouldLeave = true;
    }
    return shouldLeave;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Créer un budget mensuel"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description du budget'),
                ),
                const SizedBox(height: 20),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text('Mois ${index + 1}'),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                    });
                  },
                ),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(5, (index) {
                    return DropdownMenuItem(
                      value: DateTime.now().year - index,
                      child: Text('${DateTime.now().year - index}'),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Revenu total: \$${_totalIncome.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20),
                ),
                Text(
                  'Revenu restant: \$${_remainingIncome.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
                const SizedBox(height: 20),
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
                  child: const Text('Ajouter la catégorie'),
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return ListTile(
                      title: Text(category.name),
                      subtitle: Text('Montant alloué: \$${category.allocatedAmount.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editCategory(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeCategory(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _createBudget,
                  child: const Text('Créer le budget'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
