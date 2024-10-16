import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

import '../../models/good_models.dart';
import '../../utils/categories.dart';
import '../../utils/generate_ids.dart';


// Ajouter une transaction, soit débit soit crédit donc tout les champs ne sont pas nécessaire
Future<void> addTransaction({
  required bool type, // Le type de la transaction (Débit ou crédit)
  required UserTransaction userTransaction,
  double? amount,
  LatLng? localisation,
  List<String>? photos,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception("Utilisateur non connecté");
  }

  try {
    // Ajout de la transaction de base (UserTransaction)
    await FirebaseFirestore.instance.collection('transactions').add(userTransaction.toMap());

    // Vérification du type de la transaction a ajouté
    if (type) {
      // C'est un débit
      if (amount == null && localisation == null) {
        throw Exception("Le montant et la localisation sont requis pour un débit");
      }
      Debit debit = Debit(
        id: generateTransactionId(),
        transaction_id: userTransaction.id,
        amount: amount!,
        localisation: localisation!,
        photos: photos,
      );

      await FirebaseFirestore.instance.collection("debits").add(debit.toMap());
      // Mettre à jour la catégorie avec le montant dépensé
      await udpateCategorySpending(userTransaction.categorie_id, amount);
    } else {
      // C'est un crédit
      if (amount == null) {
        throw Exception("Le montant est requis pour un crédit");
      }
      Credit credit = Credit(
        id: generateTransactionId(),
        transaction_id: userTransaction.id,
        amount: amount,
      );
      await FirebaseFirestore.instance.collection("credits").add(credit.toMap());
    }
  } catch (e) {
    log("Une erreur est survenu lors de la tentative d'ajout d'une transaction");
    throw Exception("Erreur lors de l'ajout de la transaction: $e");
  }
}

/*
Future<void> bad_addTransaction({
  required bool type,
  required double amount,
  required String categoryId,
  required DateTime date,
  String? notes,
  required bool isRecurring,
  List<String>? receiptUrls,
  GeoPoint? location,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      // Création d'un identifiant unique de transaction
      String transactionId = generateTransactionId();

      // Ajout de la transaction directement dans la collection 'transactions'
      await FirebaseFirestore.instance.collection('transactions').add({
        'id': transactionId,
        'userId': user.uid,
        'type_transaction':
      })
    }
    final budgetRef = FirebaseFirestore.instance.collection('budgets').doc(budgetId);
    final budgetDoc = await budgetRef.get();

    if (budgetDoc.exists) {
      // Récupération des catégories du budget
      final List<dynamic> categories = budgetDoc.data()?['categories'] ?? [];
      final categoryIndex = categories.indexWhere((category) => category['name'] == categoryId);

      if (categoryIndex != -1) {
        final category = categories[categoryIndex];
        final double spentAmount = (category['spentAmount'] as num?)?.toDouble() ?? 0.0;

        // Calcul du nouveau montant dépensé
        double newSpentAmount = spentAmount + amount;

        // Mise à jour du montant dépensé dans la catégorie
        categories[categoryIndex]['spentAmount'] = newSpentAmount;

        // Mise à jour du document du budget
        await budgetRef.update({'categories': categories});

        // Créer l'id de transaction
        String transactionId = generateTransactionId();

        // Ajouter la transaction
        await FirebaseFirestore.instance.collection('transactions').add({
          'id': transactionId,
          'userId': user.uid,
          'type_transaction': type_transaction,
          'amount': amount,
          'categoryId': categoryId,
          'date': date ?? Timestamp.now(),
          'isRecurring': isRecurring,
          'receiptUrls': receiptUrls,
          'location': location,
          'budgetId': budgetId,
        });
      }
    }
  }
}
*/
/*
Future<double> deductFromSavings(String userId, String savingId, double amountToDeduct) async {
  final savingRef = FirebaseFirestore.instance
      .collection("users")
      .doc(userId)
      .collection("savings")
      .doc(savingId);

  final savingDoc = await savingRef.get();

  if (savingDoc.exists) {
    final currentAmount = (savingDoc.data()?['amount'] as num?)?.toDouble() ?? 0.0;
    if (currentAmount >= amountToDeduct) {
      // Déduire directement le montant de l'économie
      await savingRef.update({'amount': currentAmount - amountToDeduct});
      return amountToDeduct;  // Tout a été déduit de cette économie
    } else {
      throw Exception("Pas assez de fonds dans cette catégorie d'économies.");
    }
  } else {
    throw Exception("Catégorie d'économies non trouvée.");
  }
}
*/

Future<void> _updateMonthlyBudget(double amount, String budgetId) async {
  final budgetRef = FirebaseFirestore.instance.collection('budgets').doc(budgetId);
  final budgetDoc = await budgetRef.get();

  if (budgetDoc.exists) {
    final currentAmount = (budgetDoc.data()?['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final newAmount = currentAmount + amount;

    await budgetRef.update({'totalAmount': newAmount});
  }
}
