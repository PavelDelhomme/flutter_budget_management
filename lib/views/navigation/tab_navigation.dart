import 'package:budget_management/views/navigation/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../budget/summary_view.dart';
import '../budget/transaction/transaction_view.dart';

class TabNavigation extends StatefulWidget {
  final String? budgetId;

  const TabNavigation({super.key, this.budgetId});

  @override
  _TabNavigationState createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> {
  int _currentIndex = 0;  // Gère l'index de l'onglet actif

  // Listes des vues pour chaque onglet
  final List<Widget> _pages = [
    const SummaryView(),  // Vue Résumé
    TransactionsView(budgetId: null),  // Vue Transactions
  ];

  // Listes des titres des pages (correspond à chaque vue)
  final List<String> _titles = [
    'Résumé',
    'Transactions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${DateFormat.MMMM('fr_FR').format(DateTime.now())} ${DateTime.now().year}'),
      ),
      drawer: CustomDrawer(),
      body: _pages[_currentIndex],  // Affiche la page active
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,  // Index de l'onglet actif
        onTap: (int index) {
          setState(() {
            _currentIndex = index;  // Met à jour l'onglet actif
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Résumé',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
            //todo : déplier liste transaction du mois courrant par défaut.
          ),
        ],
      ),
    );
  }
}
