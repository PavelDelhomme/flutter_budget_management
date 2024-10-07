import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../navigation/custom_drawer.dart';
import '../navigation/tab_navigation.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget du mois de ${DateFormat.MMMM('fr_FR').format(DateTime.now())} ${DateTime.now().year}'),
      ),
      drawer: const CustomDrawer(),
      body: const TabNavigation(budgetId: null),  // Transactions globales
    );
  }
}
