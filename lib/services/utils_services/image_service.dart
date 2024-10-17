import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';

Future<String?> uploadImage(File file, String userId) async {
  try {
    String fileName = basename(file.path);
    String storagePath = 'users/$userId/receipts/$fileName';

    // Référence au stockage Firebase
    Reference storageReference = FirebaseStorage.instance.ref().child(storagePath);

    // Démarrage upload du fichier
    UploadTask uploadTask = storageReference.putFile(file);
    TaskSnapshot taskSnapshot = await uploadTask;

    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    log("Erreur lors du l'upload : $e");
    return null;
  }
}