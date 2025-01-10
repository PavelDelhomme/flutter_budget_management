import 'package:flutter/material.dart';
import 'base/transactions_base_view.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});

  @override build(BuildContext context) {
    return const TransactionsBaseView(
      showRecurring: false,
    );
  }
}
