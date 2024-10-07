import 'package:budget_management/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/budget.dart';
import '../../models/category.dart';
import '../navigation/custom_drawer.dart';
import '../navigation/tab_navigation.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    checkAndCreateMonthlyBudget();
  }

  Future<void> checkAndCreateMonthlyBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    if (user != null) {
      final budgetSnapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .where("userId", isEqualTo: user.uid)
          .where("month", isEqualTo: currentMonth)
          .where("year", isEqualTo: currentYear)
          .get();

      if (budgetSnapshot.docs.isEmpty) {
        final lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;
        final lastYear = currentMonth == 1 ? currentYear - 1 : currentYear;

        final previousBudgetSnapshot = await FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user.uid)
            .where('month', isEqualTo: lastMonth)
            .where('year', isEqualTo: lastYear)
            .get();

        BudgetModel newBudget;

        if (previousBudgetSnapshot.docs.isNotEmpty) {
          final previousBudget = previousBudgetSnapshot.docs.first;

          newBudget = BudgetModel(
            id: generateBudgetId(),
            userId: user.uid,
            description: 'Budget du mois de ${DateFormat.MMMM('fr_FR').format(now)} $currentYear',
            totalAmount: previousBudget['totalAmount'],
            savings: previousBudget['savings'],
            month: currentMonth,
            year: currentYear,
            startDate: Timestamp.fromDate(DateTime(currentYear, currentMonth, 1)),
            endDate: Timestamp.fromDate(DateTime(currentYear, currentMonth + 1, 0)),
            categories: (previousBudget['categories'] as List)
                .map((category) => CategoryModel.fromMap(category))
                .toList(),
          );

          await copyRecurringTransactions(previousBudget.id, newBudget.id);
        } else {
          newBudget = BudgetModel(
            id: generateBudgetId(),
            userId: user.uid,
            description: 'Budget du mois de ${DateFormat.MMMM('fr_FR').format(now)} $currentYear',
            totalAmount: 0.0,
            savings: 0.0,
            month: currentMonth,
            year: currentYear,
            startDate: Timestamp.fromDate(DateTime(currentYear, currentMonth, 1)),
            endDate: Timestamp.fromDate(DateTime(currentYear, currentMonth + 1, 0)),
            categories: [],
          );
        }

        await FirebaseFirestore.instance.collection('budgets').doc(newBudget.id).set(newBudget.toMap());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget du mois de ${DateFormat.MMMM('fr_FR').format(DateTime.now())} ${DateTime.now().year}'),
      ),
      drawer: const CustomDrawer(),
      body: const TabNavigation(budgetId: null),
    );
  }
}
