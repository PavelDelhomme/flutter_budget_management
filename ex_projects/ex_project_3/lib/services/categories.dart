
import 'package:budget_management/services/transactions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {

  final FirebaseFirestore _database = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();

  Future<void> createCategory(String name, String userId, String type) async {
    await _database.collection("categories").add({
      'name': name,
      'userId': userId,
      'type': type, // Ajouter le type (debit ou credit)
      'spentAmount': 0.0,
    });
  }


  Future<void> udpateCategorySpending(String categoryId, double amount) async {
    final categoryRef = await _database
        .collection("categories")
        .doc(categoryId)
        .get();

    if (categoryRef.exists) {
      final currentSpent =
          (categoryRef.data()?['spentAmount'] as num?)?.toDouble() ?? 0.0;
      await _database
          .collection("categories")
          .doc(categoryId)
          .update({
        'spentAmount': currentSpent + amount,
      });
    } else {
      throw Exception("Catégorie non trouvée.");
    }
  }

}