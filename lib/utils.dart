import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'deadcodes/last_model/transaction.dart';

String generateTransactionId() {
  final random = Random();
  return 'transac_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

String generateBudgetId() {
  final random = Random();
  return 'budget_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

String generateIncomeId() {
  final random = Random();
  return 'income_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

String generateSavingId() {
  final random = Random();
  return 'saving_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

Future<void> copyRecurringTransactions(String previousBudgetId, String newBudgetId) async {
  final recurringTransactionsSnapshot = await FirebaseFirestore.instance
      .collection('transactions')
      .where('budgetId', isEqualTo: previousBudgetId)
      .where('isRecurring', isEqualTo: true)
      .get();

  for (var transactionDoc in recurringTransactionsSnapshot.docs) {
    final transactionData = transactionDoc.data();

    final newTransaction = TransactionModel(
      id: generateTransactionId(),
      userId: transactionData['userId'],
      amount: transactionData['amount'],
      categoryId: transactionData['categoryId'],
      date: Timestamp.now(),
      type_transaction: transactionData['type_transaction'],
      notes: transactionData['notes'],
      isRecurring: transactionData['isRecurring'],
    );

    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(newTransaction.id)
        .set(newTransaction.toMap());

    await _updateCategorySpending(newBudgetId, newTransaction.categoryId, newTransaction.amount);
  }
}

Future<void> _updateCategorySpending(String budgetId, String categoryId, double amount) async {
  final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(budgetId).get();

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

      await FirebaseFirestore.instance.collection('budgets').doc(budgetId).update({
        'categories': FieldValue.arrayRemove([selectedCategory]),
      });

      await FirebaseFirestore.instance.collection('budgets').doc(budgetId).update({
        'categories': FieldValue.arrayUnion([updatedCategory]),
      });
    }
  }
}

