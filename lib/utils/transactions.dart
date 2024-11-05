import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/good_models.dart';
import 'budgets.dart';
import 'generate_ids.dart';

DateTime _calculateNewDate(DateTime originalDate) {
  int year = originalDate.year;
  int month = originalDate.month + 1;

  // Si on passe à une nouvelle année
  if (month > 12) {
    month = 1;
    year++;
  }

  int day = originalDate.day;

  // Trouver le dernier jour du mois cible si le jour original dépasse la fin du mois
  int lastDayOfMonth = DateTime(year, month + 1, 0).day;
  if (day > lastDayOfMonth) {
    day = lastDayOfMonth;
  }

  return DateTime(year, month, day);
}

/*
Future<void> copyRecurringTransactionsForNewMonth() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    DateTime now = DateTime.now();

    // Récupérer les transactions récurrentes de débit pour le mois suivant
    final recurringDebitTransactionsSnapshot = await FirebaseFirestore.instance
        .collection('debits')
        .where('user_id', isEqualTo: user.uid)
        .where('isRecurring', isEqualTo: true)
        .get();

    log("DateTime now.month : ${DateTime(now.year, now.month, now.day)}");
    log("DateTime now.month - 1 : ${DateTime(now.year, now.month - 1, now.day)}");

    for (var debitDoc in recurringDebitTransactionsSnapshot.docs) {
      final debitData = debitDoc.data();

      DateTime ancienneDate = (debitData['date'] as Timestamp).toDate();
      DateTime previousMonth = DateTime(ancienneDate.year, ancienneDate.month - 1, ancienneDate.day);
      if (ancienneDate == previousMonth) {
        DateTime newDate = _calculateNewDate(ancienneDate);

        final newDebit = Debit(
          id: generateTransactionId(),
          user_id: debitData['user_id'],
          date: newDate,
          notes: debitData['notes'],
          isRecurring: debitData['isRecurring'],
          amount: debitData['amount'],
          photos: List<String>.from(debitData['photos'] ?? []),
          localisation: debitData['localisation'],
          categorie_id: debitData['categorie_id'],
        );

        await FirebaseFirestore.instance
            .collection("debits")
            .doc(newDebit.id)
            .set(newDebit.toMap());
      }
      /*bool transactionExists = await FirebaseFirestore.instance
          .collection('debits')
          .where('user_id', isEqualTo: user.uid)
          .where('isRecurring', isEqualTo: true)
          .where('date', isEqualTo: Timestamp.fromDate(newDate))
          .where('categorie_id', isEqualTo: debitData['categorie_id'])
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty);*/
      }
    }

    // Récupérer les transactions récurrentes de crédit pour le mois suivant
  /*
    final recurringCreditTransactionsSnapshot = await FirebaseFirestore.instance
        .collection('credits')
        .where('user_id', isEqualTo: user.uid)
        .where('isRecurring', isEqualTo: true)
        .get();

    for (var creditDoc in recurringCreditTransactionsSnapshot.docs) {
      final creditData = creditDoc.data();
      DateTime newDate = _calculateNewDate((creditData['date'] as Timestamp).toDate());

      bool transactionExists = await FirebaseFirestore.instance
          .collection('credits')
          .where('user_id', isEqualTo: user.uid)
          .where('isRecurring', isEqualTo: true)
          .where('date', isEqualTo: Timestamp.fromDate(newDate))
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty);

      if (!transactionExists) {
        final newCredit = Credit(
          id: generateTransactionId(),
          user_id: creditData['user_id'],
          date: newDate,
          notes: creditData['notes'],
          isRecurring: creditData['isRecurring'],
          amount: creditData['amount'],
        );

        await FirebaseFirestore.instance
            .collection("credits")
            .doc(newCredit.id)
            .set(newCredit.toMap());
      }
    }
  }*/
}
 */
/*
Future<void> updateRecurringTransactionsForCurrentMonth() async  {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

    final recurringTransactionsSnapshot = await FirebaseFirestore.instance
      .collection("debits")
      .where('user_id', isEqualTo: user.uid)
      .where('isRecurring', isEqualTo: true)
      .get();

    for (var doc in recurringTransactionsSnapshot.docs) {
      DateTime transactionDate = (doc['date'] as Timestamp).toDate();

      // Si une transaction similaire n'existe pas déjà pour le mois en cours
      bool transactionExists = await FirebaseFirestore.instance
          .collection('debits')
          .where('user_id', isEqualTo: user.uid)
          .where('isRecurring', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .where('categorie_id', isEqualTo: doc['categorie_id'])
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty);

      if (!transactionExists) {
        DateTime newTransactionDate = DateTime(now.year, now.month, transactionDate.day);

        // Créer une transaction pour le mois actuel
        final newTransaction = {
          "id": generateTransactionId(),
          "user_id": user.uid,
          "date": Timestamp.fromDate(newTransactionDate),
          "notes": doc['notes'],
          "isRecurring": doc['isRecurring'],
          "amount": doc['amount'],
          "photos": doc['photos'] ?? [],
          "localisation": doc['localisation'],
          'categorie_id': doc['categorie_id'],
        };

        await FirebaseFirestore.instance.collection("debits").doc(newTransaction['id']).set(newTransaction);
      }
    }
  }
}
*/

