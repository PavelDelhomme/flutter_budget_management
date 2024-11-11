import 'dart:developer';
import 'dart:io';
import 'package:budget_management/services/utils_services/image_service.dart';
import 'package:budget_management/utils/recurring_transactions.dart';
import 'package:budget_management/views/budget/transaction/transaction_form_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

import '../../../utils/transactions.dart';

class TransactionDetailsView extends StatelessWidget {
  final DocumentSnapshot transaction;

  const TransactionDetailsView({super.key, required this.transaction});

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

  Future<void> _replacePhoto(BuildContext context, String oldUrl) async {
    final picker = ImagePicker();
    final pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Choississez une option"),
          actions: <Widget>[
            TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(await picker.pickImage(source: ImageSource.camera));
                },
                child: const Text("Prendre une photo"),
            ),
            TextButton(
                onPressed: () async {
                  Navigator.of(context).pop(await picker.pickImage(source: ImageSource.gallery));
                },
                child: Text("Depuis la gallery"),
            ),
          ],
        );
      }
    );

    if (pickedFile != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Uploadez la nouvelle image (à personnaliser en fonction de votre fonction de téléchargement)
        final newUrl = await uploadImage(File(pickedFile.path), user.uid);
        if (newUrl != null) {
          // Mettez à jour Firestore en supprimant l'ancienne URL et ajoutant la nouvelle
          await transaction.reference.update({
            "photos": FieldValue.arrayRemove([oldUrl]),
          });
          await transaction.reference.update({
            "photos": FieldValue.arrayUnion([newUrl]),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Photo remplacée avec succès")),
          );
        }
      }
    }
  }

  Future<void> _confirmAndRemovePhoto(BuildContext context, String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: const Text("Êtes-vous sûr de vouloir supprimer cette photo ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _removePhoto(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo supprimée")),
      );
    }
  }

  Future<void> _removePhoto(String url) async {
    try {
      await transaction.reference.update({
        "photos": FieldValue.arrayRemove([url]),
      });
    } catch (e) {
      log("Erreur lors de la suppression de la photo : $e");
    }
  }
  Future<void> _pickImageAndUpload(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Choississez une option"),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(await picker.pickImage(source: ImageSource.camera));
              },
              child: const Text("Prendre une photo"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(await picker.pickImage(source: ImageSource.gallery));
              },
              child: const Text("Depuis la galerie"),
            ),
          ],
        );
      },
    );

    if (pickedFile != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newUrl = await uploadImage(File(pickedFile.path), user.uid);
        if (newUrl != null) {
          await transaction.reference.update({
            "photos": FieldValue.arrayUnion([newUrl]),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Photo ajoutée avec succès")),
          );
        }
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
    final data = transaction.data() as Map<String, dynamic>?;

    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Transaction")),
        body: const Center(
          child: Text("Erreur : Aucune donnée disponible pour cette transaction."),
        ),
      );
    }

    final bool isDebit = isDebitTransaction(transaction);
    log("transaction_details_view.dart : transaction.reference.parent.id : ${transaction.reference.parent.id}");
    log("Déterminé isDebit : $isDebit");

    final amount = data['amount'] ?? 0.0;
    final date = DateFormat.yMMMMd('fr_FR').format((data['date'] as Timestamp).toDate());
    final notes = data['notes'] ?? '';
    final bool isRecurring = data['isRecurring'] ?? false;
    final List<String> photos = isDebit && data.containsKey('photos') ? List<String>.from(data['photos'] ?? []) : [];
    final String? categoryId = isDebit ? data['categorie_id'] : null;
    final LatLng? location = data['localisation'] != null ? LatLng((data['localisation'] as GeoPoint).latitude, (data['localisation'] as GeoPoint).longitude) : null;

    // Log les détails de la transaction
    log("Détails de la transaction - Montant : $amount, Type : ${isDebit ? 'Débit' : 'Crédit'}, Catégorie ID : $categoryId, Notes : $notes");


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
                  builder: (context) => TransactionFormScreen(transaction: transaction)
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Date : $date",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Montant : ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  formatTransactionAmount(amount, isDebit),
                ],
              ),
              const SizedBox(height: 10),
              if (categoryId != null && categoryId.isNotEmpty)
                FutureBuilder<String>(
                  future: _getCategoryName(categoryId),
                  builder: (context, snapshot) {
                    log(categoryId);
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
              else
                Text(
                  'Type : ${isDebit ? 'Débit' : 'Crédit'}',
                  style: const TextStyle(fontSize: 18),
                ),
              const SizedBox(height: 10),
              Text('Notes : $notes', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaction récurrente :',
                      style: TextStyle(fontSize: 18)),
                  Switch(
                    value: isRecurring,
                    onChanged: (value) async {
                      await _toggleRecurrence(context, transaction, value);
                      Navigator.of(context).pop();
                    },
                  )
                ],
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              if (photos.isNotEmpty)
                if (photos.length < 2)
                  ElevatedButton(
                    onPressed: () async {
                      await _pickImageAndUpload(context);
                    },
                    child: const Text("Ajouter une photo (2 max)"),
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
        ),
      )
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