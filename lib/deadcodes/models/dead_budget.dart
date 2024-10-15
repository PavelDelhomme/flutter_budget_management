import 'package:cloud_firestore/cloud_firestore.dart';

import 'dead_category.dart';

class DeadBudgetModel {
  String id;
  String userId;
  String description;
  double totalAmount;
  double savings; // Ajout de l'épargne
  int month; // Mois de ce budget
  int year; // Année de ce budget
  Timestamp startDate;
  Timestamp endDate;
  List<DeadCategoryModel> categories;

  DeadBudgetModel({
    required this.id,
    required this.userId,
    required this.description,
    required this.totalAmount,
    required this.savings,  // Ajout de l'épargne
    required this.month,  // Mois du budget
    required this.year,   // Année du budget
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
      'savings': savings,  // Ajout de l'épargne
      'month': month,  // Mois du budget
      'year': year,  // Année du budget
      'startDate': startDate,
      'endDate': endDate,
      'categories': categories.map((c) => c.toMap()).toList(),
    };
  }

  static DeadBudgetModel fromMap(Map<String, dynamic> map, String documentId) {
    return DeadBudgetModel(
      id: documentId,
      userId: map['userId'],
      description: map['description'],
      totalAmount: map['totalAmount'],
      savings: map['savings'] ?? 0.0,  // Ajout de l'épargne
      month: map['month'] ?? DateTime.now().month,  // Mois du budget
      year: map['year'] ?? DateTime.now().year,  // Année du budget
      startDate: map['startDate'],
      endDate: map['endDate'],
      categories: (map['categories'] as List)
          .map((categoryMap) => DeadCategoryModel.fromMap(categoryMap))
          .toList(),
    );
  }
}
