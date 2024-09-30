
import 'package:cloud_firestore/cloud_firestore.dart';

import 'category.dart';

class BudgetModel {
  String id;
  String userId;
  String description;
  double totalAmount;
  Timestamp startDate;
  Timestamp endDate;
  List<CategoryModel> categories;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.totalAmount,
    required this.startDate,
    required this.endDate,
    required this.categories,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'totalAmount': totalAmount,
      'startDate': startDate,
      'endDate': endDate,
      'categories': categories.map((c) => c.toMap()).toList(),
    };
  }

  static BudgetModel fromMap(Map<String, dynamic> map, String documentId) {
    return BudgetModel(
      id: documentId,
      userId: map['userId'],
      description: map['description'],
      totalAmount: map['totalAmount'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      categories: (map['categories'] as List)
          .map((categoryMap) => CategoryModel.fromMap(categoryMap))
          .toList(),
    );
  }
}