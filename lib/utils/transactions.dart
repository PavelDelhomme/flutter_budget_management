import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

import '../models/good_models.dart';
import 'budgets.dart';
import 'categories.dart';
import 'generate_ids.dart';

Future<void> copyRecurringTransactions(
    String previousBudgetId, String newBudgetId) async {
  // Copier les transaction réccurentes pour les débits
  final recurringTransactionsSnapshot = await FirebaseFirestore.instance
      .collection('debits')
      .where('budgetId', isEqualTo: previousBudgetId)
      .where('isRecurring', isEqualTo: true)
      .get();

  for (var debitDoc in recurringTransactionsSnapshot.docs) {
    final debitData = debitDoc.data();

    // Création d'une nouvelle transaction de type débit pour le nouveau mois
    final newDebit = Debit(
      id: generateTransactionId(),
      user_id: debitData['user_id'],
      date: DateTime.now(),
      notes: debitData['notes'],
      isRecurring: debitData['isRecurring'],
      amount: debitData['amount'],
      photos: List<String>.from(debitData['photos'] ?? []),
      localisation: debitData['localisation'],
      categorie_id: debitData['categorie_id'],
    );

    // ajouter la nouvelle transaction de type débit
    await FirebaseFirestore.instance.collection("debits").doc(newDebit.id).set(newDebit.toMap());

    // Mettre  a njour les dépenses de la catégorie si elle est présente
    if (debitData['categorie_id'] != null) {
      await updateCategorySpending(debitData['categorie_id'], debitData['amount']);
    }
  }

  // Coppier les transactions réccurenytes pour les crédits
  final recurringCreditsSnapshot = await FirebaseFirestore.instance
    .collection("credits")
    .where('budgetId', isEqualTo: previousBudgetId)
    .where("isReccuring", isEqualTo: true)
    .get();

  for (var creditDoc in recurringCreditsSnapshot.docs) {
    final creditData = creditDoc.data();

    // Cr"er une nouvelle transaction de type crédit pour le nouveau mois
    final newCredit = Credit(
      id: generateTransactionId(),
      user_id: creditData['user_id'],
      date: DateTime.now(),
      notes: creditData['notes'],
      isRecurring: creditData['isReccuring'],
      amount: creditData['amount'],
    );

    // Ajouter la nouvelle transaction de type Crédit
    await FirebaseFirestore.instance.collection('credits').doc(newCredit.id).set(newCredit.toMap());
  }
}


// Ajout d'une transaction de type Débit
Future<void> addDebitTransaction({
  required String budgetId,
  required String userId,
  required String categoryId,
  required DateTime date,
  required double amount,
  String? notes,
  List<String>? receiptUrls,
  GeoPoint? location,
  bool isRecurring = false,
}) async {
  final transactionId = generateTransactionId();
  final debit = Debit(
    id: transactionId,
    user_id: userId,
    date: date,
    notes: notes ?? '',
    isRecurring: isRecurring,
    amount: amount,
    photos: receiptUrls,
    localisation: location ?? const GeoPoint(0, 0),
    categorie_id: categoryId,
  );

  await FirebaseFirestore.instance
      .collection('debits')
      .doc(transactionId)
      .set(debit.toMap());

  await updateBudgetAfterTransaction(budgetId, amount, isDebit: true);
}


// Ajout d'une transaction de type Crédit
Future<void> addCreditTransaction({
  required String budgetId,
  required String userId,
  required DateTime date,
  required double amount,
  String? notes,
  bool isRecurring = false,
}) async {
  final transactionId = generateTransactionId();
  final credit = Credit(
    id: transactionId,
    user_id: userId,
    date: date,
    notes: notes ?? '',
    isRecurring: isRecurring,
    amount: amount,
  );

  await FirebaseFirestore.instance
      .collection('credits')
      .doc(transactionId)
      .set(credit.toMap());

  await updateBudgetAfterTransaction(budgetId, amount, isDebit: false);
}


// Récupérer les transactions du mois actuel par type (Débit ou Crédit)
Future<List<QueryDocumentSnapshot>> _getTransactionsForCurrentMonth(bool isDebit) async {
  final user = FirebaseAuth.instance.currentUser;
  DateTime now = DateTime.now();
  DateTime startOfMonth = DateTime(now.year, now.month, 1);

  var collection = isDebit ? 'debits' : 'credits';

  var query = await FirebaseFirestore.instance
      .collection(collection)
      .where("user_id", isEqualTo: user?.uid)
      .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
      .where("date", isLessThan: Timestamp.fromDate(DateTime(now.year, now.month + 1, 1)))
      .get();

  return query.docs;
}


// Récupérer les transactions par catégorie
Future<List<Debit>> getDebitsForCategory(String userId, String categoryId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("debits")
      .where("user_id", isEqualTo: userId)
      .where("categorie_id", isEqualTo: categoryId)
      .get();

  return snapshot.docs.map((doc) => Debit.fromMap(doc.data() as Map<String, dynamic>)).toList();
}

Future<List<Credit>> getCreditsForCategory(String userId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("credits")
      .where("user_id", isEqualTo: userId)
      .get();

  return snapshot.docs.map((doc) => Credit.fromMap(doc.data() as Map<String, dynamic>)).toList();
}