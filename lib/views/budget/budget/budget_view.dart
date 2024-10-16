import 'package:budget_management/views/budget/transaction/transaction_view.dart';
import 'package:flutter/material.dart';

import '../../navigation/custom_drawer.dart';

class BudgetView extends StatefulWidget {
  const BudgetView({Key? key}) : super(key: key);

  @override
  _BudgetViewState createState() => _BudgetViewState();
}


class _BudgetViewState extends State<BudgetView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const CustomDrawer(activeItem: 'budgets'),
        appBar: AppBar(
        title: const Text("Transactions"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // todo logique pour ajouter une nouvelle transaction
            },
          ),
        ],
      ),
      body: const TransactionsView()
    );
  }
}