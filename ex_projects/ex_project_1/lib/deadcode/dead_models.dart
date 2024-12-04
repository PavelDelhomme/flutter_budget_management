
/*
class Budget {
  String id;
  String user_id;
  Timestamp month;
  Timestamp year;
  double total_debit;
  double total_credit;

  Budget({
    required this.id,
    required this.user_id,
    required this.month,
    required this.year,
    this.total_debit = 0,
    this.total_credit = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'month': month,
      'year': year,
      'total_debit': total_debit,
      'total_credit': total_credit,
    };
  }

  static Budget fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      user_id: map['user_id'],
      month: map['month'],
      year: map['year'],
      total_debit: map['total_debit'],
      total_credit: map['total_credit'],
    );
  }

  /// Méthode pour calculer les débits à partir de la liste des transactions
  double calculateDebit(List<Transaction> transactions) {
    double totalDebit = 0;
    for (var transaction in transactions) {
      if (transaction is Debit) {
        totalDebit += transaction.amount;
      }
    }
    return totalDebit;
  }

  /// Méthode pour calculer les crédits à partir de la liste des transactions
  double calculateCredit(List<Transaction> transactions) {
    double totalCredit = 0;
    for (var transaction in transactions) {
      if (transaction is Credit) {
        totalCredit += transaction.amount;
      }
    }
    return totalCredit;
  }
}*/

/*
class Debit {
  String id;
  double amount;
  List<String>? photos;
  LatLng localisation;
  String transaction_id;
  String user_id;

  Debit({
    required this.id,
    required this.amount,
    required this.localisation,
    required this.transaction_id,
    required this.user_id,
    this.photos,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "amount": amount,
      "photos": photos ?? [],
      "localisation": localisation,
      "transactionId": transaction_id,
    };
  }

  static Debit fromMap(Map<String, dynamic> map) {
    return Debit(
      id: map['id'],
      amount: map['amount'],
      localisation: map['localisation'],
      transaction_id: map['transaction_id'],
      photos: List<String>.from(map['photos'] ?? []),
      user_id: map['user_id'],
    );
  }
}

class Credit {
  String id;
  String transaction_id;
  double amount;

  Credit({
    required this.id,
    required this.transaction_id,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "transaction_id": transaction_id,
      "amount": amount,
    };
  }

  static Credit fromMap(Map<String, dynamic> map) {
    return Credit(
      id: map['id'],
      transaction_id: map['transaction_id'],
      amount: map['amount'],
    );
  }
}
*/