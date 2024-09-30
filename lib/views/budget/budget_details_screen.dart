import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetDetailsScreen extends StatelessWidget {
  final String budgetId;

  const BudgetDetailsScreen({Key? key, required this.budgetId}) : super(key: key);

  Future<Map<String, dynamic>> _getBudgetDetails() async {
    final budgetSnapshot = await FirebaseFirestore.instance.collection('budgets').doc(budgetId).get();
    return budgetSnapshot.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du budget'),
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
