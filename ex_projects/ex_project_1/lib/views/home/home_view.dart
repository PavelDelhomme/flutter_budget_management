import 'package:flutter/material.dart';
import '../../services/transactions.dart';
import '../navigation/custom_drawer.dart';
import '../navigation/tab_navigation.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _initializeRecurringTransactions();
  }

  void _initializeRecurringTransactions () {
    _transactionService.copyRecurringTransactionsForNewMonth();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      drawer: CustomDrawer(activeItem: 'home'),
      body: TabNavigation(),
    );
  }
}
