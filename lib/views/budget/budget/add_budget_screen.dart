import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../deadcodes/last_model/budget.dart';
import '../../../models/category.dart';
import '../../../utils.dart';
import '../../navigation/tab_navigation.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({Key? key}) : super(key: key);

  @override
  _AddBudgetScreenState createState() => _AddBudgetScreenState();
}


class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  //todo définir des catégories par défaut
  double _totalIncome = 0.0;
  double _remainingIncome = 0.0;
  bool _isLoading = true; // Indicateur de chargement des revenus

  // Variables pour le mois et l'année
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _descriptionController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }


  Future<void> _createBudget() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {

      final description = _descriptionController.text.isEmpty
          ? 'Budget sans description'
          : _descriptionController.text;

      final budget = BudgetModel(
        id: generateBudgetId(),
        userId: user.uid,
        month: _selectedMonth,
        year: _selectedYear,
        startDate: Timestamp.fromDate(DateTime(_selectedYear, _selectedMonth, 1)),
        endDate: Timestamp.fromDate(DateTime(_selectedYear, _selectedMonth + 1, 0)),
        categories: _categories, // Récupérer les catégories définies par défaut
      );

      await FirebaseFirestore.instance.collection('budgets').doc(budget.id).set(budget.toMap());

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => TabNavigation(budgetId: budget.id)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une catégorie.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un budget mensuel"),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator()) // Afficher un indicateur de chargement pendant que les revenus se chargent
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
                focusNode: _descriptionFocusNode,
                decoration: const InputDecoration(labelText: 'Description du budget'),
                onEditingComplete: () {
                  // Passer le focus au champ "Nom de la catégorie"
                  FocusScope.of(context).requestFocus(_categoryNameFocusNode);
                },
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
                focusNode: _categoryNameFocusNode,
                decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
                textInputAction: TextInputAction.next,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(_categoryAmountFocusNode);
                },
              ),
              /*ElevatedButton(
                onPressed: _addCategory,
                child: const Text('Ajouter la catégorie'),
              ),*/
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ListTile(
                    title: Text(category.name),
                    subtitle: Text('Montant dépensé: \$${category.spentAmount.toStringAsFixed(2)}'),
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
    );
  }
}