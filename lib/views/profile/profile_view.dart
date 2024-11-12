import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../navigation/custom_drawer.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  ProfileViewState createState() => ProfileViewState();
}

class ProfileViewState extends State<ProfileView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _emailController.text = user!.email ?? "";
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _reauthenticateUser(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user!.reauthenticateWithCredential(credential);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ré-authentification réussie"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de ré-authentification: $e"))
      );
    }
  }

  // Popup pour ré-authentification
  Future<void> _showReauthPopup() async {
    String email = '';
    String password = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ré-authentification requise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Adresse email'),
                onChanged: (value) {
                  email = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                onChanged: (value) {
                  password = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _reauthenticateUser(email, password);
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  // Mise à jour du mot de passe
  Future<void> _updatePassword() async {
    if (_passwordController.text.isNotEmpty) {
      try {
        await user!.updatePassword(_passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mot de passe mis à jour.')));
      } catch (e) {
        if (e.toString().contains('requires-recent-login')) {
          _showReauthPopup(); // Demander la ré-authentification
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(activeItem: 'profile'),
      appBar: AppBar(title: const Text("Mon Profil")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Affichage seulement du champ de modification du mot de passe
              ExpansionTile(
                title: const Text("Modifier le mot de passe"),
                children: [
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: "Nouveau mot de passe"),
                    obscureText: true,
                  ),
                  ElevatedButton(
                    onPressed: _updatePassword,
                    child: const Text("Mettre à jour le mot de passe"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
