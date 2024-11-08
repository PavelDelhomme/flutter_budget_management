import 'package:flutter/material.dart';

import '../../navigation/custom_drawer.dart';

class BudgetView extends StatefulWidget {
  const BudgetView({super.key});

  @override
  BudgetViewState createState() => BudgetViewState();
}


class BudgetViewState extends State<BudgetView> {

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
      body: null//const TransactionsView()
    );
  }
}