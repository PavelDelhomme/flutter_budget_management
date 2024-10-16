import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../navigation/custom_drawer.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
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

  Future<void> _updateEmail() async {
    if (user != null && _emailController.text.isNotEmpty) {
      try {
        await user!.updateEmail(_emailController.text);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Email mis à jour.")));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur : $e")));
      }
    }
  }

  Future<void> _updatePassword() async {
    if (user != null && _passwordController.text.isNotEmpty) {
      try {
        await user!.updatePassword(_passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mot de passe mis à jour.')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
              ExpansionTile(
                title: const Text("Modifier l'adresse email"),
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                        labelText: "Nouvelle adresse email"),
                  ),
                  ElevatedButton(
                    onPressed: _updateEmail,
                    child: const Text("Mettre à jour l'e-mail"),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text("Modifier le mot de passe"),
                children: [
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                        labelText: "Nouveau mot de passe"),
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
