import 'package:budget_management/models/ancien_models.dart';
import 'package:budget_management/utils/generate_ids.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    _checkAndAddDefaultCategories();
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
    List<Categorie> defaultCategories = [
      Categorie(id: generateCategoryId(), userId: userId, nom: 'Alimentation'),
      Categorie(id: generateCategoryId(), userId: userId, nom: 'Vie sociale'),
      Categorie(id: generateCategoryId(), userId: userId, nom: 'Transport'),
      Categorie(id: generateCategoryId(), userId: userId, nom: 'Santé'),
      Categorie(id: generateCategoryId(), userId: userId, nom: 'Education'),
      Categorie(id: generateCategoryId(), userId: userId, nom: 'Cadeaux'),
    ];

    for (var category in defaultCategories) {
      await FirebaseFirestore.instance.collection("categories").add(category.toMap());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      drawer: const CustomDrawer(activeItem: 'home'),
      body: TabNavigation(),
    );
  }
}
