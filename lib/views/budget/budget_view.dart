import 'package:flutter/material.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer mes Budgets'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Page de gestion des budgets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Action pour ajouter ou gérer un budget
              },
              child: const Text('Ajouter un budget'),
            ),
          ],
        ),
      ),
    );
  }
}
