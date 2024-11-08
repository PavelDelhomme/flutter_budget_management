import 'package:flutter/material.dart';
import 'base/transactions_base_view.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({Key? key}) : super(key: key);

  @override build(BuildContext context) {
    return TransactionsBaseView(
      showRecurring: false,
    );
  }
}
