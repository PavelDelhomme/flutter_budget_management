import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../authentication/connexion_view.dart';
import '../home/home_view.dart';
import '../budget/budget/budget_view.dart';
import '../profile/profile_view.dart';
import '../settings/settings_view.dart';
import '../budget/saving/savings_page.dart';

class CustomDrawer extends StatelessWidget {
  final String activeItem;

  const CustomDrawer({super.key, required this.activeItem});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Effacement du cache local
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ConnexionView()),
    );
  }

  Future<void> _deleteDatas(String collection, String userId) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .where("user_id", isEqualTo: userId)
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
    });
  }

  Future<void> _deleteUserData(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    try {
      // Supprime les documents dans les collections debits, credits, budgets, et categories
      await _deleteDatas("debits", userId);
      await _deleteDatas("credits", userId);
      await _deleteDatas("budgets", userId);
      await _deleteDatas("categories", userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Données utilisateur supprimées avec succès.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la suppression des données...")),
      );
      log("Erreur lors de la suppressions des données : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Bonjour, ${user?.email ?? 'Utilisateur'}'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            text: 'Accueil',
            destination: const HomeView(),
            active: activeItem == 'home',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.attach_money,
            text: 'Budgets',
            destination: const BudgetView(),
            active: activeItem == 'budgets',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.savings,
            text: 'Économies',
            destination: SavingsPage(),
            active: activeItem == 'savings',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.account_circle,
            text: 'Profil',
            destination: const ProfileView(),
            active: activeItem == 'profile',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            text: 'Paramètres',
            destination: const SettingsView(),
            active: activeItem == 'settings',
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Supprimer les données"),
            onTap: () => _deleteUserData(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {
    required IconData icon,
    required String text,
    required Widget destination,
    required bool active,
  }) {
    return ListTile(
      leading: Icon(icon, color: active ? Colors.blue : null),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? Colors.blue : null,
        ),
      ),
      tileColor: active ? Colors.blue.shade100 : null,
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }
}
