import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Information de l'utilisateur",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Email : ${user?.email ?? 'Non disponible'}'),
            const SizedBox(height: 10),
            Text('ID utilisateur : ${user?.uid ?? 'Non disponible'}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Ajoute une action pour mettre à jour le profil
              },
              child: const Text('Mettre à jour le profil'),
            ),
          ],
        ),
      ),
    );
  }
}