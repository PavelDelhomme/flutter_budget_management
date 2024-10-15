import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> dead_createBudget({
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
