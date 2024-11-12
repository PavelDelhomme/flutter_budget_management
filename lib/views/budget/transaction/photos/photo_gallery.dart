import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_screen.dart';
import 'package:budget_management/services/utils_services/image_service.dart';

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
  int currentIndex = 0;


  Future<void> _loadPhotos() async {
    setState(() => isLoading = true);
    final data = widget.transaction.data() as Map<String, dynamic>?;
    List<String> fetchedPhotos = data != null && data.containsKey('photos') ? List<String>.from(data['photos']) : [];
    setState(() {
      photos = fetchedPhotos;
      isLoading = false;
      /*
      photos.clear();
      photos.addAll(fetchedPhotos);
      isLoading = false;
      */
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

    final XFile? pickedFile = await showImageSourceDialog(context, picker);
    if (pickedFile != null) {
      final String? downloadUrl = await uploadImage(File(pickedFile.path));
      if (downloadUrl != null) {
        await widget.transaction.reference.update({
          "photos": FieldValue.arrayUnion([downloadUrl]),
        });
        _loadPhotos();
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
            : photos.isEmpty
                ? const Text("Aucune photo disponible")
                : SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: photos.length,
                      controller: PageController(initialPage: currentIndex),
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageScreen(
                                  imageUrl: photos[index],
                                  transaction: widget.transaction,
                                ),
                              ),
                            );
                            if (result == "removed" || result == "replaced") {
                              _loadPhotos();
                            }
                          },
                          child: Image.network(
                            photos[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}

