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
  User? user = FirebaseAuth.instance.currentUser;
  List<IncomeModel> incomes = [];
  bool _isRecurring = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserIncomes();
    if (user != null) {
      _emailController.text = user!.email ?? "";
    }
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
                    decoration:
                        const InputDecoration(labelText: "Source de revenu"),
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
