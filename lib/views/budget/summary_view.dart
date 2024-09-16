import 'package:budget_management/views/budget/logix/add_budget.dart';
import 'package:flutter/material.dart';

class SummaryView extends StatelessWidget {
  const SummaryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé du budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Budget',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Remplace avec les données réelles du budget
            const Text(
              'Budget: \$5000',
              style: TextStyle(fontSize: 20),
            ),
            const Text(
              'Dépenses: \$1500',
              style: TextStyle(fontSize: 20),
            ),
            const Text(
              'Solde restant: \$3500',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await createBudget(totalAmount: 5000.0);
              },
              child: const Text('Créer un nouveau budget'),
            ),
          ],
        ),
      ),
    );
  }
}
