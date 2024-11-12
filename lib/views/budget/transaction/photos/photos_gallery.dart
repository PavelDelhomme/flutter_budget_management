import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:budget_management/views/budget/transaction/photos/image_screen.dart';

class PhotoGallery extends StatefulWidget {
  final DocumentSnapshot transaction;

  const PhotoGallery({super.key, required this.transaction});

  @override
  _PhotoGalleryState createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  final ImagePicker picker = ImagePicker();
  late List<String> photos = [];
  bool isLoading = false;


  Future<void> _loadPhotos() async {
    setState(() => isLoading = true);
    final data = widget.transaction.data() as Map<String, dynamic>?;
    List<String> fetchedPhotos = data != null && data.containsKey('photos') ? List<String>.from(data['photos']) : [];
    setState(() {
      photos.clear();
      photos.addAll(fetchedPhotos);
      isLoading = false;
    });
  }


  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _pickImageAndUpload() async {
    if (photos.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous ne pouvez ajouter que 2 photos.")),
      );
      return;
    }

    final XFile? pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ajouter une photo"),
          content: const Text("Choisissez une option pour ajouter une photos."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context, await picker.pickImage(source: ImageSource.camera));
              },
              child: const Text("Prendre une photo"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery));
              },
              child: const Text("Depuis la galerie"),
            ),
          ],
        );
      },
    );

    if (pickedFile != null) {
      final String fileName = DateTime.now().toIso8601String();
      final File imageFile = File(pickedFile.path);

      try {
        final downloadUrl = await FirebaseStorage.instance
            .ref(fileName)
            .putFile(imageFile)
            .then((task) => task.ref.getDownloadURL());
        await widget.transaction.reference.update({
          "photos": FieldValue.arrayUnion([downloadUrl]),
        });
        _loadPhotos();
      } catch (e) {
        log("Erreur lors de l'upload de l'image : $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bouton pour ajouter une photo si moins de 2
        if (photos.length < 2)
          ElevatedButton.icon(
            onPressed: _pickImageAndUpload,
            icon: const Icon(Icons.add_a_photo),
            label: const Text("Ajouter une photo"),
          ),
        const SizedBox(height: 10),
        isLoading
            ? const CircularProgressIndicator()
            : Wrap(
          spacing: 10,
          children: photos.map((url) {
            return GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageScreen(
                      imageUrl: url,
                      transaction: widget.transaction,
                    ),
                  ),
                );
                if (result == "removed" || result == "replaced") {
                  _loadPhotos();
                }
              },
              child: SizedBox(
                height: 100,
                width: 100,
                child: Image.network(url, fit: BoxFit.cover),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

