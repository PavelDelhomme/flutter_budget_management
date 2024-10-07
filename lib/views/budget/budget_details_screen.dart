import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetDetailsScreen extends StatefulWidget {
  final String budgetId;

  const BudgetDetailsScreen({Key? key, required this.budgetId}) : super(key: key);

  @override
  _BudgetDetailsScreenState createState() => _BudgetDetailsScreenState();
}

class _BudgetDetailsScreenState extends State<BudgetDetailsScreen> {
  Future<Map<String, dynamic>> _getBudgetDetails() async {
    final budgetSnapshot = await FirebaseFirestore.instance.collection('budgets').doc(widget.budgetId).get();
    return budgetSnapshot.data() as Map<String, dynamic>;
  }

  void _updateCategory(String categoryName, double newAllocatedAmount) async {
    final budgetRef = FirebaseFirestore.instance.collection('budgets').doc(widget.budgetId);
    final budgetSnapshot = await budgetRef.get();
    if (budgetSnapshot.exists) {
      final budgetData = budgetSnapshot.data()!;
      final categories = List<Map<String, dynamic>>.from(budgetData['categories']);

      // Mise à jour du montant alloué à la catégorie
      final categoryIndex = categories.indexWhere((category) => category['name'] == categoryName);
      if (categoryIndex != -1) {
        categories[categoryIndex]['allocatedAmount'] = newAllocatedAmount;
        await budgetRef.update({'categories': categories});

        // Mettre à jour le montant total du budget
        final totalAmount = categories.fold(0.0, (sum, category) => sum + (category['allocatedAmount'] as num).toDouble());
        await budgetRef.update({'totalAmount': totalAmount});

        setState(() {}); // Rafraîchit l'affichage
      }
    }
  }

  void _addCategory(String categoryName, double allocatedAmount) async {
    final budgetRef = FirebaseFirestore.instance.collection('budgets').doc(widget.budgetId);
    final budgetSnapshot = await budgetRef.get();
    if (budgetSnapshot.exists) {
      final budgetData = budgetSnapshot.data()!;
      final categories = List<Map<String, dynamic>>.from(budgetData['categories']);

      // Ajouter une nouvelle catégorie
      categories.add({
        'name': categoryName,
        'allocatedAmount': allocatedAmount,
        'spentAmount': 0.0,
      });

      await budgetRef.update({'categories': categories});

      // Mettre à jour le montant total du budget
      final totalAmount = categories.fold(0.0, (sum, category) => sum + (category['allocatedAmount'] as num).toDouble());
      await budgetRef.update({'totalAmount': totalAmount});

      setState(() {}); // Rafraîchit l'affichage
    }
  }

  void _showEditCategoryDialog(String categoryName, double currentAmount) {
    final _amountController = TextEditingController(text: currentAmount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier la catégorie $categoryName'),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Montant alloué'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newAmount = double.tryParse(_amountController.text) ?? currentAmount;
                _updateCategory(categoryName, newAmount);
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final _nameController = TextEditingController();
    final _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter une catégorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
              ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant alloué'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final categoryName = _nameController.text.trim();
                final allocatedAmount = double.tryParse(_amountController.text) ?? 0.0;
                if (categoryName.isNotEmpty && allocatedAmount > 0.0) {
                  _addCategory(categoryName, allocatedAmount);
                }
                Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getBudgetDetails(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgetData = snapshot.data!;
          final categories = budgetData['categories'] as List<dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description: ${budgetData['description']}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Montant total: \$${budgetData['totalAmount']}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Catégories:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(category['name']),
                        subtitle: Text('Montant alloué: \$${category['allocatedAmount']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditCategoryDialog(category['name'], (category['allocatedAmount'] as num).toDouble());
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
