import 'package:budget_management/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addTransaction({
  //required userId,
  required bool type_transaction,
  required double amount,
  required String categoryId,
  required DateTime date,
  String? notes,
  required bool isRecurring,
  List<String>? receiptUrls,
  GeoPoint? location,
  required String budgetId,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
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

Future<void> _updateMonthlyBudget(double amount, String budgetId) async {
  final budgetRef = FirebaseFirestore.instance.collection('budgets').doc(budgetId);
  final budgetDoc = await budgetRef.get();

  if (budgetDoc.exists) {
    final currentAmount = (budgetDoc.data()?['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final newAmount = currentAmount + amount;

    await budgetRef.update({'totalAmount': newAmount});
  }
}
