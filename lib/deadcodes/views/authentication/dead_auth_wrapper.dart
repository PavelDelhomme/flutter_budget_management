import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../home/dead_home_view.dart';
import 'dead_connexion_view.dart';

class DeadAuthWrapper extends StatelessWidget {
  const DeadAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const DeadHomeView();
        }

        return const DeadConnexionView();
      },
    );
  }
}