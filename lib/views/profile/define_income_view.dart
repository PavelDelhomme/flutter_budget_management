import 'dart:developer';

import 'package:flutter/material.dart';
import '../../models/income.dart';
import '../../services/income_service.dart';
import '../budget/budget/add_budget_screen.dart';

class DefineIncomeView extends StatefulWidget {
  final String userId;

  const DefineIncomeView({Key? key, required this.userId}) : super(key: key);

  @override
  _DefineIncomeViewState createState() => _DefineIncomeViewState();
}

class _DefineIncomeViewState extends State<DefineIncomeView> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isRecurring = false;
  bool _isLoading = false;
  List<IncomeModel> incomes = [];
  IncomeModel? _editingIncome;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _saveIncome() async {
    final source = _sourceController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    if (source.isNotEmpty && amount > 0) {
      setState(() {
        _isLoading = true;
      });

      if (_editingIncome != null) {
        // Met à jour un revenu existant
        await updateIncome(
          incomeId: _editingIncome!.id!,
          userId: widget.userId,
          source: source,
          amount: amount,
          month: currentMonth,
          year: currentYear,
          isRecurring: _isRecurring,
        );
        log("Revenu modifié : $source, Montant: $amount");
      } else {
        // Ajoute un nouveau revenu
        await addIncome(
          userId: widget.userId,
          source: source,
          amount: amount,
          month: currentMonth,
          year: currentYear,
          isRecurring: _isRecurring,
        );
        log("Revenu ajouté : $source, Montant: $amount");
      }

      _loadIncomes();
      _clearForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une source de revenu valide et un montant.')),
      );
      log("Veuillez entrer une source de revenu valide et un montant.");
    }
  }

  Future<void> _deleteIncome(IncomeModel income) async {
    if (income.id != null) {
      setState(() {
        _isLoading = true;
      });

      await deleteIncome(widget.userId, income.id!);
      log("Revenu supprimé : ${income.source}");

      _loadIncomes();
    }
  }

  Future<void> _loadIncomes() async {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    incomes = await getUserIncomes(widget.userId, currentMonth, currentYear);
    setState(() {
      _isLoading = false;
    });
  }

  void _editIncome(IncomeModel income) {
    setState(() {
      _editingIncome = income;
      _sourceController.text = income.source;
      _amountController.text = income.amount.toString();
      _isRecurring = income.isRecurring;
    });
  }

  void _clearForm() {
    setState(() {
      _editingIncome = null;
      _sourceController.clear();
      _amountController.clear();
      _isRecurring = false;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Définir vos revenus')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Veuillez entrer vos sources de revenus pour ce mois.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _sourceController,
                decoration: const InputDecoration(labelText: 'Source de revenu'),
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Montant'),
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value!;
                      });
                    },
                  ),
                  const Text("Récurrent"),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _saveIncome,
                child: Text(_editingIncome != null ? 'Modifier la source' : 'Ajouter une source'),
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                itemCount: incomes.length,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final income = incomes[index];
                  return ListTile(
                    title: Text('${income.source}: \$${income.amount.toStringAsFixed(2)}'),
                    subtitle: Text(
                      'Mois: ${income.month}, Année: ${income.year}, ${income.isRecurring ? 'Récurrent' : 'Ponctuel'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editIncome(income),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteIncome(income),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_sourceController.text.isNotEmpty && _amountController.text.isNotEmpty) {
                    await _saveIncome();
                  }

                  // Passe à l'étape de création de budget
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
                  );
                },
                child: const Text('Continuer à la création de budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
