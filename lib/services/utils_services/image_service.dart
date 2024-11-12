import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
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
    await storage.refFromURL(imageUrl).delete();
    await transactionRef.update({
      "photos": FieldValue.arrayRemove([imageUrl]),
    });
  } catch (e) {
    log("Erreur lors de la suppression de l'image : $e");
  }
}

Future<void> replaceImage(BuildContext context, String oldImageUrl, DocumentReference transactionRef) async {
  final ImagePicker picker = ImagePicker();
  final XFile? pickedFile = await showImageSourceDialog(context, picker);

  if (pickedFile != null) {
    final String? newUrl = await uploadImage(File(pickedFile.path));
    if (newUrl != null) {
      await transactionRef.update({
        "photos": FieldValue.arrayRemove([oldImageUrl]),
        "photos": FieldValue.arrayUnion([newUrl]),
      });
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