import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

final FirebaseStorage storage = FirebaseStorage.instance;


Future<String?> uploadImage(File file) async {
  try {
    String fileName = DateTime.now().toIso8601String();
    Reference storageReference = storage.ref().child("transactions/$fileName");
    UploadTask uploadTask = storageReference.putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask;
    return await taskSnapshot.ref.getDownloadURL();
  } catch (e) {
    log("Erreur lors de l'upload de l'image : $e");
    return null;
  }
}


Future<void> removeImage(String imageUrl, DocumentReference transactionRef) async {
  try {
    // Supprimer l'image de Firebase Storage
    await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    // Mettre à jour Firestore pour supprimer l'URL
    await transactionRef.update({
      "photos": FieldValue.arrayRemove([imageUrl]),
    });
  } catch (e) {
    log("Erreur lors de la suppression de l'image : $e");
  }
}

Future<void> replaceImage(BuildContext context, String imageUrl, DocumentReference transactionRef) async {
  final picker = ImagePicker();
  final XFile? pickedFile = await showDialog<XFile?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Choisissez une option pour remplacer la photo."),
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
    final String fileName = DateTime.now().toIso8601String();
    final File imageFile = File(pickedFile.path);

    try {
      final newUrl = await FirebaseStorage.instance
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

Future<XFile?> showImageSourceDialog(BuildContext context, ImagePicker picker) {
  return showDialog<XFile?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Choisissez une option"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context, await picker.pickImage(source: ImageSource.camera));
            },
            child: const Text("Prendre une photo"),
          ),
          TextButton(onPressed: () async {
            Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery));
            },
            child: const Text("Depuis la galerie"),
          ),
        ],
      );
    },
  );
}