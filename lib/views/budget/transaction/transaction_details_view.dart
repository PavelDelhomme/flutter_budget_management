import 'dart:developer';
import 'package:budget_management/utils/recurring_transactions.dart';
import 'package:budget_management/views/budget/transaction/photos/photos_gallery.dart';
import 'package:budget_management/views/budget/transaction/transaction_form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

import '../../../utils/transactions.dart';

class TransactionDetailsView extends StatefulWidget {
  final DocumentSnapshot transaction;

  const TransactionDetailsView({super.key, required this.transaction});

  @override
  _TransactionDetailsViewState createState() => _TransactionDetailsViewState();
}

class _TransactionDetailsViewState extends State<TransactionDetailsView> {
  final ValueNotifier<List<String>> photosNotifier = ValueNotifier<List<String>>([]);

  FirebaseStorage storage = FirebaseStorage.instance;
  //List<String> photos = [];
  late bool isLoading = false;
  String? statusMessage;

  @override
  void initState() {
    super.initState();
    // Charger les photos initiales
    /*
    final data = widget.transaction.data() as Map<String, dynamic>;
    photos = data.containsKey('photos') ? List<String>.from(data['photos']) : [];
    log("Initial photos loaded :$photos");*/
    _loadInitialPhotos();
  }


  Future<String> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      return placemarks.isNotEmpty
          ? placemarks.first.street ?? 'Adresse inconnue'
          : 'Adresse inconnue';
    } catch (e) {
      log("Adresse inconnue : $e");
      return 'Adresse inconnue';
    }
  }

  Future<String> _getCategoryName(String categoryId) async {
    try {
      DocumentSnapshot categorySnapshot = await FirebaseFirestore.instance
          .collection("categories")
          .doc(categoryId)
          .get();

      if (categorySnapshot.exists) {
        return categorySnapshot.get("name");
      } else {
        log("Catégorie avec ID $categoryId non trouvé.");
        return "Catégorie inconnue";
      }
    } catch (e) {
      log("Erreur lors de la récupération de la catégorie $e");
      return "Erreur lors de la récupération de la catégorie";
    }
  }

  Future<void> _loadInitialPhotos() async {
    setState(() => isLoading = true);
    final data = widget.transaction.data() as Map<String, dynamic>?;
    photosNotifier.value = data != null && data.containsKey("photos") ? List<String>.from(data['photos']) : [];
    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    photosNotifier.dispose();
    super.dispose();
  }

  Future<void> _toggleRecurrence(BuildContext context,
      DocumentSnapshot transaction, bool makeRecurring) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final DateTime transactionDate = (transaction['date'] as Timestamp).toDate();
    final collection = transaction.reference.parent.id;
    final amount = transaction['amount'];
    final categoryId = transaction['categorie_id'] ?? "";

    if (makeRecurring) {
      await FirebaseFirestore.instance.collection(collection)
          .doc(transaction.id)
          .update({'isRecurring': true});
      await addRetroactiveRecurringTransaction(
        userId: userId,
        categoryId: categoryId,
        startDate: transactionDate,
        amount: amount,
        isDebit: isDebitTransaction(transaction),
      );
    } else {
      bool confirmAllOccurrences = await _confirmToggleFutureOccurrences(context);
      if (confirmAllOccurrences) {
        await FirebaseFirestore.instance.collection(collection)
            .where('user_id', isEqualTo: userId)
            .where('isRecurring', isEqualTo: true)
            .where('categorie_id', isEqualTo: categoryId)
            .where('date', isGreaterThan: Timestamp.fromDate(transactionDate))
            .get()
            .then((snapshot) async {
          for (var doc in snapshot.docs) {
            await doc.reference.delete();
          }
        });
      }
      await FirebaseFirestore.instance.collection(collection)
          .doc(transaction.id)
          .update({'isRecurring': false});
    }
  }
  Future<bool> _confirmToggleFutureOccurrences(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Désactiver la récurrence"),
          content: const Text("Voulez-vous désactiver la récurrence pour toutes les occurrences futures ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Non"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Oui"),
            ),
          ],
        );
      },
    ) ??
        false;
  }


  @override
  Widget build(BuildContext context) {
    final data = widget.transaction.data() as Map<String, dynamic>?;

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Transaction")),
        body: const Center(
          child: Text("Erreur : Aucune donnée disponible pour cette transaction."),
        ),
      );
    }

    final bool isDebit = isDebitTransaction(widget.transaction);
    log("transaction_details_view.dart : transaction.reference.parent.id : ${widget.transaction.reference.parent.id}");
    log("Déterminé isDebit : $isDebit");


    final bool isRecurring = data['isRecurring'] ?? false;
    final String? categoryId = isDebit ? data['categorie_id'] : null;
    final LatLng? location = data['localisation'] != null ? LatLng((data['localisation'] as GeoPoint).latitude, (data['localisation'] as GeoPoint).longitude) : null;

    // Log les détails de la transaction
    log("Détails de la transaction - Type : ${isDebit ? 'Débit' : 'Crédit'}, Catégorie ID : $categoryId");

    //final List<String> photos = isDebit && data.containsKey('photos') ? List<String>.from(data['photos'] ?? []) : [];


    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de la transcation"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionFormScreen(transaction: widget.transaction)
                ),
              );

              // Si la transaction est mise à jour, rafraîchit les détails
              if (result == true) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Text(
                      "Date : ${DateFormat.yMMMMd('fr_FR').format((data['date'] as Timestamp).toDate())}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),// Montant
                    Row(
                      children: [
                        const Text(
                          'Montant : ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        formatTransactionAmount(data['amount'] ?? 0.0, isDebit),
                      ],
                    ),
                    const SizedBox(height: 10),// Catégorie
                    if (categoryId != null && categoryId.isNotEmpty)
                      FutureBuilder<String>(
                        future: _getCategoryName(categoryId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'Chargement de la catégorie...',
                              style: TextStyle(fontSize: 18),
                            );
                          } else if (snapshot.hasError || !snapshot.hasData) {
                            return const Text(
                              'Catégorie inconnue',
                              style: TextStyle(fontSize: 18),
                            );
                          }
                          return Text(
                            'Catégorie : ${snapshot.data}',
                            style: const TextStyle(fontSize: 18),
                          );
                        },
                      )
                    else // Type
                      Text(
                        'Type : ${isDebit ? 'Débit' : 'Crédit'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    const SizedBox(height: 10), // Notes
                    Row(
                      children: [
                        Text('Notes : ${data['notes'] ?? ''}', style: const TextStyle(fontSize: 18))
                      ],
                    ),
                    const SizedBox(height: 10), // Réccurence
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transaction récurrente :',
                            style: TextStyle(fontSize: 18)),
                        Switch(
                          value: isRecurring,
                          onChanged: (value) async {
                            await _toggleRecurrence(context, widget.transaction, value);
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 20), // Localisation
                    if (location != null) ...[
                      FutureBuilder<String>(
                        future: _getAddressFromLatLng(location),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text('Chargement de l\'adresse...',
                                style: TextStyle(fontSize: 18));
                          } else if (snapshot.hasError || !snapshot.hasData) {
                            return const Text('Adresse inconnue',
                                style: TextStyle(fontSize: 18));
                          }
                          return Text('Adresse : ${snapshot.data}',
                              style: const TextStyle(fontSize: 18));
                        },
                      ),
                    ],
                    const SizedBox(height: 20), // Photos
                    /*
                    if (photos.isNotEmpty)
                      if (photos.length < 2)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Ajouter une photo (2 max)"),
                            // Button pour ajouter une photo
                            if (photos.length < 2)
                              ElevatedButton(
                                onPressed: () async {
                                  _pickImageAndUpload(context);
                                },
                                child: const Icon(Icons.add_a_photo),
                              ),
                          ],
                        ),
                      const SizedBox(height: 10), // Affichage des photos
                      Column(
                        children: photos.map((url) {
                          return Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ImageScreen(imageUrl: url),
                                    ),
                                  );
                                },
                                child: SizedBox(
                                  height: 150,
                                  width: 150,
                                  child: Image.network(
                                    url,
                                    key: ValueKey(url),
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.error, color: Colors.red, size: 50),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _confirmAndRemovePhoto(context, url),
                                  child: const Icon(Icons.close, color: Colors.red, size: 30),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _replacePhoto(context, url),
                                  child: const Icon(Icons.refresh, color: Colors.blue, size: 30),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),*/
                    PhotoGallery(
                        transaction: widget.transaction,
                    ),
                    /*
                    if (photos.isNotEmpty)
                      if (photos.length < 2)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Ajouter une photo (2 max)"),
                            // Button pour ajouter une photo
                            if (photos.length < 2)
                              ElevatedButton(
                                onPressed: () async {
                                  _pickImageAndUpload(context);
                                },
                                child: const Icon(Icons.add_a_photo),
                              ),
                          ],
                        ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Si photos n'est pas vide, afficher les images
                        if (photos.isNotEmpty)
                          ...photos.map((url) => Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageScreen(imageUrl: url),
                                    ),
                                  );
                                },
                                child: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: Image.network(
                                    url,
                                    key: ValueKey(url),
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.error, color: Colors.red, size: 50),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _confirmAndRemovePhoto(context, url),
                                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _replacePhoto(context, url),
                                  child: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                                ),
                              ),
                            ],
                          )).toList(),
                      ],
                    ),
                     */
                  ],
                ),
              ),
          ),
          if (isLoading)
            const Center(
                child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}


class ImageScreen extends StatelessWidget {
  final String imageUrl;

  const ImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reçu"),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.error, color: Colors.red, size: 50),
            );
          },
        ),
      ),
    );
  }
}