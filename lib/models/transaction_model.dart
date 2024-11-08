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
  //String? budget_id;

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
    //this.budget_id,
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
      //'budget_id': budget_id,
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
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'] ?? '',
      isRecurring: map['isRecurring'] ?? false,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      photos: List<String>.from(map['photos'] ?? []),
      localisation: map['localisation'] ?? const GeoPoint(0, 0), // Valeur par défaut
      categorie_id: map['categorie_id'],
      //budget_id: map['budget_id'] ?? '', // Valeur par défaut
    );
  }
}

// Classe Credit héritant de Transaction, n'ajoutant que le montant spécifique
class Credit extends Transaction {
  //String? budget_id;

  Credit({
    required String id,
    required String user_id,
    required DateTime date,
    required String notes,
    required bool isRecurring,
    required double amount,
    //this.budget_id,
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
      //'budget_id': budget_id,
    });
    return map;
  }

  static Credit fromMap(Map<String, dynamic> map) {
    return Credit(
      id: map['id'],
      user_id: map['user_id'],
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'],
      isRecurring: map['isRecurring'],
      amount: map['amount'],
      //budget_id: map['budget_id'],
    );
  }
}