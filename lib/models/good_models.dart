import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class UserModel {
  String id;
  String email;
  String name;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['email'],
      name: map['name'],
    );
  }
}


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
}

class Categorie {
  String id;
  String userId;
  String name;

  Categorie({
    required this.id,
    required this.userId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "name": name,
    };
  }

  static Categorie fromMap(Map<String, dynamic> map) {
    return Categorie(
      id: map['id'],
      userId: map['userId'],
      name: map['name']
    );
  }
}


// Classe parent Transaction pour les champs communs
class Transaction {
  String id;
  String user_id;
  DateTime date;
  String notes;
  bool isRecurring;
  double amount;

  Transaction({
    required this.id,
    required this.user_id,
    required this.date,
    required this.notes,
    required this.isRecurring,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'date': date,
      'notes': notes,
      'isRecurring': isRecurring,
      'amount': amount,
    };
  }
}

// Classe Debit héritant de Transaction et ajoutant des champs spécifiques
class Debit extends Transaction {
  List<String>? photos;
  GeoPoint localisation;
  String? categorie_id;

  Debit({
    required String id,
    required String user_id,
    required DateTime date,
    required String notes,
    required bool isRecurring,
    required double amount,
    this.photos,
    required this.localisation,
    this.categorie_id,
  }) : super(
    id: id,
    user_id: user_id,
    date: date,
    notes: notes,
    isRecurring: isRecurring,
    amount: amount,
  );

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'photos': photos ?? [],
      'localisation': localisation,
      'categorie_id': categorie_id,
    });
    return map;
  }

  static Debit fromMap(Map<String, dynamic> map) {
    return Debit(
      id: map['id'],
      user_id: map['user_id'],
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'],
      isRecurring: map['isRecurring'],
      amount: map['amount'],
      photos: List<String>.from(map['photos'] ?? []),
      localisation: map['localisation'],
      categorie_id: map['categorie_id'],
    );
  }
}

// Classe Credit héritant de Transaction, n'ajoutant que le montant spécifique
class Credit extends Transaction {
  Credit({
    required String id,
    required String user_id,
    required DateTime date,
    required String notes,
    required bool isRecurring,
    required double amount,
  }) : super(
    id: id,
    user_id: user_id,
    date: date,
    notes: notes,
    isRecurring: isRecurring,
    amount: amount,
  );

  @override
  Map<String, dynamic> toMap() {
    return super.toMap();
  }

  static Credit fromMap(Map<String, dynamic> map) {
    return Credit(
      id: map['id'],
      user_id: map['user_id'],
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'],
      isRecurring: map['isRecurring'],
      amount: map['amount'],
    );
  }
}

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
*//*
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