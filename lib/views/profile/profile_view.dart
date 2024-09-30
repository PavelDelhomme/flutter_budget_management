import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final TextEditingController _incomeController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  double _currentIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserIncome();
  }

  Future<void> _loadUserIncome() async {
    if (user != null) {
      final incomeSnapshot = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        _currentIncome = incomeSnapshot['income'] ?? 0.0;
        _incomeController.text = _currentIncome.toString();
      });
    }
  }

  Future<void> _saveIncome() async {
    if (user != null && _incomeController.text.isNotEmpty) {
      double income = double.tryParse(_incomeController.text) ?? 0.0;
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'income': income,
      }, SetOptions(merge: true));
      setState(() {
        _currentIncome = income;
      });
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
              "Information de l'utilisateur",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Email : ${user?.email ?? 'Non disponible'}'),
            const SizedBox(height: 10),
            Text('ID utilisateur : ${user?.uid ?? 'Non disponible'}'),
            const SizedBox(height: 20),
            TextField(
              controller: _incomeController,
              decoration: const InputDecoration(
                labelText: 'Revenu mensuel',
              ),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: _saveIncome,
              child: const Text('Enregistrer le revenu'),
            ),
          ],
        ),
      ),
    );
  }
}
