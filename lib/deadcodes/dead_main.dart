import 'package:budget_management/views/authentication/auth_wrapper.dart';
import 'package:budget_management/views/authentication/connexion_view.dart';
import 'package:budget_management/views/home/home_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

void dead_main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //FirebaseFirestore.instance.clearPersistence();
  await initializeDateFormatting('fr_FR', null);


  runApp(const MyApp());
}
//todo plutot que source de revenu, transaction débit / crédit, les entrée et sorite, il peux définir entrée et définir des sortie.
// todo liste des source de revenus possible (salaire cadeauxx autre)
// todo définition revenu dans le drawer
// définition des revenu de dois pas bloquer le reste de l'expérience


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/sing-in': (context) => const ConnexionView(),
        '/home': (context) => const HomeView()
      },
    );
  }
}