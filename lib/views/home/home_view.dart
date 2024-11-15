import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/transactions.dart';
import '../navigation/custom_drawer.dart';
import '../navigation/tab_navigation.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _initializeRecurringTransactions();
    fixFirestoreLocationField();
  }

  void _initializeRecurringTransactions () {
    _transactionService.copyRecurringTransactionsForNewMonth();
  }
  Future<void> fixFirestoreLocationField() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final transactionsCollections = ['debits', 'credits'];

    for (String collection in transactionsCollections) {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('user_id', isEqualTo: user.uid)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('location') && !data.containsKey('localisation')) {
          final GeoPoint? location = data['location'] as GeoPoint?;
          await doc.reference.update({
            'localisation': location,
            'location': FieldValue.delete(),
          });
        }
      }
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
