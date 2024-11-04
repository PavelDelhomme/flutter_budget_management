import 'package:budget_management/utils/categories.dart';
import 'package:budget_management/utils/transactions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/good_models.dart';

import 'generate_ids.dart';

Future<void> createBudget({
  required String userId,
  required DateTime date,
}) async {
  final budgetId = generateBudgetId();
  final Timestamp monthTimestamp = Timestamp.fromDate(DateTime(date.year, date.month, 1));
  final Timestamp yearTimestamp = Timestamp.fromDate(DateTime(date.year, 1, 1));

  double remainingAmountFromPreviousMonth = 0.0;

  // Récupérer le budget du mois précédent
  DateTime previousMonth = DateTime(date.year, date.month - 1, 1);
  final previousBudgetSnapshot = await FirebaseFirestore.instance
      .collection('budgets')
      .where('user_id', isEqualTo: userId)
      .where('month', isEqualTo: Timestamp.fromDate(previousMonth))
      .get();

  if (previousBudgetSnapshot.docs.isNotEmpty) {
    final previousBudget = Budget.fromMap(previousBudgetSnapshot.docs.first.data());
    remainingAmountFromPreviousMonth = previousBudget.total_credit - previousBudget.total_debit;

    print('Copie des transactions récurrentes du mois précédent');
    // Copier les transactions récurrentes du mois précédent
    await copyRecurringTransactions(previousBudget.id, budgetId);
  } else {
    print('Pas de budget pour le mois précédent.');
  }

  // Créer le nouveau budget avec le reste du mois précédent ajouté aux crédits
  final budget = Budget(
    id: budgetId,
    user_id: userId,
    month: monthTimestamp,
    year: yearTimestamp,
    total_debit: 0.0,
    total_credit: remainingAmountFromPreviousMonth,  // Inclure le reste
  );

  print('Création du nouveau budget pour le mois de ${date.month}');
  await FirebaseFirestore.instance
      .collection("budgets")
      .doc(budgetId)
      .set(budget.toMap());

  print('Budget créé avec succès : $budgetId');
}

Future<void> updateBudgetAfterTransaction(String budgetId, double amount, {required bool isDebit}) async {
  final budgetRef = FirebaseFirestore.instance.collection('budgets').doc(budgetId);
  final budgetDoc = await budgetRef.get();

  if (budgetDoc.exists) {
    final currentTotalDebit = (budgetDoc.data()?['total_debit'] as num).toDouble();
    final currentTotalCredit = (budgetDoc.data()?['total_credit'] as num).toDouble();

    if (isDebit) {
      await budgetRef.update({
        'total_debit': currentTotalDebit + amount,
      });
      print('Total Débit mis à jour : ${currentTotalDebit + amount}');
    } else {
      await budgetRef.update({
        'total_credit': currentTotalCredit + amount,
      });
      print('Total Crédit mis à jour : ${currentTotalCredit + amount}');
    }
  } else {
    print('Le budget n\'existe pas : $budgetId');
  }
}

Future<void> createDefaultCategories(String userId) async {
  // Catégories pour les débits (dépenses)
  List<Map<String, String>> debitCategories = [
    {"name": "Logement", "type": "debit"},
    {"name": "Alimentation", "type": "debit"},
    {"name": "Transport", "type": "debit"},
    {"name": "Abonnements", "type": "debit"},
    {"name": "Santé", "type": "debit"},
  ];

  // Catégories pour les crédits (revenus)
  List<Map<String, String>> creditCategories = [
    {"name": "Salaire", "type": "credit"},
    {"name": "Aides", "type": "credit"},
    {"name": "Ventes", "type": "credit"},
  ];

  // Ajouter les catégories de débits
  for (var category in debitCategories) {
    await createCategory(category['name']!, userId, category['type']!);
  }

  // Ajouter les catégories de crédits
  for (var category in creditCategories) {
    await createCategory(category['name']!, userId, category['type']!);
  }
}



Future<void> updateCategorySpending(String categoryId, double amount, {bool isDebit = true}) async {
  final categoryRef = await FirebaseFirestore.instance.collection('categories').doc(categoryId).get();

  if (categoryRef.exists) {
    final currentSpent = (categoryRef.data()?['spentAmount'] as num?)?.toDouble() ?? 0.0;
    final newAmount = isDebit ? (currentSpent + amount) : (currentSpent - amount);
    await FirebaseFirestore.instance.collection("categories").doc(categoryId).update({
      'spentAmount': newAmount,
    });
  } else {
    throw Exception("Catégorie non trouvée.");
  }
}