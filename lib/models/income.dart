class IncomeModel {
  String? id;
  String userId;
  String source;
  double amount;
  int month;
  int year;
  bool isRecurring;

  IncomeModel({
    this.id,
    required this.userId,
    required this.source,
    required this.amount,
    required this.month,
    required this.year,
    required this.isRecurring,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'source': source,
      'amount': amount,
      'month': month,
      'year': year,
      'isRecurring': isRecurring,
    };
  }

  // Cette méthode accepte maintenant l'id du document en plus des données.
  static IncomeModel fromMap(Map<String, dynamic> map, String documentId) {
    return IncomeModel(
      id: documentId, // Assigne l'ID du document Firebase
      userId: map['userId'],
      source: map['source'],
      amount: (map['amount'] as num).toDouble(), // Convertir en double au cas où
      month: map['month'],
      year: map['year'],
      isRecurring: map['isRecurring'] ?? false, // Corrigez l'orthographe ici
    );
  }
}
