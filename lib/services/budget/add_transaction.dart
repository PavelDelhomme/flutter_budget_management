import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addTransaction({
  required String description,
  required double amount,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    await FirebaseFirestore.instance.collection('transactions').add({
      'userId': user.uid,
      'description': description,
      'amount': amount,
      'date': Timestamp.now(),
    });
  }
}
