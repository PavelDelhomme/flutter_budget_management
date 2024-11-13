import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/generate_ids.dart';
/*
/// Ajoute une transaction de type Débit.
Future<void> addDebitTransaction({
  required String userId,
  required String categoryId,
  required DateTime date,
  required double amount,
  String? notes,
  List<String>? photos,
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
    photos: photos,
    localisation: location ?? const GeoPoint(0, 0),
    categorie_id: categoryId,
  );

  log("Ajout de transaction de type Débit - ID: $transactionId - Montant: $amount");

  await FirebaseFirestore.instance
      .collection('debits')
      .doc(transactionId)
      .set(debit.toMap());
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

  log("Ajout de transaction de type Crédit - ID: $transactionId - Montant: $amount");

  await FirebaseFirestore.instance
      .collection('credits')
      .doc(transactionId)
      .set(credit.toMap());
  await updateCurrentMonthBudget(userId, amount, isDebit: false);
}

/// Récupère les transactions de type Débit par catégorie pour un utilisateur donné.
Future<List<Debit>> getDebitsForCategory(
    String userId, String categoryId) async {
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

Text formatTransactionAmount(double amount, bool isDebit) {
  String sign = isDebit ? '-' : '+';
  Color amountColor = isDebit ? Colors.red : Colors.green;

  // Log le signe et la couleur du montant
  log("Montant formaté : $sign€${amount.toStringAsFixed(2)} - Couleur : ${amountColor.toString()} - Type : ${isDebit ? 'Débit' : 'Crédit'}");

  return Text(
    "$sign€${amount.toStringAsFixed(2)}",
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: amountColor,
    ),
  );
}

bool isDebitTransaction(DocumentSnapshot transaction) {
  return transaction.reference.parent.id == 'debits';
}
 */