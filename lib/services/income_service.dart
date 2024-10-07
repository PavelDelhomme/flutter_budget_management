import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income.dart';
import '../utils.dart';

Future<void> addIncome({
  required String userId,
  required String source,
  required double amount,
  required int month,
  required int year,
  required bool isRecurring,
}) async {
  final income = IncomeModel(
    id: generateIncomeId(),
    userId: userId,
    source: source,
    amount: amount,
    month: month,
    year: year,
    isRecurring: isRecurring,
  );

  await FirebaseFirestore.instance
    .collection('incomes')
    .doc(income.id)
    .set(income.toMap());
}

Future<List<IncomeModel>> getUserIncomes(String userId, int month, int year) async {
  final incomeSnapshot = await FirebaseFirestore.instance
      .collection('incomes')
      .where("userId", isEqualTo: userId)
      .where("month", isEqualTo: month)
      .where("year", isEqualTo: year)
      .get();

  return incomeSnapshot.docs.map((doc) {
    return IncomeModel.fromMap(doc.data(), doc.id);
  }).toList();
}