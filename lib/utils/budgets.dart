import 'package:budget_management/utils/categories.dart';
import 'package:budget_management/utils/transactions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/good_models.dart';

import 'generate_ids.dart';

Future<void> handleMonthTransition({
  required String userId,
  required DateTime date,
}) async {
  final Timestamp monthTimestamp = Timestamp.fromDate(DateTime(date.year, date.month, 1));

  // Obtenir le mois précédent pour copier les transactions récurrentes
  DateTime previousMonth = DateTime(date.year, date.month - 1, 1);

  // Vérifier si des transactions récurrentes existent pour le mois précédent
  final previousTransactionsSnapshot = await FirebaseFirestore.instance
      .collection('debits')
      .where('user_id', isEqualTo: userId)
      .where('isRecurring', isEqualTo: true)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(previousMonth))
      .get();

  // Copier les transactions récurrentes pour le mois courant
  if (previousTransactionsSnapshot.docs.isNotEmpty) {
    print('Copie des transactions récurrentes du mois précédent');
    await copyRecurringTransactions(previousTransactionsSnapshot, userId, monthTimestamp);
  } else {
    print('Pas de transactions récurrentes à copier pour le mois précédent.');
  }
}

// Copie des transactions récurrentes pour le nouveau mois
Future<void> copyRecurringTransactions(
    QuerySnapshot previousTransactionsSnapshot, String userId, Timestamp newMonthTimestamp) async {
  for (var doc in previousTransactionsSnapshot.docs) {
    final transactionData = doc.data() as Map<String, dynamic>;

    DateTime newDate = DateTime(newMonthTimestamp.toDate().year, newMonthTimestamp.toDate().month, transactionData['date'].toDate().day);

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

    await FirebaseFirestore.instance
        .collection("debits")
        .doc(newTransaction.id)
        .set(newTransaction.toMap());

    print('Nouvelle transaction récurrente ajoutée pour le mois : ${newTransaction.id}');
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