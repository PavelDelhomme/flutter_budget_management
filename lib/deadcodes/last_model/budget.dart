import 'package:cloud_firestore/cloud_firestore.dart';
import 'category.dart';

class BudgetModel {
  String id;
  String userId;
  int month; // Mois de ce budget
  int year; // Année de ce budget
  Timestamp startDate;
  Timestamp endDate;
  List<CategoryModel> categories;

  BudgetModel({
    required this.id,
    required this.userId,
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
      'month': month,  // Mois du budget
      'year': year,  // Année du budget
      'startDate': startDate,
      'endDate': endDate,
      'categories': categories.map((c) => c.toMap()).toList(),
    };
  }

  static BudgetModel fromMap(Map<String, dynamic> map, String documentId) {
    return BudgetModel(
      id: documentId,
      userId: map['userId'],
      month: map['month'] ?? DateTime.now().month,  // Mois du budget
      year: map['year'] ?? DateTime.now().year,  // Année du budget
      startDate: map['startDate'],
      endDate: map['endDate'],
      categories: (map['categories'] as List)
          .map((categoryMap) => CategoryModel.fromMap(categoryMap))
          .toList(),
    );
  }
}
