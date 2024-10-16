import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../budget/summary_view.dart';
import '../budget/transaction/transaction_view.dart';
import 'custom_drawer.dart';

class TabNavigation extends StatefulWidget {
  const TabNavigation({super.key});

  @override
  _TabNavigationState createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> {
  int _currentIndex = 0;  // Gère l'index de l'onglet actif

  final List<Widget> _pages = [
    const SummaryView(),  // Vue Résumé
    const TransactionsView(),  // Vue Transactions
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${DateFormat.MMMM('fr_FR').format(DateTime.now())} ${DateTime.now().year}'),
      ),
      drawer: const CustomDrawer(activeItem: 'home'),  // Toujours "home" lorsque tu es dans TabNavigation
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
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
          ),
        ],
      ),
    );
  }
}
