import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  String id;
  String userId;
  String description;
  double totalAmount;
  String categoryId;
  Timestamp startDate;
  Timestamp endDate;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.totalAmount,
    required this.categoryId,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'totalAmount': totalAmount,
      'categoryId': categoryId,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  static BudgetModel fromMap(Map<String, dynamic> map, String documentId) {
    return BudgetModel(
      id: documentId,
      userId: map['userId'],
      description: map['description'],
      totalAmount: map['totalAmount'],
      categoryId: map['categoryId'],
      startDate: map['startDate'],
      endDate: map['endDate'],
    );
  }
}
