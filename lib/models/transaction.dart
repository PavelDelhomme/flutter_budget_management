import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String id;
  String userId;
  double amount;
  String categoryId;
  Timestamp date;
  String description;
  bool isRecurring;
  String? receiptUrl;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.description,
    this.isRecurring = false,
    this.receiptUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'categoryId': categoryId,
      'date': date,
      'description': description,
      'isRecurring': isRecurring,
      'receiptUrl': receiptUrl,
    };
  }

  static TransactionModel fromMap(Map<String, dynamic> map, String documentId) {
    return TransactionModel(
      id: documentId,
      userId: map['userId'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      date: map['date'],
      description: map['description'],
      isRecurring: map['isRecurring'] ?? false,
      receiptUrl: map['receiptUrl'],
    );
  }
}
