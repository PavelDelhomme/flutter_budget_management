import 'package:budget_management/views/navigation/custom_drawer.dart';
import 'package:flutter/material.dart';
import '../budget/summary_view.dart';
import '../budget/transaction/transaction_view.dart';

class TabNavigation extends StatefulWidget {
  final String? budgetId;

  const TabNavigation({super.key, this.budgetId});

  @override
  _TabNavigationState createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Transactions'),
          ],
        ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const SummaryView(),  // Vue Résumé
          TransactionsView(budgetId: widget.budgetId),  // Vue Transactions global ou par budget)
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
