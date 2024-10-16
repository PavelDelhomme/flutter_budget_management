import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/good_models.dart';
import 'budgets.dart';
import 'generate_ids.dart';

Future<void> copyRecurringTransactions(
    String previousBudgetId, String newBudgetId) async {
  final recurringTransactionsSnapshot = await FirebaseFirestore.instance
      .collection('transactions')
      .where('budgetId', isEqualTo: previousBudgetId)
      .where('isRecurring', isEqualTo: true)
      .get();

  for (var transactionDoc in recurringTransactionsSnapshot.docs) {
    final transactionData = transactionDoc.data();

    final newTransaction = UserTransaction(
      id: generateTransactionId(),
      type: transactionData['type'],
      categorie_id: transactionData['categorie_id'],
      user_id: transactionData['user_id'],
      date: (transactionData['date'] as Timestamp).toDate(),
      notes: transactionData['notes'],
      isRemaining: transactionData['isRemaining'],
    );

    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(newTransaction.id)
        .set(newTransaction.toMap());

    await updateCategorySpending(
        newBudgetId, newTransaction.categorie_id, transactionData['amount']);
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
    amount: amount,
    localisation: location ?? LatLng(0, 0),
    transaction_id: transactionId,
    photos: receiptUrls,
  );

  // Ajout de la transaction à Firestore
  await FirebaseFirestore.instance
      .collection('budgets')
      .doc(budgetId)
      .collection('transactions')
      .add(debit.toMap());

  // Mise à jour du solde et du total de débit dans le budget
  await updateBudgetAfterTransaction(budgetId, amount, isDebit: true);
}
