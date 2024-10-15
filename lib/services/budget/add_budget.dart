import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createBudget({
  required double totalAmount,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    await FirebaseFirestore.instance.collection('budgets').add({
      'userId': user.uid,
      'totalAmount': totalAmount,
      'dateCreated': Timestamp.now(),
    });
  }
}


Future<void> createDefaultCategories() async {
  List<String> categories_list = ["Alimentation", "Vie sociale", "Transport", "Culture", "Produits ménagers", "Vêtements", "Beauté", "Santé", "Education", "Cadeau", "Autres"];

}