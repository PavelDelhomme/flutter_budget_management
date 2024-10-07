import 'package:budget_management/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../budget/add_budget_screen.dart';
import '../navigation/custom_drawer.dart';
import '../navigation/tab_navigation.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Future<void> _checkExistingBudget() async {
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
        // Si aucun budget n'existe, rediriger vers la création de budget
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingBudget();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      drawer: CustomDrawer(),
      body: TabNavigation(budgetId: null),
    );
  }
}
