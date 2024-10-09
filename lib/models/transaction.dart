import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class TransactionModel {
  String id;
  String userId;
  double amount;
  String categoryId;
  Timestamp date;
  String description;
  bool isRecurring;
  List<String>? receiptUrls;
  LatLng? location;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.description,
    this.isRecurring = false,
    this.receiptUrls,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'categoryId': categoryId,
      'date': date,
      'description': description,
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
      amount: map['amount'],
      categoryId: map['categoryId'],
      date: map['date'],
      description: map['description'],
      isRecurring: map['isRecurring'] ?? false,
      receiptUrls: List<String>.from(map['receiptsUrls'] ?? []),
      location: map['location'] != null
          ? LatLng((map['location'] as GeoPoint).latitude,
              (map['location'] as GeoPoint).longitude)
          : null,
    );
  }
}
