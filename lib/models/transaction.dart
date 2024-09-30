import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  String id;
  String userId;
  double amount;
  String categoryId;
  Timestamp date;
  String description;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'categoryId': categoryId,
      'date': date,
      'description': description,
    };
  }

  static Transaction fromMap(Map<String, dynamic> map, String documentId) {
    return Transaction(
      id: documentId,
      userId: map['userId'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      date: map['date'],
      description: map['description'],
    );
  }
}