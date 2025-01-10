import 'package:flutter/material.dart';

import 'package:money_mate/views/budget/transaction/base/transaction_base_view.dart';

class TransactionsReccuringView extends StatelessWidget {
  const TransactionsReccuringView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TransactionsBaseView(
      showRecurring: true,
    );
  }
}
