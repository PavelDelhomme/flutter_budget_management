import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/good_models.dart';
import 'budgets.dart';
import 'categories.dart';
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
      categorie_id: transactionData['type'] ? transactionData['categorie_id'] : null,
      user_id: transactionData['user_id'],
      date: DateTime.now(), // Copier pour le mois suivant
      notes: transactionData['notes'],
      isRecurring: transactionData['isRecurring'],
    );

    await FirebaseFirestore.instance
        .collection('transactions')
        .doc(newTransaction.id)
        .set(newTransaction.toMap());

    // Mettre a jour les dépenses pa catégorie si c'est un débit
    if (transactionData['type'] && transactionData['categorie_id'] != null) {
      await updateCategorySpending(transactionData['categorie_id'], transactionData['amount']);
    }

    // ajouter des transaction spécifiques (Débit ou Crédit)
    if (transactionData['type']) {
      final debit = Debit(
        id: newTransaction.id,
        amount: transactionData['amount'],
        localisation: LatLng(transactionData['location'].latitude, transactionData['location'].longitude),
        transaction_id: newTransaction.id,
        photos: List<String>.from(transactionData['receiptUrls'] ?? []),
      );
      await FirebaseFirestore.instance.collection("debits").doc(debit.id).set(debit.toMap());
    } else {
      final credit = Credit(
        id: newTransaction.id,
        transaction_id: newTransaction.id,
        amount: transactionData['amount'],
      );

      await FirebaseFirestore.instance.collection("credits").doc(credit.id).set(credit.toMap());
    }
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
  bool isRecurring = false
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

Future<void> addCreditTransaction ({
  required String budgetId,
  required String userId,
  required DateTime date,
  required double amount,
  String? notes,
  List<String>? receiptUrls,
  LatLng? location,
  bool isRecurring = false,
}) async {
  final transactionId = generateTransactionId();

  final userTransaction = UserTransaction(
    id: transactionId,
    type: false, // Crédit
    user_id: userId,
    date: date,
    notes: notes ?? '',
    isRecurring: isRecurring,
  );

  final credit = Credit(
    id: transactionId,
    transaction_id: transactionId,
    amount: amount,
  );

  await FirebaseFirestore.instance
        .collection("budgets")
        .doc(budgetId)
        .collection("transactions")
        .doc(transactionId)
        .set(userTransaction.toMap());


  // Ajout du crédit spécifique
  await FirebaseFirestore.instance
      .collection("credits")
      .doc(transactionId)
      .set(credit.toMap());


  // Mise à jour du solde
  await updateBudgetAfterTransaction(budgetId, amount, isDebit: false);

}


Future<List<UserTransaction>> getTransactionsForMonth(String userId, int month, int year) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("transactions")
      .where("user_id", isEqualTo: userId)
      .where("date", isGreaterThanOrEqualTo: DateTime(year, month, 1))
      .where("date", isLessThan: DateTime(year, month + 1, 1))
      .get();

  return snapshot.docs.map((doc) => UserTransaction.fromMap(doc.data() as Map<String, dynamic>)).toList();
}

Future<List<UserTransaction>> getTransactionsForYear(String userId, int year) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("transactions")
      .where("user_id", isEqualTo: userId)
      .where("date", isGreaterThanOrEqualTo: DateTime(year, 1, 1))
      .where("date", isLessThan: DateTime(year + 1, 1, 1))
      .get();

  return snapshot.docs.map((doc) => UserTransaction.fromMap(doc.data() as Map<String, dynamic>)).toList();
}

Future<List<UserTransaction>> getTransactionsForCategory(String userId, String categoryId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("transactions")
      .where("user_id", isEqualTo: userId)
      .where("categorie_id", isEqualTo: categoryId)
      .get();

  return snapshot.docs.map((doc) => UserTransaction.fromMap(doc.data() as Map<String, dynamic>)).toList();
}
