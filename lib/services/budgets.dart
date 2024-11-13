import 'package:budget_management/services/categories.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../utils/generate_ids.dart';

class BudgetService {

  final FirebaseFirestore _database = FirebaseFirestore.instance;
  final CategoryService _categoryService = CategoryService();

  Future<void> handleMonthTransition({
    required String userId,
    required DateTime date,
  }) async {
    final currentMonth = DateTime(date.year, date.month, 1);
    final previousMonth = DateTime(date.year, date.month - 1, 1);

    // Calcul des transactions récurrentes pour le mois précédent
    final recurringTransactionsSnapshot = await _database
        .collection('debits')
        .where('user_id', isEqualTo: userId)
        .where('isRecurring', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(previousMonth))
        .get();

    if (recurringTransactionsSnapshot.docs.isNotEmpty) {
      await copyRecurringTransactions(recurringTransactionsSnapshot, userId, currentMonth);
    }
  }

  Future<void> updateMonthlyBudgetTotals(String userId, int month, int year) async {
    final budgetRef = _database
        .collection("budgets")
        .where("user_id", isEqualTo: userId)
        .where("month", isEqualTo: month)
        .where('year', isEqualTo: year)
        .limit(1);

    final budgetSnapshot = await budgetRef.get();
    if (budgetSnapshot.docs.isNotEmpty) {
      final budgetDoc = budgetSnapshot.docs.first.reference;

      final creditSnapshot = await _database
          .collection("credits")
          .where("user_id", isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(year, month, 1)))
          .where('date', isLessThan: Timestamp.fromDate(DateTime(year, month + 1, 1)))
          .get();


      final debitSnapshot = await _database
          .collection('debits')
          .where('user_id', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(year, month, 1)))
          .where('date', isLessThan: Timestamp.fromDate(DateTime(year, month + 1, 1)))
          .get();

      double totalCredit = creditSnapshot.docs.fold(0, (sum, doc) => sum + (doc['amount'] as num).toDouble());
      double totalDebit = debitSnapshot.docs.fold(0, (sum, doc) => sum + (doc['amount'] as num).toDouble());

      // Calcul des montants restants
      double remaining = totalCredit - totalDebit;
      double cumulativeRemaining = remaining; // Ajustez en fonction de la logique cumulative

