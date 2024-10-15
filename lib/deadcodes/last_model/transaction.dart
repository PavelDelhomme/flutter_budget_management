import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class TransactionModel {
  String id;
  String userId;
  bool type_transaction; // true = débit, false = crédit
  double amount;
  String categoryId;
  Timestamp date;
  String notes;
  bool isRecurring;
  List<String>? receiptUrls;
  LatLng? location;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type_transaction,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.notes,
    this.isRecurring = false,
    this.receiptUrls,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type_transaction': type_transaction,
      'amount': amount,
      'categoryId': categoryId,
      'date': date,
      'notes': notes,
      'isRecurring': isRecurring,
      'receiptUrls': receiptUrls,
      'location': location != null
          ? GeoPoint(location!.latitude, location!.longitude)
          : null,
    };
  }

  static TransactionModel fromMap(Map<String, dynamic> map, String documentId) {
    return TransactionModel(
      id: documentId,
      userId: map['userId'],
      type_transaction: map['type_transaction'] ?? false,
      amount: map['amount'],
      categoryId: map['categoryId'],
      date: map['date'],
      notes: map['notes'],
      isRecurring: map['isRecurring'] ?? false,
      receiptUrls: List<String>.from(map['receiptsUrls'] ?? []),
      location: map['location'] != null
          ? LatLng((map['location'] as GeoPoint).latitude,
              (map['location'] as GeoPoint).longitude)
          : null,
    );
  }
}
