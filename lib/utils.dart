import 'dart:math';

String generateTransactionId() {
  final random = Random();
  return 'transac_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}


String generateBudgetId() {
  final random = Random();
  return 'budget_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

String generateIncomeId() {
  final random = Random();
  return 'income_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}

String generateSavingId() {
  final random = Random();
  return 'saving_${random.nextInt(1000000)}_${DateTime.now().millisecondsSinceEpoch}';
}