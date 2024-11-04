import 'package:budget_management/utils/transactions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/budgets.dart';
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
    copyRecurringTransactionsForNewMonth();
    //_checkAndAddDefaultCategories();
  }

  Future<void> _checkAndAddDefaultCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final categoriesSnapshot = await FirebaseFirestore.instance
            .collection("categories")
            .where("userId", isEqualTo: user.uid)
            .get();

      if (categoriesSnapshot.docs.isEmpty) {
        await _addDefaultCategories(user.uid);
      }
    }
  }

  Future<void> _addDefaultCategories(String userId) async {
    await createDefaultCategories(userId);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      drawer: const CustomDrawer(activeItem: 'home'),
      body: TabNavigation(),
    );
  }
}
