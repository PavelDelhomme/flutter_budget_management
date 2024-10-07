import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/saving.dart';
import 'models/transaction.dart';

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
      description: transactionData['description'],
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

Future<void> updateSavingsFromRemainingBudget(String budgetId) async {
  final budgetSnapshot = await FirebaseFirestore.instance.collection('budgets').doc(budgetId).get();

  if (budgetSnapshot.exists) {
    final budgetData = budgetSnapshot.data()!;
    final remainingBalance = budgetData['totalAmount'] - (budgetData['totalExpenses'] ?? 0.0);

    if (remainingBalance > 0) {
      final userId = budgetData['userId'];
      final savingsId = generateSavingId();

      final newSaving = SavingsModel(
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
