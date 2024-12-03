import 'package:cloud_firestore/cloud_firestore.dart';

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
    required DateTime date,
    required this.notes,
    required this.isRecurring,
    required this.amount,
  }) : date = DateTime(date.year, date.month, date.day);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user_id,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
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
    required super.id,
    required super.user_id,
    required super.date,
    required super.notes,
    required super.isRecurring,
    required super.amount,
    this.photos,
    required this.localisation,
    this.categorie_id,
  });

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
    if (map['user_id'] == null) {
      throw Exception('user_id est manquant dans les données : $map');
    }
    if (map['localisation'] == null) {
      throw Exception('localisation est manquante dans les données : $map');
    }

    return Debit(
      id: map['id'] ?? '',
      user_id: map['user_id'] ?? '',
      date: (map['date'] as Timestamp).toDate().toLocal().subtract(
          Duration(hours: map['date'].toDate().hour, minutes: map['date'].toDate().minute)),
      notes: map['notes'] ?? '',
      isRecurring: map['isRecurring'] ?? false,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      photos: List<String>.from(map['photos'] ?? []),
      localisation: map['localisation'] ?? const GeoPoint(0, 0),
      categorie_id: map['categorie_id'],
    );
  }
}

// Classe Credit héritant de Transaction, n'ajoutant que le montant spécifique
class Credit extends Transaction {
  Credit({
    required super.id,
    required super.user_id,
    required super.date,
    required super.notes,
    required super.isRecurring,
    required super.amount,
  });

  static Credit fromMap(Map<String, dynamic> map) {
    return Credit(
      id: map['id'],
      user_id: map['user_id'],
      date: (map['date'] as Timestamp).toDate().toLocal().subtract(
          Duration(hours: map['date'].toDate().hour, minutes: map['date'].toDate().minute)), // Supprime l'heure
      notes: map['notes'],
      isRecurring: map['isRecurring'],
      amount: map['amount'],
    );
  }
}