      await budgetDoc.update({
        'total_credit': totalCredit,
        'total_debit': totalDebit,
        'remaining': remaining,
        'cumulativeRemaining': cumulativeRemaining,
      });

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
      );

      await _database.collection("debits").doc(newTransaction.id).set(newTransaction.toMap());
    }
  }

  Future<void> updateBudetTotals(String userId, double amount, {required bool isDebit}) async {
    final currentMonth = DateTime.now();
    final budgetDoc = await _database
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

  Future<void> updateBudgetAfterTransactionDeletion(String userId, double amount, {required bool isDebit}) async {
    final now = DateTime.now();
    final budgetRef = _database
        .collection("budgets")
        .where("user_id", isEqualTo: userId)
        .where("month", isEqualTo: now.month)
        .where("year", isEqualTo: now.year)
        .limit(1);

    final budgetSnapshot = await budgetRef.get();

    if (budgetSnapshot.docs.isNotEmpty) {
      final budgetData = budgetSnapshot.docs.first;
      final double totalDebit = (budgetData['total_debit'] as num?)?.toDouble() ?? 0.0;
      final double totalCredit = (budgetData['total_credit'] as num?)?.toDouble() ?? 0.0;

      // Soustraire le montant supprimé du bon total
      final newTotalDebit = isDebit ? totalDebit - amount : totalDebit;
      final newTotalCredit = isDebit ? totalCredit : totalCredit - amount;

      await budgetData.reference.update({
        'total_debit': newTotalDebit,
        'total_credit': newTotalCredit,
      });
    }
  }

  Future<void> updateCategorySpending(String categoryId, double amount, {bool isDebit = true}) async {
    final categoryRef = await _database.collection('categories').doc(categoryId).get();

    if (categoryRef.exists) {
      final currentSpent = (categoryRef.data()?['spentAmount'] as num?)?.toDouble() ?? 0.0;
      final newAmount = isDebit ? (currentSpent + amount) : (currentSpent - amount);
      await _database.collection("categories").doc(categoryId).update({
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
      await _categoryService.createCategory(category['name']!, userId, category['type']!);
    }

    // Ajouter la catégorie "Revenus" pour les crédits
    await _categoryService.createCategory("Revenus", userId, "credit");
  }

  Future<void> updateCurrentMonthBudget(String userId, double amount, {required bool isDebit}) async {
    final now = DateTime.now();
    final budgetRef = _database
        .collection('budgets')
        .where('user_id', isEqualTo: userId)
        .where('month', isEqualTo: now.month)
        .where('year', isEqualTo: now.year)
        .limit(1);

    final budgetSnapshot = await budgetRef.get();

    if (budgetSnapshot.docs.isNotEmpty) {
      // Si le budget existe, mise à jour des totaux
      final budgetData = budgetSnapshot.docs.first;
      final newTotalDebit = (budgetData['total_debit'] as num).toDouble() + (isDebit ? amount : 0.0);
      final newTotalCredit = (budgetData['total_credit'] as num).toDouble() + (!isDebit ? amount : 0.0);

      await budgetData.reference.update({
        'total_debit': newTotalDebit,
        'total_credit': newTotalCredit,
      });
    } else {
      // Si le budget n'existe pas, création d'un nouveau document
      final newBudget = Budget(
        id: generateTransactionId(),
        user_id: userId,
        month: now.month,
        year: now.year,
        total_debit: isDebit ? amount : 0.0,
        total_credit: !isDebit ? amount : 0.0,
      );
      await FirebaseFirestore.instance.collection('budgets').doc(newBudget.id).set(newBudget.toMap());
    }
  }


  Future<void> updatePreviousMonthBudget(String userId, DateTime date) async {
    final previousMonth = DateTime(date.year, date.month -1 , 1);

    final previousBudgetRef = _database
        .collection('budgets')
        .where('user_id', isEqualTo: userId)
        .where('month', isEqualTo: previousMonth.month)
        .where('year', isEqualTo: previousMonth.year)
        .limit(1);


    final previousBudgetSnapshot = await previousBudgetRef.get();

    if (previousBudgetSnapshot.docs.isNotEmpty) {
      final previousBudget = previousBudgetSnapshot.docs.first;
      final totalDebit = (previousBudget['total_debit'] as num?)?.toDouble() ?? 0.0;
      final totalCredit = (previousBudget['total_credit'] as num?)?.toDouble() ?? 0.0;

      // Calcul des valeurs remaining et cumulativeRemaining
      double remaining = totalCredit - totalDebit;
      double cumulativeRemaining = (previousBudget['cumulativeRemaining'] as num?)?.toDouble() ?? 0.0;
      cumulativeRemaining += remaining;

      await previousBudget.reference.update({
        'remaining': remaining,
        'cumulativeRemaining': cumulativeRemaining,
      });
    }

  }


  Future<void> createOrUpdateMonthlyBudget(String userId, DateTime date) async {
    final budgetRef = _database
        .collection('budgets')
        .where('user_id', isEqualTo: userId)
        .where('month', isEqualTo: date.month)
        .where('year', isEqualTo: date.year)
        .limit(1);

    final budgetSnapshot = await budgetRef.get();

    if (budgetSnapshot.docs.isNotEmpty) {
      // Si le budget existe, aucune action supplémentaire
      return;
    } else {
      // Si le budget n'existe pas, création d'un nouveau document
      final newBudget = Budget(
        id: generateTransactionId(),
        user_id: userId,
        month: date.month,
        year: date.year,
      );
      await _database.collection('budgets').doc(newBudget.id).set(newBudget.toMap());
    }
  }

}
