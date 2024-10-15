class DeadSavingsModel {
  final String id;
  final String userId;
  final String category;
  final double amount;

  DeadSavingsModel({required this.id, required this.userId, required this.category, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'amount': amount,
    };
  }

  static DeadSavingsModel fromMap(Map<String, dynamic> map, String documentId) {
    return DeadSavingsModel(
      id: documentId,
      userId: map['userId'],
      category: map['category'],
      amount: (map['amount'] as num).toDouble(),
    );
  }
}