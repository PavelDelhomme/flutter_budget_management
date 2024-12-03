import 'package:flutter/material.dart';

import 'base/transactions_base_view.dart';

class TransactionsReccuringView extends StatelessWidget {
  const TransactionsReccuringView({super.key});

  @override
  Widget build(BuildContext context) {
    return const TransactionsBaseView(
      showRecurring: true,
    );
  }
}
