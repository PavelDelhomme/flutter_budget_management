import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income.dart';
import '../utils.dart';

Future<List<IncomeModel>> getUserIncomes(String userId, int month, int year) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('incomes')
      .where('month', isEqualTo: month)
      .where('year', isEqualTo: year)
      .get();

  return snapshot.docs.map((doc) => IncomeModel.fromMap(doc.data(), doc.id)).toList();
}

Future<void> addIncome({
  required String userId,
  required String source,
  required double amount,
  required int month,
  required int year,
  required bool isRecurring,
}) async {
  final income = IncomeModel(
    userId: userId,
    source: source,
    amount: amount,
    month: month,
    year: year,
    isRecurring: isRecurring,
  );

  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('incomes')
      .add(income.toMap());
}

Future<void> updateIncome({
  required String incomeId,
  required String userId,
  required String source,
  required double amount,
  required int month,
  required int year,
  required bool isRecurring,
}) async {
  final income = IncomeModel(
    id: incomeId,
    userId: userId,
    source: source,
    amount: amount,
    month: month,
    year: year,
    isRecurring: isRecurring,
  );

  await FirebaseFirestore.instance.collection('incomes').doc(incomeId).update(income.toMap());
}

Future<void> deleteIncome(String userId, String incomeId) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('incomes')
      .doc(incomeId)
      .delete();
}
