import 'package:cloud_firestore/cloud_firestore.dart';
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
  String userId;
  Timestamp month;
  Timestamp year;
  double solde;
  double total_debit;
  double total_credit;

  Budget({
    required this.id,
    required this.userId,
    required this.month,
    required this.year,
    this.solde = 0.0,
    this.total_debit = 0.0,
    this.total_credit = 0.0
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'month': month,
      'year': year,
      'solde': solde,
      'total_debit': total_debit,
      'total_credit': total_credit,
    };
  }

  static Budget fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      userId: map['userId'],
      month: map['month'],
      year: map['year'],
      solde: map['solde'],
      total_debit: map['total_debit'],
      total_credit: map['total_credit'],
    );
  }
}


class Categorie {
  String id;
  String userId;
  String nom;

  Categorie({
    required this.id,
    required this.userId,
    required this.nom,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nom': nom,
    };
  }

  static Categorie fromMap(Map<String, dynamic> map) {
    return Categorie(
      id: map['id'],
      userId: map['userId'],
      nom: map['nom'],
    );
  }
}

class Transaction {
  String id;
  String type;
  String category_id;
  String user_id;
  DateTime date;
  String notes;
  bool isRemaining;

  Transaction({
    required this.id,
    required this.type,
    required this.category_id,
    required this.user_id,
    required this.date,
    required this.notes,
    required this.isRemaining,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'category_id': category_id,
      'user_id': user_id,
      'date': date,
      'notes': notes,
      'isRemaining': isRemaining,
    };
  }

  static Transaction fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: map['type'],
      category_id: map['category_id'],
      user_id: map['user_id'],
      date: map['date'],
      notes: map['notes'],
      isRemaining: map['isRemaining'],
    );
  }
}

class Debit extends Transaction {
  late String transaction_id;
  late double amount;
  List<String>? receiptUrls;
  LatLng? location;

  Debit({
    required super.id,
    required super.type,
    required super.category_id,
    required super.user_id,
    required super.date,
    required super.notes,
    required super.isRemaining,
    required transaction_id,
    required amount,
    receiptUrls,
    location,
  });

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transaction_id,
      'amount': amount,
      'receiptUrls': receiptUrls,
      'location': location,
    };
  }

  static Debit fromMap(Map<String, dynamic> map) {
    return Debit(
      id: map['id'],
      type: map['type'],
      category_id: map['category_id'],
      user_id: map['user_id'],
      date: map['date'],
      notes: map['notes'],
      isRemaining: map['isRemaining'],
      transaction_id: map['transaction_id'],
      amount: map['amount'],
      receiptUrls: map['receiptUrls'],
      location: map['location'],
    );
  }
}