import 'dart:io';
import 'package:budget_management/services/utils_services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageScreen extends StatelessWidget {
  final String imageUrl;
  final DocumentSnapshot transaction;

  const ImageScreen(
      {super.key, required this.imageUrl, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reçu"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await removeImage(imageUrl, transaction.reference);
              Navigator.pop(context, "removed");
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await replaceImage(context, imageUrl, transaction.reference);
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
