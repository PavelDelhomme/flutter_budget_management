import 'package:budget_management/views/map_exemple/map.dart';
import 'package:flutter/material.dart';

import '../navigation/custom_drawer.dart';
import '../navigation/tab_navigation.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    /*return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: const CustomDrawer(),
      body: const TabNavigation(),
    );*/
    return const MapPage();
  }
}
