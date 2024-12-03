
class Budget {
  String id;
  String user_id;
  int month;
  int year;
  double total_debit;
  double total_credit;
  double remaining = 0.0;
  double cumulativeRemaining = 0.0;

  Budget({
    required this.id,
    required this.user_id,
    required this.month,
    required this.year,
    this.total_debit = 0.0,
    this.total_credit = 0.0,
    this.remaining = 0.0,
    this.cumulativeRemaining = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'month': month,
      'year': year,
      'total_debit': total_debit,
      'total_credit': total_credit,
      'remaining': remaining,
      'cumulativeRemaining': cumulativeRemaining,
    };
  }

  static Budget fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      user_id: map['user_id'],
      month: map['month'],
      year: map['year'],
      total_debit: (map['total_debit'] as num?)?.toDouble() ?? 0.0,
      total_credit: (map['total_debit'] as num?)?.toDouble() ?? 0.0,
      remaining: (map['remaining'] as num?)?.toDouble() ?? 0.0,
      cumulativeRemaining: (map['cumulativeRemaining'] as num?)?.toDouble() ?? 0.0,
    );
  }
}