

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> udpateCategorySpending(String categoryId, double amount) async {
  final categoryRef = await FirebaseFirestore.instance.collection("categories").doc(categoryId).get();

  if (categoryRef.exists) {
    final currentSpent = (categoryRef.data()?['spentAmount'] as num?)?.toDouble() ?? 0.0;
    await FirebaseFirestore.instance.collection("categories").doc(categoryId).update({
      'spentAmount': currentSpent + amount,
    });
  } else {
    throw Exception("Catégorie non trouvée.");
  }
}

Future<void> createCategory(String name, String userId) async {
  await FirebaseFirestore.instance.collection("categories").add({
    'name': name,
    'userId': userId,
    'spentAmount': 0.0,
  });
}