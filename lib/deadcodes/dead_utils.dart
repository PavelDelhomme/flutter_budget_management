import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/dead_saving.dart';
import 'models/dead_transaction.dart';

String dead_generateTransactionId() {
  final random = Random();
  return 'transac_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

String dead_generateBudgetId() {
  final random = Random();
  return 'budget_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

String dead_generateIncomeId() {
  final random = Random();
  return 'income_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

String dead_generateSavingId() {
  final random = Random();
  return 'saving_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

Future<void> dead_copyRecurringTransactions(String previousBudgetId, String newBudgetId) async {
  final recurringTransactionsSnapshot = await FirebaseFirestore.instance
      .collection('transactions')
      .where('budgetId', isEqualTo: previousBudgetId)
      .where('isRecurring', isEqualTo: true)
      .get();

  for (var transactionDoc in recurringTransactionsSnapshot.docs) {
    final transactionData = transactionDoc.data();

    final newTransaction = DeadTransactionModel(
      id: dead_generateTransactionId(),
      userId: transactionData['userId'],
      amount: transactionData['amount'],
      categoryId: transactionData['categoryId'],
      date: Timestamp.now(),
      description: transactionData['description'],
      isRecurring: transactionData['isRecurring'],
    );

    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(newTransaction.id)
        .set(newTransaction.toMap());

    await _dead_updateCategorySpending(newBudgetId, newTransaction.categoryId, newTransaction.amount);
  }
}

Future<void> _dead_updateCategorySpending(String budgetId, String categoryId, double amount) async {
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

Future<void> dead_updateSavingsFromRemainingBudget(String budgetId) async {
  final budgetSnapshot = await FirebaseFirestore.instance.collection('budgets').doc(budgetId).get();

  if (budgetSnapshot.exists) {
    final budgetData = budgetSnapshot.data()!;
    final remainingBalance = budgetData['totalAmount'] - (budgetData['totalExpenses'] ?? 0.0);

    if (remainingBalance > 0) {
      final userId = budgetData['userId'];
      final savingsId = dead_generateSavingId();

      final newSaving = DeadSavingsModel(
        id: savingsId,
        userId: userId,
        category: 'Économies mensuelles',
        amount: remainingBalance,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savings')
          .doc(savingsId)
          .set(newSaving.toMap());
    }
  }
}

