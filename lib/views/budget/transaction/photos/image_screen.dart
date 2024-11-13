import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../services/utils_services/image_service.dart';

class ImageScreen extends StatelessWidget {
  final String imageUrl;
  final DocumentSnapshot transaction;

  const ImageScreen(
      {super.key, required this.imageUrl, required this.transaction});
  Future<void> _confirmAndRemovePhoto(BuildContext context) async {
    bool confirmDeletion = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: const Text("Êtes-vous sûr de vouloir supprimer cette photo ?"),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Supprimer"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDeletion) {
      await ImageService().removeImage(imageUrl, transaction.reference);
      Navigator.pop(context, "removed"); // Indiquer la suppression
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reçu"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmAndRemovePhoto(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await ImageService().replaceImage(context, imageUrl, transaction.reference);
              Navigator.pop(context, "replaced");
            },
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
