
class IncomeModel {
  String id;
  String userId;
  String source;
  double amount;
  int month;
  int year;
  bool isRecurring;

  IncomeModel({
    required this.id,
    required this.userId,
    required this.source,
    required this.amount,
    required this.month,
    required this.year,
    required this.isRecurring,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'source': source,
      'amount': amount,
      'month': month,
      'year': year,
      'isRecurring': isRecurring,
    };
  }

  static IncomeModel fromMap(Map<String, dynamic> map, String documentId) {
    return IncomeModel(
      id: documentId,
      userId: map['userId'],
      source: map['source'],
      amount: map['amount'],
      month: map['month'],
      year: map['year'],
      isRecurring: map['isReccuring'] ?? false,
    );
  }
}