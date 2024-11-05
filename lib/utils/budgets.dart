import 'package:budget_management/utils/categories.dart';
import 'package:budget_management/utils/transactions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/good_models.dart';

import 'generate_ids.dart';

Future<void> handleMonthTransition({
  required String userId,
  required DateTime date,
}) async {
  final currentMonth = DateTime(date.year, date.month, 1);
  final previousMonth = DateTime(date.year, date.month - 1, 1);

  // Calcul des transactions récurrentes pour le mois précédent
  final recurringTransactionsSnapshot = await FirebaseFirestore.instance
      .collection('debits')
      .where('user_id', isEqualTo: userId)
      .where('isRecurring', isEqualTo: true)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(previousMonth))
      .get();

  if (recurringTransactionsSnapshot.docs.isNotEmpty) {
    await copyRecurringTransactions(recurringTransactionsSnapshot, userId, currentMonth);
  }
}


// Copie des transactions récurrentes pour le nouveau mois
Future<void> copyRecurringTransactions(
    QuerySnapshot previousTransactionsSnapshot, String userId, DateTime newMonth
    ) async {
  for (var doc in previousTransactionsSnapshot.docs) {
    final transactionData = doc.data() as Map<String, dynamic>;
    final newDate = DateTime(newMonth.year, newMonth.month, transactionData['date'].toDate().day);

    final newTransaction = Debit(
      id: generateTransactionId(),
      user_id: userId,
      date: newDate,
      notes: transactionData['notes'],
      isRecurring: transactionData['isRecurring'],
      amount: transactionData['amount'],
      photos: List<String>.from(transactionData['photos'] ?? []),
      localisation: transactionData['localisation'],
      categorie_id: transactionData['categorie_id'],
      isValidated: false,
    );

    await FirebaseFirestore.instance.collection("debits").doc(newTransaction.id).set(newTransaction.toMap());
  }
}

Future<void> updateBudetTotals(String userId, double amount, {required bool isDebit}) async {
  final currentMonth = DateTime.now();
  final budgetDoc = await FirebaseFirestore.instance
    .collection('budgets')
    .where('user_id', isEqualTo: userId)
    .where('month', isEqualTo: currentMonth.month)
    .where('year', isEqualTo: currentMonth.year)
    .limit(1)
    .get();

  if (budgetDoc.docs.isNotEmpty) {
    final budgetData = budgetDoc.docs.first;
    final double totalDebit = (budgetData['total_debit'] as num?)?.toDouble() ?? 0.0;
    final double totalCredit = (budgetData['total_credit'] as num?)?.toDouble() ?? 0.0;

    final newTotalDebit = isDebit ? totalDebit + amount : totalDebit;
    final newTotalCredit = isDebit ? totalCredit : totalCredit + amount;

    await budgetData.reference.update({
      'total_debit': newTotalDebit,
      'total_credit': newTotalCredit,
    });
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

Future<void> createDefaultCategories(String userId) async {
  // Catégories pour les débits (dépenses)
  List<Map<String, String>> debitCategories = [
    {"name": "Logement", "type": "debit"},
    {"name": "Alimentation", "type": "debit"},
    {"name": "Transport", "type": "debit"},
    {"name": "Abonnements", "type": "debit"},
    {"name": "Santé", "type": "debit"},
  ];

  // Ajouter les catégories de débits
  for (var category in debitCategories) {
    await createCategory(category['name']!, userId, category['type']!);
  }

  // Ajouter la catégorie "Revenus" pour les crédits
  await createCategory("Revenus", userId, "credit");
}
