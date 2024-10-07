import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:intl/intl.dart';  // Pour la gestion des dates
import '../../models/budget.dart';
import '../../models/category.dart';
import '../../models/income.dart';  // Modèle des revenus
import '../../services/income_service.dart';  // Service pour gérer les revenus

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({Key? key}) : super(key: key);

  @override
  _AddBudgetScreenState createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  List<CategoryModel> categories = [];
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _categoryAmountController = TextEditingController();

  // Variables pour le mois et l'année
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  double _totalIncome = 0.0;
  double _remainingIncome = 0.0;  // Pour suivre le revenu restant

  @override
  void initState() {
    super.initState();
    _loadUserIncome();
    _generateDefaultCategories();
  }

  Future<void> _loadUserIncome() async {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final incomes = await getUserIncomes(currentMonth, currentYear);

    double totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);

    setState(() {
      _totalIncome = totalIncome;
      _remainingIncome = _totalIncome;
    });
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
      final allocatedAmount = double.tryParse(_categoryAmountController.text) ?? 0.0;
      if (allocatedAmount <= _remainingIncome) {
        setState(() {
          categories.add(CategoryModel(
            name: _categoryNameController.text,
            allocatedAmount: allocatedAmount,
          ));
          _remainingIncome -= allocatedAmount;
          _categoryNameController.clear();
          _categoryAmountController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Montant alloué supérieur au revenu restant.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir le nom et le montant de la catégorie.")),
      );
    }
  }

  void _removeCategory(int index) {
    setState(() {
      _remainingIncome += categories[index].allocatedAmount;
      categories.removeAt(index);
    });
  }

  double _calculateTotalAmount() {
    return categories.fold(0.0, (sum, category) => sum + category.allocatedAmount);
  }

  void _addBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    double totalAmount = _calculateTotalAmount();
    double savings = _remainingIncome;  // Le reste est alloué à l'épargne

    if (user != null && _descriptionController.text.isNotEmpty && categories.isNotEmpty) {
      final budget = BudgetModel(
        id: generateBudgetId(),
        userId: user.uid,
        description: _descriptionController.text,
        totalAmount: totalAmount,
        savings: savings,
        month: _selectedMonth,
        year: _selectedYear,
        startDate: Timestamp.fromDate(DateTime(_selectedYear, _selectedMonth, 1)),
        endDate: Timestamp.fromDate(DateTime(_selectedYear, _selectedMonth + 1, 0)),
        categories: categories,
      );

      await FirebaseFirestore.instance.collection('budgets').doc(budget.id).set(budget.toMap());

      Navigator.pop(context, true);
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Ajouter un budget mensuel')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description du budget'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    DropdownButton<int>(
                      value: _selectedMonth,
                      items: List.generate(12, (index) {
                        return DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text(DateFormat.MMMM().format(DateTime(0, index + 1))),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value!;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(5, (index) {
                        return DropdownMenuItem<int>(
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
                  ],
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      title: Text(category.name),
                      subtitle: Text('Montant alloué: \$${category.allocatedAmount.toStringAsFixed(2)}'),
                      onTap: () => _editCategory(index),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeCategory(index),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Total Budget Estimé: \$${_calculateTotalAmount().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Revenu restant : \$${_remainingIncome.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addBudget,
                  child: const Text('Créer le budget mensuel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editCategory(int index) {
    final category = categories[index];
    final _editController = TextEditingController(text: category.allocatedAmount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier ${category.name}'),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(labelText: 'Nouveau montant alloué'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newAmount = double.tryParse(_editController.text) ?? category.allocatedAmount;
                if (newAmount <= (_remainingIncome + category.allocatedAmount)) {
                  setState(() {
                    _remainingIncome += category.allocatedAmount - newAmount;
                    categories[index] = CategoryModel(
                      name: category.name,
                      allocatedAmount: newAmount,
                      spentAmount: category.spentAmount,
                    );
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Montant alloué supérieur au revenu restant.")),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}
