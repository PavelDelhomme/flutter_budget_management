import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoGallery extends StatefulWidget {
  final DocumentSnapshot transaction;

  const PhotoGallery({super.key, required this.transaction});

  @override
  _PhotoGalleryState createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker picker = ImagePicker();
  late List<String> photos = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => isLoading = true);
    final data = widget.transaction.data() as Map<String, dynamic>?;
    List<String> fetchedPhotos = data != null && data.containsKey('photos') ? List<String>.from(data['photos']) : [];

    // Mise à jour de la liste locale si différente de la liste Firebase
    if (fetchedPhotos.toString() != photos.toString()) {
      setState(() {
        photos = fetchedPhotos;
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _pickImageAndUpload(String source) async {
    if (photos.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous ne pouvez ajouter que 2 photos")),
      );
      return;
    }

    final XFile? pickedImage = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1920,
    );

    if (pickedImage == null) return;

    final String fileName = DateTime.now().toIso8601String();
    final File imageFile = File(pickedImage.path);

    try {
      await storage.ref(fileName).putFile(
        imageFile,
        SettableMetadata(customMetadata: {
          'uploaded_by': FirebaseAuth.instance.currentUser?.email ?? 'N/A',
          'description': 'User transaction image'
        }),
      );

      final String downloadUrl = await storage.ref(fileName).getDownloadURL();
      await widget.transaction.reference.update({
        "photos": FieldValue.arrayUnion([downloadUrl])
      });

      _loadPhotos();
    } catch (e) {
      log("Erreur lors de l'upload de l'image : $e");
    }
  }

  Future<void> _confirmAndRemovePhoto(String url) async {
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
    }
  }

  Future<void> _removePhoto(String url) async {
    try {
      await storage.refFromURL(url).delete();
      await widget.transaction.reference.update({
        "photos": FieldValue.arrayRemove([url]),
      });
      _loadPhotos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Photo supprimée")),
      );
    } catch (e) {
      log("Erreur lors de la suppression de la photo : $e");
    }
  }

  Future<bool> _isImageAccessible(String url, {int maxRetries = 5, int delayInSeconds = 4}) async {
    // Vérification de l'accessibilité de l'image après plusieur tentative avant de recharger le widget
    for (int i = 0; i < maxRetries; i++) {
      try {
        final request = await HttpClient().getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        log("Tentative $i : Image inaccessible. Erreur : $e");
      }
      await Future.delayed(Duration(seconds: delayInSeconds));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Ajouter une photo (2 max)"),
            if (photos.length < 2)
              ElevatedButton(
                onPressed: () async {
                  await _pickImageAndUpload('gallery');
                },
                child: const Icon(Icons.add_a_photo),
              ),
          ],
        ),
        const SizedBox(height: 10),
        isLoading
            ? const CircularProgressIndicator()
            : Wrap(
          spacing: 10,
          children: photos.map((url) {
            return FutureBuilder<bool>(
              future: _isImageAccessible(url),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError || !(snapshot.data ?? false)) {
                  return const Icon(Icons.error, color: Colors.red, size: 50);
                }
                return Stack(
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
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _confirmAndRemovePhoto(url),
                        child: const Icon(Icons.close, color: Colors.red, size: 20),
                      ),
                    ),
                  ],
                );
              },
            );
          }).toList(),
        ),
      ],
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
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(),
            );
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
