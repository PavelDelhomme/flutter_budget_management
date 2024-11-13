import 'dart:developer' as dev;
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:budget_management/utils/generate_ids.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/transaction_model.dart';
import '../utils/general.dart';
import 'budgets.dart';


class TransactionService {

  /// Add
  Future<void> addDebitTransaction({
    required BudgetService budgetService, required String userId,
    required String categoryId, required DateTime date, required double amount,
    String? notes, List<String>? photos, GeoPoint? location,
    bool isRecurring = false}) async {
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

    dev.log("Ajout de transaction de type Débit - ID: $transactionId - Montant: $amount");

    await FirebaseFirestore.instance
        .collection('debits')
        .doc(transactionId)
        .set(debit.toMap());
    await budgetService.updateCurrentMonthBudget(userId, amount, isDebit: true);
  }

  Future<void> addCreditTransaction({
    required String userId, required DateTime date, required double amount,
    String? notes, bool isRecurring = false
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
    dev.log("Ajout de transaction de type Crédit - ID: $transactionId - Montant: $amount");

    await FirebaseFirestore.instance
        .collection('credits')
        .doc(transactionId)
        .set(credit.toMap());
    await BudgetService().updateCurrentMonthBudget(userId, amount, isDebit: false);
  }

  /// Récupère les transactions de type Crédit/Débit pour un utilisateur donné.
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
    dev.log("Montant formaté : $sign€${amount.toStringAsFixed(2)} - Couleur : ${amountColor.toString()} - Type : ${isDebit ? 'Débit' : 'Crédit'}");

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

  /// Copie les transactions récurrentes (débit et crédit) pour le mois suivant si elles n'existent pas déjà.
  Future<void> copyRecurringTransactionsForNewMonth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    String currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final userDocRef =
    FirebaseFirestore.instance.collection("users").doc(user.uid);
    final userDoc = await userDocRef.get();
    String lastProcessedMonth = userDoc.data()?['lastProcessedMonth'] ?? '';

    if (lastProcessedMonth == currentMonth) {
      log("Les transactions récurrentes existent déjà pour le mois en cours.");
      return;
    }

    // Met à jour le budget du mois précèdent avant de copier les transactions récurrentes
    await BudgetService().updatePreviousMonthBudget(user.uid, now);

    // Créer le budget pour le mois s'il n'existe pas
    await BudgetService().createOrUpdateMonthlyBudget(user.uid, now);

    // Copie les transactions pour chaque type (débit et crédit)
    await _copyRecurringTransactions(
      'debits',
      user.uid,
          (data, newDate) => Debit(
        id: generateTransactionId(),
        user_id: data['user_id'],
        date: newDate,
        notes: data['notes'],
        isRecurring: data['isRecurring'],
        amount: data['amount'],
        photos: List<String>.from(data['photos'] ?? []),
        localisation: data['localisation'],
        categorie_id: data['categorie_id'],
      ),
    );

    await _copyRecurringTransactions(
      'credits',
      user.uid,
          (data, newDate) => Credit(
        id: generateTransactionId(),
        user_id: data['user_id'],
        date: newDate,
        notes: data['notes'],
        isRecurring: data['isRecurring'],
        amount: data['amount'],
      ),
    );

    // Met à jour le champ `lastProcessedMonth` pour éviter les duplications futures
    await userDocRef.update({
      'lastProcessedMonth': currentMonth,
    });

    log("Copie des transactions récurrentes terminée pour le mois : $currentMonth");
  }
  /// Fonction générique pour copier les transactions récurrentes pour un type donné (débits ou crédits).
  /// Elle utilise un `transactionBuilder` pour construire les instances de transaction appropriées.
  Future<void> _copyRecurringTransactions(
      String collection,
      String userId,
      Function(Map<String, dynamic> data, DateTime newDate) transactionBuilder,
      ) async {
    final recurringTransactionsSnapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('user_id', isEqualTo: userId)
        .where('isRecurring', isEqualTo: true)
        .get();

    for (var doc in recurringTransactionsSnapshot.docs) {
      final data = doc.data();
      DateTime newDate = calculateNewDate((data['date'] as Timestamp).toDate());

      // Vérifie l'existence de la transaction pour éviter les doublons
      bool transactionExists = await FirebaseFirestore.instance
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .where('isRecurring', isEqualTo: true)
          .where('date', isEqualTo: Timestamp.fromDate(newDate))
          .where('amount', isEqualTo: data['amount'])
          .where('categorie_id', isEqualTo: data['categorie_id'])
          .where('notes',
          isEqualTo: data['notes']) // Ajouté pour renforcer la vérification
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty);

      if (!transactionExists) {
        await FirebaseFirestore.instance.collection(collection).doc(doc.id).delete();

        final newTransaction = transactionBuilder(data, newDate);
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(newTransaction.id)
            .set(newTransaction.toMap());
      }
    }
  }

  /// Met à jour les transactions récurrentes pour le mois actuel si elles n'existent pas encore.
  Future<void> updateRecurringTransactionsForCurrentMonth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

    // Met à jour les transactions récurrentes de la collection de débit
    await _updateRecurringTransactions(
      'debits',
      user.uid,
      startOfMonth,
      endOfMonth,
          (data, newDate) => Debit(
        id: generateTransactionId(),
        user_id: data['user_id'],
        date: newDate,
        notes: data['notes'],
        isRecurring: data['isRecurring'],
        amount: data['amount'],
        photos: List<String>.from(data['photos'] ?? []),
        localisation: data['localisation'],
        categorie_id: data['categorie_id'],
      ),
    );
  }

  /// Fonction générique pour mettre à jour les transactions récurrentes pour un mois donné.
  /// `transactionBuilder` est une fonction qui crée l'instance de transaction appropriée.
  Future<void> _updateRecurringTransactions(
      String collection,
      String userId,
      DateTime startOfMonth,
      DateTime endOfMonth,
      Function(Map<String, dynamic> data, DateTime newDate) transactionBuilder,
      ) async {
    final recurringTransactionsSnapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('user_id', isEqualTo: userId)
        .where('isRecurring', isEqualTo: true)
        .get();

    for (var doc in recurringTransactionsSnapshot.docs) {
      final data = doc.data();
      DateTime transactionDate = (data['date'] as Timestamp).toDate();

      // Vérifie l'existence d'une transaction similaire pour le mois en cours
      bool transactionExists = await FirebaseFirestore.instance
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .where('isRecurring', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .where('categorie_id', isEqualTo: data['categorie_id'])
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty);

      if (!transactionExists) {
        DateTime newDate =
        DateTime(startOfMonth.year, startOfMonth.month, transactionDate.day);
        final newTransaction = transactionBuilder(data, newDate);
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(newTransaction.id)
            .set(newTransaction.toMap());
      }
    }
  }

  Future<void> addRetroactiveRecurringTransaction({
    required String userId,
    required String categoryId,
    required DateTime startDate,
    required double amount,
    required bool isDebit,
  }) async {
    DateTime date = startDate;
    while (date.isBefore(DateTime.now())) {
      final collection = isDebit ? 'debits' : 'credits';

      bool transactionExists = await FirebaseFirestore.instance
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .where('isRecurring', isEqualTo: true)
          .where('date', isEqualTo: Timestamp.fromDate(date))
          .where('amount', isEqualTo: amount)
          .where('categorie_id', isEqualTo: categoryId)
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty);

      if (!transactionExists) {
        await FirebaseFirestore.instance.collection(collection).add({
          'user_id': userId,
          'date': date,
          'amount': amount,
          'isRecurring': true,
          'categorie_id': categoryId,
        });
      }
      date = DateTime(date.year, date.month + 1, 1); // Avancer au mois suivant
    }
  }
}