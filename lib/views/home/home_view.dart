import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../budget/budget/add_budget_screen.dart';
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

  Future<void> _recalculateBudgetExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final budgetSnapshot = await FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var budgetDoc in budgetSnapshot.docs) {
        final budgetId = budgetDoc.id;
        final List<dynamic> categories = budgetDoc.data()['categories'] ?? [];

        final transactionSnapshot = await FirebaseFirestore.instance
            .collection("transactions")
            .where('budgetId', isEqualTo: budgetId)
            .get();

        // Initialiser les nouvelles sommes dépensée pour chaque catégorie
        final updatedCategories = categories.map((category) {
          final categoryName = category['name'];
          double spentAmount = 0.0;

          for (var transaction in transactionSnapshot.docs) {
            if (transaction['category'] == categoryName) {
              spentAmount += (transaction['amount'] as num).toDouble();
            }
          }

          return {
            'name': categoryName,
            'spentAmount': spentAmount,
          };
        }).toList();

        // Mise a jour du budget avec les nouvelles dépenses
        await FirebaseFirestore.instance.collection('budgets').doc(budgetId).update({
          'categories': updatedCategories,
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingBudget();
    _recalculateBudgetExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      drawer: CustomDrawer(),
      body: TabNavigation(budgetId: null),
    );
  }
}
