import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  List<IncomeModel> incomes = [];
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _loadUserIncomes();
  }

  Future<void> _loadUserIncomes() async {
    if (user != null) {
      incomes = await getUserIncomes(user!.uid, DateTime.now().month, DateTime.now().year);
      setState(() {});
    }
  }

  Future<void> _saveIncome() async {
    if (user != null && _sourceController.text.isNotEmpty && _amountController.text.isNotEmpty) {
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
      appBar: AppBar(
        title: const Text("Mon Profil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ajouter une nouvelle source de revenu",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
            ElevatedButton(
              onPressed: _saveIncome,
              child: const Text('Ajouter la source de revenu'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: incomes.length,
                itemBuilder: (context, index) {
                  final income = incomes[index];
                  return ListTile(
                    title: Text('${income.source}: \$${income.amount.toStringAsFixed(2)}'),
                    subtitle: Text('Mois: ${income.month}, Année: ${income.year}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteIncome(income),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
