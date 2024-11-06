import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/good_models.dart';
import 'budgets.dart';
import 'generate_ids.dart';

/// Ajoute une transaction de type Débit.
Future<void> addDebitTransaction({
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

  await FirebaseFirestore.instance.collection('debits').doc(transactionId).set(debit.toMap());
  await updateCurrentMonthBudget(userId, amount, isDebit: true);
}

/// Ajoute une transaction de type Crédit.
Future<void> addCreditTransaction({
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

  await FirebaseFirestore.instance.collection('credits').doc(transactionId).set(credit.toMap());
  await updateCurrentMonthBudget(userId, amount, isDebit: false);
}

/// Récupère les transactions de type Débit par catégorie pour un utilisateur donné.
Future<List<Debit>> getDebitsForCategory(String userId, String categoryId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("debits")
      .where("user_id", isEqualTo: userId)
      .where("categorie_id", isEqualTo: categoryId)
      .get();

  return snapshot.docs
      .map((doc) => Debit.fromMap(doc.data() as Map<String, dynamic>))
      .toList();
}

/// Récupère les transactions de type Crédit pour un utilisateur donné.
Future<List<Credit>> getCreditsForCategory(String userId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("credits")
      .where("user_id", isEqualTo: userId)
      .get();

  return snapshot.docs
      .map((doc) => Credit.fromMap(doc.data() as Map<String, dynamic>))
      .toList();
}
