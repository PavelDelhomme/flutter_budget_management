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

  double calculateDebit(List<UserTransaction> transactions) {
    //todo récupérer toutes les transactions de type débit correspondant au mois actuel
    return 0.0;
  }

  double calculateCredit(List<UserTransaction> transactions) {
    //todo récupérer toutes les transactions de type crédit correspondant au mois actuel
    return 0.0;
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

class UserTransaction {
  String id;
  bool type; // True : Débit | False : Crédit
  String? categorie_id;
  String user_id;
  DateTime date;
  String notes;
  bool isRecurring;

  UserTransaction({
    required this.id,
    required this.type,
    this.categorie_id,
    required this.user_id,
    required this.date,
    required this.notes,
    required this.isRecurring,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "type": type,
      "categorie_id": categorie_id,
      "user_id": user_id,
      "date": date,
      "notes": notes,
      "isRecurring": isRecurring,
    };
  }

  static UserTransaction fromMap(Map<String, dynamic> map) {
    return UserTransaction(
      id: map['id'],
      type: map['type'],
      categorie_id: map['categorie_id'],
      user_id: map['user_id'],
      date: map['date'],
      notes: map['notes'],
      isRecurring: map['isRecurring'],
    );
  }
}

class Debit {
  String id;
  double amount;
  List<String>? photos;
  LatLng localisation;
  String transaction_id;

  Debit({
    required this.id,
    required this.amount,
    required this.localisation,
    required this.transaction_id,
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
