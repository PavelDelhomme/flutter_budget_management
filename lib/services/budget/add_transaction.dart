import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/saving.dart';

Future<void> addTransaction({
  required String description,
  required double amount,
  required String categoryId,
  required String budgetId,
  bool useSavings = false,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final budgetRef = FirebaseFirestore.instance.collection('budgets').doc(budgetId);
    final budgetDoc = await budgetRef.get();

    if (budgetDoc.exists) {
      // Récupération des catégories du budget
      final List<dynamic> categories = budgetDoc.data()?['categories'] ?? [];
      final categoryIndex = categories.indexWhere((category) => category['name'] == categoryId);

      if (categoryIndex != -1) {
        final category = categories[categoryIndex];
        final double spentAmount = (category['spentAmount'] as num?)?.toDouble() ?? 0.0;
        final double allocatedAmount = (category['allocatedAmount'] as num?)?.toDouble() ?? 0.0;

        // Calcul du nouveau montant dépensé
        double newSpentAmount = spentAmount + amount;
        if (newSpentAmount > allocatedAmount && useSavings) {
          // Si le nouveau montant dépensé dépasse le budget alloué, on utilise les économies
          double overBudget = newSpentAmount - allocatedAmount;
          await deductFromSavings(user.uid, overBudget);
        }

        // Mise à jour du montant dépensé dans la catégorie
        categories[categoryIndex]['spentAmount'] = newSpentAmount;

        // Mise à jour du document du budget
        await budgetRef.update({'categories': categories});

        // Ajouter la transaction
        await FirebaseFirestore.instance.collection('transactions').add({
          'userId': user.uid,
          'budgetId': budgetId,
          'category': categoryId,
          'description': description,
          'amount': amount,
          'date': Timestamp.now(),
        });
      }
    }
  }
}


Future<void> deductFromSavings(String categoryId, double amountToDeduct) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final savingDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savings')
        .doc(categoryId)
        .get();

    if (savingDoc.exists) {
      final currentAmount = (savingDoc.data()?['amount'] as num?)?.toDouble() ?? 0.0;
      final newAmount = currentAmount - amountToDeduct;

      if (newAmount >= 0) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('savings')
            .doc(categoryId)
            .update({'amount': newAmount});
      } else {
        throw Exception("Pas assez de fonds dans cette catégorie d'économies.");
      }
    }
  }
}
