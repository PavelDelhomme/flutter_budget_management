import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

final FirebaseStorage storage = FirebaseStorage.instance;

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Upload une image
  Future<String?> uploadImage(File file) async {
    try {
      String fileName = DateTime.now().toIso8601String();
      Reference storageReference = _storage.ref().child("transactions/$fileName");
      UploadTask uploadTask = storageReference.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      log("Erreur lors de l'upload de l'image : $e");
      return null;
    }
  }

  // Remove an image from Firebase Storage and update Firestore
  Future<void> removeImage(String imageUrl, DocumentReference transactionRef) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
      await transactionRef.update({
        "photos": FieldValue.arrayRemove([imageUrl]),
      });
    } catch (e) {
      log("Erreur lors de la suppression de l'image : $e");
    }
  }

  // Replace an existing image with a new one in Firebase Storage and Firestore
  Future<void> replaceImage(BuildContext context, String imageUrl, DocumentReference transactionRef) async {
    final XFile? pickedFile = await showImageSourceDialog(context);

    if (pickedFile != null) {
      final String fileName = DateTime.now().toIso8601String();
      final File imageFile = File(pickedFile.path);

      try {
        final newUrl = await _storage
            .ref(fileName)
            .putFile(imageFile)
            .then((task) => task.ref.getDownloadURL());

        await transactionRef.update({
          "photos": FieldValue.arrayRemove([imageUrl]),
          "photos": FieldValue.arrayUnion([newUrl]),
        });
      } catch (e) {
        log("Erreur lors du remplacement de l'image : $e");
      }
    }
  }

  // Show a dialog to pick an image from camera or gallery
  Future<XFile?> showImageSourceDialog(BuildContext context) async {
    return showDialog<XFile?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choisissez une option"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context, await _picker.pickImage(source: ImageSource.camera));
              },
              child: const Text("Prendre une photo"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context, await _picker.pickImage(source: ImageSource.gallery));
              },
              child: const Text("Depuis la galerie"),
            ),
          ],
        );
      },
    );
  }
}