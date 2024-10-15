import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'deadcodes/last_model/transaction.dart';
import 'models/good_models.dart';

String generateTransactionId() {
  final random = Random();
  return 'transac_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

String generateBudgetId() {
  final random = Random();
  return 'budget_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}
String generateCategoryId() {
  final random = Random();
  return 'category_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
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
    userId: userId,
    month: monthTimestamp,
    year: yearTimestamp,
    solde: 0.0,  // Solde initial à 0
    total_debit: 0.0,
    total_credit: 0.0,
  );

  await FirebaseFirestore.instance.collection("budgets").doc(budgetId).set(budget.toMap());
}

Future<void> addDefaultCategoriesToBudget(String budgetId) async {
  List<Categorie> defaultCategories = [
    Categorie(id: generateCategoryId(), nom: 'Alimentation'),
    Categorie(id: generateCategoryId(), nom: 'Vie sociale'),
    Categorie(id: generateCategoryId(), nom: 'Transport'),
    Categorie(id: generateCategoryId(), nom: 'Santé'),
    Categorie(id: generateCategoryId(), nom: 'Éducation'),
    Categorie(id: generateCategoryId(), nom: 'Cadeaux'),
    // Ajoute plus de catégories si nécessaire
  ];

  for (var category in defaultCategories) {
    await FirebaseFirestore.instance.collection('budgets').doc(budgetId).collection('categories').add(category.toMap());
  }
}


Future<void> addDebitTransaction({
  required String budgetId,
  required String categoryId,
  required String userId,
  required DateTime date,
  required double amount,
  String? notes,
  List<String>? receiptUrls,
  LatLng? location,
}) async {
  final transactionId = generateTransactionId();
  final debit = Debit(
    id: transactionId,
    type: "debit",
    category_id: categoryId,
    user_id: userId,
    date: date,
    notes: notes ?? '',
    isRemaining: true,  // Par défaut à true, peut être ajusté selon le besoin
    transaction_id: transactionId,
    amount: amount,
    receiptUrls: receiptUrls,
    location: location,
  );

  // Ajout de la transaction à Firestore
  await FirebaseFirestore.instance.collection('budgets').doc(budgetId).collection('transactions').add(debit.toMap());

  // Mise à jour du solde et du total de débit dans le budget
  await updateBudgetAfterTransaction(budgetId, amount, isDebit: true);
}


Future<void> updateBudgetAfterTransaction(String budgetId, double amount, {required bool isDebit}) async {
  final budgetRef = FirebaseFirestore.instance.collection('budgets').doc(budgetId);
  final budgetDoc = await budgetRef.get();

  if (budgetDoc.exists) {
    final currentSolde = (budgetDoc.data()?['solde'] as num).toDouble();
    final currentTotalDebit = (budgetDoc.data()?['total_debit'] as num).toDouble();
    final currentTotalCredit = (budgetDoc.data()?['total_credit'] as num).toDouble();

    if (isDebit) {
      // Mettre à jour le total de débit et le solde
      await budgetRef.update({
        'solde': currentSolde - amount,
        'total_debit': currentTotalDebit + amount,
      });
    } else {
      // Mettre à jour le total de crédit et le solde
      await budgetRef.update({
        'solde': currentSolde + amount,
        'total_credit': currentTotalCredit + amount,
      });
    }
  }
}
