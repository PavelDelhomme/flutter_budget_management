import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageScreen extends StatelessWidget {
  final String imageUrl;
  final DocumentSnapshot transaction;

  const ImageScreen(
      {super.key, required this.imageUrl, required this.transaction});

  Future<void> _removePhoto(BuildContext context) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      await transaction.reference.update({
        "photos": FieldValue.arrayRemove([imageUrl]),
      });
      Navigator.pop(context, "removed");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Erreur lors de la suppression de la photo")),
      );
    }
  }

  Future<void> _replacePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Choisissez une option"),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(context)
                    .pop(await picker.pickImage(source: ImageSource.camera));
              },
              child: const Text("Prendre une photo"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context)
                    .pop(await picker.pickImage(source: ImageSource.gallery));
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
        final newUrl = await FirebaseStorage.instance
            .ref(fileName)
            .putFile(imageFile)
            .then((task) => task.ref.getDownloadURL());
        await transaction.reference.update({
          "photos": FieldValue.arrayRemove([imageUrl]),
          "photos": FieldValue.arrayUnion([newUrl]),
        });
        Navigator.pop(context, "replaced");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur lors du remplacement de la photo")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reçus"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _removePhoto(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _replacePhoto(context),
          ),
        ],
      ),
      body: Center(
        child: Image.network(
          imageUrl,
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
    );
  }
}
