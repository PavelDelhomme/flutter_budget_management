class SavingsModel {
  final String id;
  final String userId;
  final String category;
  final double amount;

  SavingsModel({required this.id, required this.userId, required this.category, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'amount': amount,
    };
  }

  static SavingsModel fromMap(Map<String, dynamic> map, String documentId) {
    return SavingsModel(
      id: documentId,
      userId: map['userId'],
      category: map['category'],
      amount: (map['amount'] as num).toDouble(),
    );
  }
}