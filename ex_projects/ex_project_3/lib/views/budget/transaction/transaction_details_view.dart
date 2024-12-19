import 'dart:developer';
import 'dart:io';
import 'package:budget_management/views/budget/transaction/ancien_detail/transaction_details_modal.dart';
import 'package:budget_management/views/budget/transaction/transaction_form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

import '../../../services/transactions.dart';


class TransactionDetailsView extends StatefulWidget {
  final DocumentSnapshot transaction;

  const TransactionDetailsView({super.key, required this.transaction});

  @override
  _TransactionDetailsViewState createState() => _TransactionDetailsViewState();
}

class _TransactionDetailsViewState extends State<TransactionDetailsView> {
  final ValueNotifier<List<String>> photosNotifier = ValueNotifier<List<String>>([]);
  final ImagePicker picker = ImagePicker();
  FirebaseStorage storage = FirebaseStorage.instance;
  late bool isLoading = false;
  String? statusMessage;

  @override
  void initState() {
    super.initState();
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

  String _addCacheBuster(String url) {
    final cacheBuster = 'cache_buster=${DateTime.now().millisecondsSinceEpoch}';
    return url.contains('?') ? '$url&$cacheBuster' : '$url?$cacheBuster';
  }


  Future<void> _loadInitialPhotos() async {
    setState(() => isLoading = true);
    try {
      final data = widget.transaction.data() as Map<String, dynamic>?;
      photosNotifier.value = data != null && data.containsKey("photos") ? List<String>.from(data['photos']) : [];
    } catch (e) {
      photosNotifier.value = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    photosNotifier.dispose();
    super.dispose();
  }


  Future<void> _pickImageAndUpload() async {
    if (photosNotifier.value.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous ne pouvez ajouter que 2 photos.")),
      );
      return;
    }

    // Boîte de dialogue pour choisir entre caméra et galerie
    final XFile? pickedFile = await showDialog<XFile>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ajouter une photo"),
          content: const Text("Choisissez une option pour ajouter une photo."),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final XFile? cameraFile = await picker.pickImage(source: ImageSource.camera);
                Navigator.of(context).pop(cameraFile);
              },
              child: const Text("Caméra"),
            ),
            TextButton(
              onPressed: () async {
                final XFile? galleryFile = await picker.pickImage(source: ImageSource.gallery);
                Navigator.of(context).pop(galleryFile);
              },
              child: const Text("Galerie"),
            ),
          ],
        );
      },
    );

    if (pickedFile != null) {
      setState(() => isLoading = true);
      try {
        final fileName = DateTime.now().toIso8601String();
        final storageRef = storage.ref(fileName);
        await storageRef.putFile(File(pickedFile.path));

        final downloadUrl = await storageRef.getDownloadURL();
        await widget.transaction.reference.update({
          "photos": FieldValue.arrayUnion([downloadUrl]),
        });

        photosNotifier.value = List.from(photosNotifier.value)..add(downloadUrl);
        statusMessage = "Photo ajoutée avec succès";
      } catch (e) {
        log("Erreur lors de l'upload de l'image : $e");
        statusMessage = "Erreur lors de l'upload de l'image";
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _removePhoto(String url) async {
    try {
      await widget.transaction.reference.update({
        "photos": FieldValue.arrayRemove([url]),
      });
      photosNotifier.value = List.from(photosNotifier.value)..remove(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo supprimée")),
      );
    } catch (e) {
      log("Erreur lors de la suppression de la photo : $e");
    }
  }

  Future<void> _replacePhoto(String oldUrl) async {
    final XFile? pickedFile = await showDialog<XFile>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Remplacer la photo"),
          content: const Text("Choisissez une option pour remplacer la photo."),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final XFile? cameraFile = await picker.pickImage(source: ImageSource.camera);
                Navigator.of(context).pop(cameraFile);
              },
              child: const Text("Caméra"),
            ),
            TextButton(
              onPressed: () async {
                final XFile? galleryFile = await picker.pickImage(source: ImageSource.gallery);
                Navigator.of(context).pop(galleryFile);
              },
              child: const Text("Galerie"),
            ),
          ],
        );
      },
    );

    if (pickedFile != null) {
      setState(() => isLoading = true);
      try {
        final fileName = DateTime.now().toIso8601String();
        final storageRef = storage.ref(fileName);
        await storageRef.putFile(File(pickedFile.path));

        final newUrl = await storageRef.getDownloadURL();

        // Supprimer l'ancienne photo et ajouter la nouvelle dans Firestore
        await widget.transaction.reference.update({
          "photos": FieldValue.arrayRemove([oldUrl]),
        });
        await widget.transaction.reference.update({
          "photos": FieldValue.arrayUnion([newUrl]),
        });

        // Recharger les photos pour s'assurer que l'ancienne image est supprimée
        photosNotifier.value = List.from(photosNotifier.value)
          ..remove(oldUrl)
          ..add(_addCacheBuster(newUrl));


        statusMessage = "Photo remplacée avec succès";

        // Recharger les données pour s'assurer que l'ancienne photo est bien supprimée
        //await _loadInitialPhotos();

        //statusMessage = "Photo remplacée avec succès";
      } catch (e) {
        log("Erreur lors du remplacement de l'image : $e");
        statusMessage = "Erreur lors du remplacement de l'image";
      } finally {
        setState(() => isLoading = false);
      }
    }
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
      await TransactionService().addRetroactiveRecurringTransaction(
        userId: userId,
        categoryId: categoryId,
        startDate: transactionDate,
        amount: amount,
        isDebit: TransactionService().isDebitTransaction(transaction),
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
        appBar: AppBar(title: const Text("Transaction")),
        body: const Center(
          child: Text("Erreur : Aucune donnée disponible pour cette transaction."),
        ),
      );
    }

    final bool isDebit = TransactionService().isDebitTransaction(widget.transaction);
    final bool isRecurring = data['isRecurring'] ?? false;
    final String? categoryId = isDebit ? data['categorie_id'] : null;
    final LatLng? location = data['localisation'] != null
        ? LatLng((data['localisation'] as GeoPoint).latitude, (data['localisation'] as GeoPoint).longitude)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de la transaction"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionFormScreen(transaction: widget.transaction),
                ),
              );
              if (result == true) {
                _loadInitialPhotos();
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
                  Text(
                    "Date : ${DateFormat.yMMMMd('fr_FR').format((data['date'] as Timestamp).toDate())}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Montant : ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TransactionService().formatTransactionAmount(data['amount'] ?? 0.0, isDebit),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (categoryId != null && categoryId.isNotEmpty)
                    FutureBuilder<String>(
                      future: _getCategoryName(categoryId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Chargement de la catégorie...', style: TextStyle(fontSize: 18));
                        } else if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('Catégorie inconnue', style: TextStyle(fontSize: 18));
                        }
                        return Text('Catégorie : ${snapshot.data}', style: const TextStyle(fontSize: 18));
                      },
                    )
                  else
                    Text(
                      'Type : ${isDebit ? 'Débit' : 'Crédit'}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Notes : ${data['notes'] ?? ''}', style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transaction récurrente :', style: TextStyle(fontSize: 18)),
                      Switch(
                        value: isRecurring,
                        onChanged: (value) async {
                          await _toggleRecurrence(context, widget.transaction, value);
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (location != null)
                    FutureBuilder<String>(
                      future: _getAddressFromLatLng(location),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Chargement de l\'adresse...', style: TextStyle(fontSize: 18));
                        } else if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('Adresse inconnue', style: TextStyle(fontSize: 18));
                        }
                        return Text('Adresse : ${snapshot.data}', style: const TextStyle(fontSize: 18));
                      },
                    ),
                  const SizedBox(height: 20),
                  if (isDebit)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Ajouter une photo (2 max)"),
                        if (photosNotifier.value.length < 2)
                          ElevatedButton(
                            onPressed: _pickImageAndUpload,
                            child: const Icon(Icons.add_a_photo),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<List<String>>(
                      valueListenable: photosNotifier,
                      builder: (context, photos, child) {
                        return Column(
                          children: photos.map((url) {
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ImageScreen(imageUrl: url)),
                                    );
                                  },
                                  child: SizedBox(
                                    height: 150,
                                    width: 150,
                                    child: Image.network(
                                      _addCacheBuster(url),
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        return loadingProgress == null
                                            ? child
                                            : const Center(child: CircularProgressIndicator());
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(url),
                                    child: const Icon(Icons.close, color: Colors.red, size: 30),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _replacePhoto(url),
                                    child: const Icon(Icons.refresh, color: Colors.blue, size: 30),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                    if (statusMessage != null)
                      Text(statusMessage!, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
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