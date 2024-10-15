import 'dart:developer';

import 'package:flutter/material.dart';

import '../../models/dead_income.dart';
import '../../services/dead_income_service.dart';
import '../budget/budget/dead_add_budget_screen.dart';

class DeadDefineIncomeView extends StatefulWidget {
  final String userId;

  const DeadDefineIncomeView({Key? key, required this.userId}) : super(key: key);

  @override
  _DeadDefineIncomeViewState createState() => _DeadDefineIncomeViewState();
}

class _DeadDefineIncomeViewState extends State<DeadDefineIncomeView> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _sourceFocusNode = FocusNode();
  bool _isRecurring = false;
  bool _isLoading = false;
  List<DeadIncomeModel> incomes = [];
  DeadIncomeModel? _editingIncome;

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _amountController.dispose();
    _sourceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final source = _sourceController.text;

    // Conversion des virgules en points pour le montant
    String amountText = _amountController.text.replaceAll(",", ".");
    final amount = double.tryParse(amountText) ?? 0.0;

    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    if (source.isNotEmpty && amount > 0) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      if (_editingIncome != null) {
        // Met à jour un revenu existant
        //todo lorsque on modifie un revenu erreur lors de la suppression du revenu
        //todo avoir unn popup pour la modification de revenu

        //todo définir le budget définir le crud pour le budget

        //todo idée de pouvoir avoir des ligne des dépenses et enregistre,
        // pas forcement savoir si salaire.

        //todo Séparer en CRUD pour les
        await dead_updateIncome(
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
        await dead_addIncome(
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

  Future<void> _deleteIncome(DeadIncomeModel income) async {
    if (income.id != null) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      await dead_deleteIncome(widget.userId, income.id!);
      log("Revenu supprimé : ${income.source}");

      _loadIncomes();
    }
  }

  Future<void> _loadIncomes() async {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    incomes = await dead_getUserIncomes(widget.userId, currentMonth, currentYear);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editIncome(DeadIncomeModel income) {
    if (mounted) {
      setState(() {
        _editingIncome = income;
        _sourceController.text = income.source;
        _amountController.text = income.amount.toString();
        _isRecurring = income.isRecurring;
      });
    }
  }

  void _clearForm() {
    /*
    if (mounted) {
      setState(() {
        _editingIncome = null;
        _sourceController.clear();
        _amountController.clear();
        _isRecurring = false;
        _isLoading = false;
      });
    }*/
    _sourceController.clear();
    _amountController.clear();
    FocusScope.of(context).requestFocus(_sourceFocusNode);
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
                focusNode: _sourceFocusNode,
                decoration: const InputDecoration(labelText: 'Source de revenu'),
                textInputAction: TextInputAction.next,
                onEditingComplete: () {
                  FocusScope.of(context).nextFocus();
                },
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Montant'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  _saveIncome();
                },
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
                    MaterialPageRoute(builder: (context) => const DeadAddBudgetScreen()),
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
