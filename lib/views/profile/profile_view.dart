import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/income.dart';
import '../../services/income_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sourceController = TextEditingController();
  final _amountController = TextEditingController();
  final FocusNode _sourceFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  User? user = FirebaseAuth.instance.currentUser;
  List<IncomeModel> incomes = [];
  bool _isRecurring = false;
  bool _isLoading = false;
  String? _editingIncomeId; // Stocker l'id en cour de modification

  @override
  void initState() {
    super.initState();
    _loadUserIncomes();
    if (user != null) {
      _emailController.text = user!.email ?? "";
    }
  }

  @override
  void dispose() {
    _sourceFocusNode.dispose();
    _amountFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _sourceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIncomes() async {
    if (user != null) {
      incomes = await getUserIncomes(
          user!.uid, DateTime.now().month, DateTime.now().year);
      setState(() {});
    }
  }

  Future<void> _saveIncome() async {
    if (user != null &&
        _sourceController.text.isNotEmpty &&
        _amountController.text.isNotEmpty) {
      double amount = double.tryParse(_amountController.text) ?? 0.0;
      String source = _sourceController.text;

      final income = IncomeModel(
        userId: user!.uid,
        source: source,
        amount: amount,
        month: DateTime.now().month,
        year: DateTime.now().year,
        isRecurring: _isRecurring,
      );

      // Si une source est en cours de modification, supprime l'ancienne avant d'ajouter la nouvelle version
      if (_editingIncomeId != null) {
        await deleteIncome(user!.uid, _editingIncomeId!);
      }

      await addIncome(
        userId: user!.uid,
        source: source,
        amount: amount,
        month: income.month,
        year: income.year,
        isRecurring: income.isRecurring,
      );

      _loadUserIncomes();
      _clearForm();
    }
  }

  Future<void> _updateEmail() async {
    if (user != null && _emailController.text.isNotEmpty) {
      try {
        await user!.updateEmail(_emailController.text);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Email mis à jour.")));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur : $e")));
      }
    }
  }

  Future<void> _updatePassword() async {
    if (user != null && _passwordController.text.isNotEmpty) {
      try {
        await user!.updatePassword(_passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mot de passe mis à jour.')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _clearForm() {
    _sourceController.clear();
    _amountController.clear();
    _isRecurring = false;
    _editingIncomeId = null;
    // Re-focus sur la source de revenu après ajout ou modification
    FocusScope.of(context).requestFocus(_sourceFocusNode);
  }

  Future<void> _deleteIncome(IncomeModel income) async {
    if (income.id != null) {
      await deleteIncome(user!.uid, income.id!);
      _loadUserIncomes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mon Profil")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpansionTile(
                title: const Text("Modifier l'adresse email"),
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                        labelText: "Nouvelle adresse email"),
                  ),
                  ElevatedButton(
                    onPressed: _updateEmail,
                    child: const Text("Mettre à jour l'e-mail"),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text("Modifier le mot de passe"),
                children: [
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                        labelText: "Nouveau mot de passe"),
                    obscureText: true,
                  ),
                  ElevatedButton(
                    onPressed: _updatePassword,
                    child: const Text("Mettre à jour le mot de passe"),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text("Gérer les sources de revenu"),
                children: [
                  TextField(
                    controller: _sourceController,
                    focusNode: _sourceFocusNode,
                    decoration:
                        const InputDecoration(labelText: "Source de revenu"),
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () {
                      // Focus vers le champs "Montant"
                      FocusScope.of(context).requestFocus(_amountFocusNode);
                    },
                  ),
                  TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    decoration: const InputDecoration(labelText: 'Montant'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () {
                      // Validation via clavier
                      _saveIncome();
                      FocusScope.of(context).unfocus();
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
                  ElevatedButton(
                    onPressed: _saveIncome,
                    child: const Text("Ajouter ou Modifier la source"),
                  ),
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: incomes.length,
                    itemBuilder: (context, index) {
                      final income = incomes[index];
                      return ListTile(
                        title: Text("${income.source}: \$${income.amount.toStringAsFixed(2)}"),
                        subtitle: Text('Mois: ${income.month}, Année: ${income.year}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                setState(() {
                                  _sourceController.text = income.source;
                                  _amountController.text = income.amount.toString();
                                  _isRecurring = income.isRecurring;
                                  _editingIncomeId = income.id;
                                  FocusScope.of(context).requestFocus(_sourceFocusNode); // Remise du focus sur le champ source
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteIncome(income),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