Future<void> copyRecurringTransactionsForNewMonth() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

    // Vérifiez si des transactions récurrentes existent déjà pour le mois courant
    final existingDebitTransactions = await FirebaseFirestore.instance
        .collection('debits')
        .where('user_id', isEqualTo: user.uid)
        .where('isRecurring', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    final existingCreditTransactions = await FirebaseFirestore.instance
        .collection('credits')
        .where('user_id', isEqualTo: user.uid)
        .where('isRecurring', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    if (existingDebitTransactions.docs.isNotEmpty || existingCreditTransactions.docs.isNotEmpty) {
      log("Les transactions récurrentes existent déjà pour le mois en cours.");
      return;
    }

    // Si elles n'existent pas, copier les transactions récurrentes de débit
    final recurringDebitTransactionsSnapshot = await FirebaseFirestore.instance
        .collection('debits')
        .where('user_id', isEqualTo: user.uid)
        .where('isRecurring', isEqualTo: true)
        .get();

    for (var debitDoc in recurringDebitTransactionsSnapshot.docs) {
      final debitData = debitDoc.data();
      DateTime newDate = _calculateNewDate((debitData['date'] as Timestamp).toDate());

      final newDebit = Debit(
        id: generateTransactionId(),
        user_id: debitData['user_id'],
        date: newDate,
        notes: debitData['notes'],
        isRecurring: debitData['isRecurring'],
        amount: debitData['amount'],
        photos: List<String>.from(debitData['photos'] ?? []),
        localisation: debitData['localisation'],
        categorie_id: debitData['categorie_id'],
      );

      await FirebaseFirestore.instance.collection("debits").doc(newDebit.id).set(newDebit.toMap());
    }

    // Copier les transactions récurrentes de crédit
    final recurringCreditTransactionsSnapshot = await FirebaseFirestore.instance
        .collection('credits')
        .where('user_id', isEqualTo: user.uid)
        .where('isRecurring', isEqualTo: true)
        .get();

    for (var creditDoc in recurringCreditTransactionsSnapshot.docs) {
      final creditData = creditDoc.data();
      DateTime newDate = _calculateNewDate((creditData['date'] as Timestamp).toDate());

      final newCredit = Credit(
        id: generateTransactionId(),
        user_id: creditData['user_id'],
        date: newDate,
        notes: creditData['notes'],
        isRecurring: creditData['isRecurring'],
        amount: creditData['amount'],
      );

      await FirebaseFirestore.instance.collection("credits").doc(newCredit.id).set(newCredit.toMap());
    }

    log("Copie des transactions récurrentes terminée pour le mois en cours.");
  }
}

Future<void> copyRecurringTransactions(
    String previousBudgetId, String newBudgetId) async {
  print('Copie des transactions récurrentes pour le budget : $newBudgetId');

  // Copier les transactions récurrentes pour les débits
  final recurringTransactionsSnapshot = await FirebaseFirestore.instance
      .collection('debits')
      .where('budget_id', isEqualTo: previousBudgetId)
      .where('isRecurring', isEqualTo: true)
      .get();

  print(
      'Transactions récurrentes de type débit : ${recurringTransactionsSnapshot.docs.length}');

  for (var debitDoc in recurringTransactionsSnapshot.docs) {
    final debitData = debitDoc.data();

    // Calcule de la nouvelle date pour le mois suivant
    DateTime newDate = _calculateNewDate((debitData['date'] as Timestamp).toDate());

    // Création d'une nouvelle transaction de type débit pour le nouveau mois
    final newDebit = Debit(
      id: generateTransactionId(),
      user_id: debitData['user_id'],
      date: newDate,
      notes: debitData['notes'],
      isRecurring: debitData['isRecurring'],
      amount: debitData['amount'],
      photos: List<String>.from(debitData['photos'] ?? []),
      localisation: debitData['localisation'],
      categorie_id: debitData['categorie_id'],
    );

    await FirebaseFirestore.instance
        .collection("debits")
        .doc(newDebit.id)
        .set(newDebit.toMap());
    print('Nouvelle transaction de type débit créée : ${newDebit.id}');
  }

  // Copier les transactions récurrentes pour les crédits
  final recurringCreditsSnapshot = await FirebaseFirestore.instance
      .collection("credits")
      .where('budget_id', isEqualTo: previousBudgetId)
      .where("isRecurring", isEqualTo: true)
      .get();

  print(
      'Transactions récurrentes de type crédit : ${recurringCreditsSnapshot.docs.length}');

  for (var creditDoc in recurringCreditsSnapshot.docs) {
    final creditData = creditDoc.data();
    final newDate = _calculateNewDate((creditData['date'] as Timestamp).toDate());

    final newCredit = Credit(
      id: generateTransactionId(),
      user_id: creditData['user_id'],
      date: newDate,
      notes: creditData['notes'],
      isRecurring: creditData['isRecurring'],
      amount: creditData['amount'],
    );

    await FirebaseFirestore.instance
        .collection('credits')
        .doc(newCredit.id)
        .set(newCredit.toMap());
    print('Nouvelle transaction de type crédit créée : ${newCredit.id}');
  }

  print(
      'Copie des transactions récurrentes terminée pour le budget : $newBudgetId');
}

// Ajout d'une transaction de type Débit
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
  //await updateBudetTotals(userId, amount, isDebit: true);
}

// Ajout d'une transaction de type Crédit
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

  await FirebaseFirestore.instance
      .collection('credits')
      .doc(transactionId)
      .set(credit.toMap());
  await updateCurrentMonthBudget(userId, amount, isDebit: false);
}


// Récupérer les transactions par catégorie
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

Future<List<Credit>> getCreditsForCategory(String userId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection("credits")
      .where("user_id", isEqualTo: userId)
      .get();

  return snapshot.docs
      .map((doc) => Credit.fromMap(doc.data() as Map<String, dynamic>))
      .toList();
}
