import 'dart:io';
import 'package:flutter/material.dart';

class PhotosSection extends StatelessWidget {
  final List<File> photoFiles;
  final List<String> existingPhotos;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onRemovePhoto;

  const PhotosSection({
    Key? key,
    required this.photoFiles,
    required this.existingPhotos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Reçus :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            ...existingPhotos.map((url) => _buildPhotoWidget(context, url, isFile: false)),
            ...photoFiles.map((file) => _buildPhotoWidget(context, file.path, isFile: true)),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onAddPhoto,
          child: const Text("Ajouter des reçus (2 max)"),
        ),
      ],
    );
  }

  Widget _buildPhotoWidget(BuildContext context, String imagePath, {bool isFile = false}) {
    return Stack(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: isFile
              ? Image.file(File(imagePath), fit: BoxFit.cover)
              : Image.network(imagePath, fit: BoxFit.cover, loadingBuilder: (context, child, progress) {
            return progress == null ? child : const Center(child: CircularProgressIndicator());
          }),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemovePhoto(imagePath),
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ),
      ],
    );
  }
}
