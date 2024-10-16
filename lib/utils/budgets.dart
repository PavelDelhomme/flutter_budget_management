import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/good_models.dart';

import 'generate_ids.dart';

Future<void> createBudget({
  required String userId,
  required DateTime month,
  required DateTime year,
}) async {
  final budgetId = generateBudgetId();
  final Timestamp monthTimestamp = Timestamp.fromDate(month);
  final Timestamp yearTimestamp = Timestamp.fromDate(year);

  final budget = Budget(
    id: budgetId,
    user_id: userId,
    month: monthTimestamp,
    year: yearTimestamp,
    total_debit: 0.0,
    total_credit: 0.0,
  );

  await FirebaseFirestore.instance
      .collection("budgets")
      .doc(budgetId)
      .set(budget.toMap());
}

Future<void> updateBudgetAfterTransaction(String budgetId, double amount,
    {required bool isDebit}) async {
  final budgetRef =
      FirebaseFirestore.instance.collection('budgets').doc(budgetId);
  final budgetDoc = await budgetRef.get();

  if (budgetDoc.exists) {
    final currentTotalDebit =
        (budgetDoc.data()?['total_debit'] as num).toDouble();
    final currentTotalCredit =
        (budgetDoc.data()?['total_credit'] as num).toDouble();

    if (isDebit) {
      await budgetRef.update({
        'total_debit': currentTotalDebit + amount,
      });
    } else {
      await budgetRef.update({
        'total_credit': currentTotalCredit + amount,
      });
    }
  }
}
