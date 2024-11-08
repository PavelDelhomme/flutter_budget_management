import 'package:flutter/material.dart';

import 'base/transactions_base_view.dart';

class TransactionsReccuringView extends StatelessWidget {
  const TransactionsReccuringView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TransactionsBaseView(
      showRecurring: true,
    );
  }
}
