import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/good_models.dart';

import 'generate_ids.dart';

Future<void> updateCategorySpending(
    String budgetId, String categoryId, double amount) async {
  final budgetDoc = await FirebaseFirestore.instance
      .collection('budgets')
      .doc(budgetId)
      .get();

  if (budgetDoc.exists) {
    final List<dynamic> categories = budgetDoc.data()?['categories'] ?? [];
    final selectedCategory = categories.firstWhere(
      (category) => category['id'] == categoryId,
      orElse: () => null,
    );

    if (selectedCategory != null) {
      final updatedCategory = {
        ...selectedCategory,
        'spentAmount': (selectedCategory['spentAmount'] ?? 0.0) + amount,
      };

      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(budgetId)
          .update({
        'categories': FieldValue.arrayRemove([selectedCategory]),
      });

      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(budgetId)
          .update({
        'categories': FieldValue.arrayUnion([updatedCategory]),
      });
    }
  }
}

Future<void> createBudget({
  required String userId,
  required DateTime month,
  required DateTime year,
}) async {
  final budgetId = generateBudgetId();
  final Timestamp monthTimestamp = Timestamp.fromDate(month);
  final Timestamp yearTimestamp = Timestamp.fromDate(year);

  final budget = Budget(
    id: budgetId,
    user_id: userId,
    month: monthTimestamp,
    year: yearTimestamp,
    total_debit: 0.0,
    total_credit: 0.0,
  );

  await FirebaseFirestore.instance
      .collection("budgets")
      .doc(budgetId)
      .set(budget.toMap());
}

Future<void> addDefaultCategoriesToBudget(String budgetId) async {
  List<Categorie> defaultCategories = [
    Categorie(id: generateCategoryId(), name: 'Alimentation'),
    Categorie(id: generateCategoryId(), name: 'Vie sociale'),
    Categorie(id: generateCategoryId(), name: 'Transport'),
    Categorie(id: generateCategoryId(), name: 'Santé'),
    Categorie(id: generateCategoryId(), name: 'Éducation'),
    Categorie(id: generateCategoryId(), name: 'Cadeaux'),
  ];

  for (var category in defaultCategories) {
    await FirebaseFirestore.instance
        .collection('budgets')
        .doc(budgetId)
        .collection('categories')
        .add(category.toMap());
  }
}

Future<void> updateBudgetAfterTransaction(String budgetId, double amount,
    {required bool isDebit}) async {
  final budgetRef =
      FirebaseFirestore.instance.collection('budgets').doc(budgetId);
  final budgetDoc = await budgetRef.get();

  if (budgetDoc.exists) {
    final currentTotalDebit =
        (budgetDoc.data()?['total_debit'] as num).toDouble();
    final currentTotalCredit =
        (budgetDoc.data()?['total_credit'] as num).toDouble();

    if (isDebit) {
      await budgetRef.update({
        'total_debit': currentTotalDebit + amount,
      });
    } else {
      await budgetRef.update({
        'total_credit': currentTotalCredit + amount,
      });
    }
  }
}
