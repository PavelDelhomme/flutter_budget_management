import 'dart:developer';
import 'dart:io';
// Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
// Others
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Map
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import 'package:nominatim_geocoding/nominatim_geocoding.dart';

// My package
import 'package:budget_management/utils/categories.dart';
import '../../../services/utils_services/permissions_service.dart';
import '../../../services/utils_services/image_service.dart';
import '../../../utils/transactions.dart';
import 'ancien_detail/transaction_details_modal.dart';

class TransactionFormScreen extends StatefulWidget {
  final DocumentSnapshot? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  TransactionFormScreenState createState() => TransactionFormScreenState();
}

class TransactionFormScreenState extends State<TransactionFormScreen> {
  // Categories
  String? _selectedCategory;
  bool _categoriesLoaded = false;
  List<String> _categories = [];
  final FocusNode _categoryFocusNode = FocusNode();

  // Transaction
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isRecurring = false;
  bool _isDebit = true;
  LatLng? _userLocation;
  final List<File> _photoFiles = [];
  List<String> _existingPhotos = [];

  // Map
  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(48.8566, 2.3522); // Defaut paris
  String? _currentAdress;
  final double _zoom = 16.0;

  @override
  void initState() {
    super.initState();
    Get.put(NominatimGeocoding());

    _loadCategories(); // Charger les catégories existantes
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      log("Transaction reçue : ${transaction.data()}");

      _isDebit = transaction.reference.parent.id == 'debits';
      _notesController.text = transaction['notes'] ?? '';
      _amountController.text = transaction['amount']?.toString() ?? '';
      _isRecurring = transaction['isRecurring'] ?? false;
      final Timestamp? date = transaction['date'] as Timestamp?;
      _dateController.text = date != null ? DateFormat('yMd').format(date.toDate()) : DateFormat('yMd').format(DateTime.now());

      // Localisation, uniquement pour les débits
      if (_isDebit) {
        // Initialisation des reçus existants
        _existingPhotos = List<String>.from(transaction['photos'] ?? []);
        final GeoPoint? location = (transaction?.data() as Map<String, dynamic>?)?.containsKey('location')  == true
            ? transaction!['location'] as GeoPoint?
            : null;

        _userLocation = location != null
            ? LatLng(location.latitude, location.longitude)
            : _defaultLocation;

        _selectedCategory = transaction['categorie_id']?.toString().trim() ?? '';
      }
    } else {
      _dateController.text = DateFormat('yMd').add_jm().format(DateTime.now());
      if (_isDebit) {
        _getCurrentLocation(); // Récupérer la localisation actuelle
      }
    }
  }

  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where("userId", isEqualTo: user.uid)
          .where("type", isEqualTo: _isDebit ? 'debit' : 'credit')
          .get();

      setState(() {
        _categories = categoriesSnapshot.docs.map((doc) => doc['name'].toString()).toSet().toList();
        _categoriesLoaded = true; // Important : assure que le formulaire est chargé
        // Si c'est une transaction existante, définir la catégorie sélectionnée
        if (widget.transaction != null && _selectedCategory == null) {
          final categoryId = widget.transaction!['categorie_id']?.toString();
          if (categoryId != null) {
            _selectedCategory = _categories.firstWhere(
                  (category) => category == categoryId,
              orElse: () => _categories.isNotEmpty ? _categories[0] : '',
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    await checkLocationServices(context);
    await checkLocationPermission(context);

    // Si la permission est accordée, récupérez la position actuelle
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_userLocation!, _zoom);
      });

      // Utilisation de Nominatim pour obtenir l'adresse via un Coordinate
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        Placemark place = placemarks.first;

        setState(() {
          _currentAdress =
          "${place.street}, ${place.locality}, ${place.administrativeArea}";
        });
      } catch (e) {
        log("Erreur lors de la récupération de l'adresse avec Nominatim : $e");
        setState(() {
          _currentAdress = "Adresse inconnue";
        });
      }
    } catch (e) {
      log("Erreur lors de la récupération de la localisation : $e");
      setState(() {
        _userLocation = _defaultLocation;
        _currentAdress = "Adresse inconnue";
      });
    }
  }

  Widget _buildTileLayer() {
    return TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: 'com.budget.budget_management',
    );
  }

  // Carte invisible pour initialiser MapController
  Widget _buildInvisibleMap() {
    return SizedBox(
      height: 0,
      width: 0,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation ?? _defaultLocation,
          initialZoom: _zoom,
        ),
        children: [
          _buildTileLayer(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return SizedBox(
      height: 250,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation ?? _defaultLocation,
          initialZoom: _zoom,
        ),
        children: [
          _buildTileLayer(),
          if (_userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _userLocation!,
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.location_on,
                    size: 50,
                    color: Colors.blue,
                  ),
                )
              ],
            )
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year - 1),
      lastDate: DateTime(initialDate.year + 1),
    );

    if (selectedDate != null) {
      setState(() {
        _dateController.text = DateFormat('EEEE d MMMM y', 'fr_FR').format(selectedDate);
      });
    }
  }

  Future<void> _createNewCategory() async {
    final TextEditingController categoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Créer une nouvelle catégorie"),
          content: TextField(
            controller: categoryController,
            decoration: const InputDecoration(hintText: "Nom de la catégorie"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Annuler"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Créer"),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && categoryController.text.isNotEmpty) {
                  String type = _isDebit ? 'debit' : 'credit';  // Déterminer le type (débit ou crédit)

                  // Créer la nouvelle catégorie avec le type approprié
                  await createCategory(categoryController.text.trim(), user.uid, type);

                  // Recharger les catégories après la création
                  _loadCategories();
                }
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }
  Future<void> _saveTransaction() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir un montant pour ajouter la transaction")),
      );
      return;
    }

    if (_isDebit && (_selectedCategory == null || _selectedCategory!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une catégorie pour un débit.")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final amount = double.tryParse(_amountController.text.replaceAll(",", ".")) ?? 0.0;
      final notes = _notesController.text;
      final dateTransaction = _dateController.text.isNotEmpty ? DateFormat('yMd').parse(_dateController.text) : DateTime.now();
      final isRecurring = _isRecurring;

      List<String> newPhotos = [];
      for (File image in _photoFiles) {
        String? url = await uploadImage(image, user.uid);
        if (url != null) newPhotos.add(url);
      }

      final updatedPhotos = [..._existingPhotos, ...newPhotos];
      GeoPoint? geoPoint = _userLocation != null ? GeoPoint(_userLocation!.latitude, _userLocation!.longitude) : null;

      try {
        if (_isDebit) {
          final categoryId = await _getCategoryId(user.uid, _selectedCategory!, 'debit');
          if (widget.transaction != null) {
            await FirebaseFirestore.instance.collection("debits").doc(widget.transaction!.id).update({
              'amount': amount,
              'notes': notes,
              'date': Timestamp.fromDate(dateTransaction),
              'isRecurring': isRecurring,
              'photos': updatedPhotos,
              'location': geoPoint,
              'categorie_id': categoryId,
            });
          } else {
            await addDebitTransaction(
              userId: user.uid,
              categoryId: categoryId,
              date: dateTransaction,
              amount: amount,
              notes: notes,
              photos: updatedPhotos,
              location: geoPoint,
              isRecurring: isRecurring,
            );
          }
        } else {
          if (widget.transaction != null) {
            await FirebaseFirestore.instance.collection('credits').doc(widget.transaction!.id).update({
              'amount': amount,
              'notes': notes,
              'date': Timestamp.fromDate(dateTransaction),
              'isRecurring': isRecurring,
            });
          } else {
            await addCreditTransaction(
              userId: user.uid,
              date: dateTransaction,
              amount: amount,
              notes: notes,
              isRecurring: isRecurring,
            );
          }
        }

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.transaction == null ? "Transaction ajoutée" : "Transaction mise à jour")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
    }
  }


  Future<String> _getCategoryId(String userId, String categoryName, String type) async {
    final categoriesSnapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where("userId", isEqualTo: userId)
        .where("name", isEqualTo: categoryName)
        .where("type", isEqualTo: type)
        .limit(1)
        .get();

    if (categoriesSnapshot.docs.isNotEmpty) {
      return categoriesSnapshot.docs.first.id;
    } else {
      throw Exception("Catégorie non trouvée.");
    }
  }

  // Vérifier et créer la catégorie si elle n'existe pas
  Future<void> _checkAndCreateCategoryIfNeeded(String userId, String categoryName, String type) async {
    final categoriesSnapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where("userId", isEqualTo: userId)
        .where("name", isEqualTo: categoryName)
        .where("type", isEqualTo: type)
        .get();

    if (categoriesSnapshot.docs.isEmpty) {
      await createCategory(categoryName, userId, type);
      await _loadCategories(); // Recharger les catégories pour inclure la nouvelle catégorie
    }
  }

  /*
  Widget _buildAdditionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Afficher ces champs uniquement si la transaction est de type Débit (donc _isDebit est true)
        if (_isDebit)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Ajouter des reçus (2 max)"),
              ),
              Wrap(
                children: _photoFiles.map((image) {
                  return GestureDetector(
                    onTap: () {
                      _showImageOptionsDialog(image);
                    },
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photoFiles.remove(image);
                              });
                            },
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              DropdownButton<String>(
                focusNode: _categoryFocusNode,
                value: _selectedCategory,
                items: _categories.map((categoryName) {
                  return DropdownMenuItem<String>(
                    value: categoryName,
                    child: Text(categoryName),
                  );
                }).toList()
                  ..add(
                    const DropdownMenuItem<String>(
                      value: "Nouvelle catégorie",
                      child: Text("Créer une nouvelle catégorie"),
                    ),
                  ),
                onChanged: (newValue) {
                  if (newValue == 'Nouvelle catégorie') {
                    _createNewCategory();
                  } else {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
                hint: const Text("Sélectionner une catégorie."),
              ),
              if (_currentAdress != null) Text("Adresse : $_currentAdress"),
              _buildMap(),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text("Récupérer ma position actuelle"),
              ),
            ],
          ),
      ],
    );
  }*/


  Future<void> _pickImage() async {
    if (_photoFiles.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous ne pouvez ajourter que 2 reçus.")),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ajouter une image"),
          content: const Text("Choisissez une option"),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _selectImage(ImageSource.camera);
              },
              child: const Text("Prendre une photo"),
            ),TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _selectImage(ImageSource.gallery);
              },
              child: const Text("Depuis la galerie"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _photoFiles.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _replaceImage(File oldImage) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Remplacer l'image"),
          content: const Text("Choisissez une option"),
          actions: <Widget>[
            TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _selectNewImageForReplace(oldImage, ImageSource.camera);
                },
                child: const Text("Prendre une photo"),
            ),
            TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _selectNewImageForReplace(oldImage, ImageSource.gallery);
                },
                child: const Text("Depuis la galerie"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectNewImageForReplace(File oldImage, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _photoFiles[_photoFiles.indexOf(oldImage)] = File(pickedFile.path);
      });
    }
  }

  Future<void> _showImageOptionsDialog(File image) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Options de l'image"),
          content: Image.file(image, fit: BoxFit.cover),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  _photoFiles.remove(image);
                });
                Navigator.of(context).pop();
              },
              child: const Text("Supprimer"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _replaceImage(image);
              },
              child: const Text("Remplacer"),
            ),
          ],
        );
      },
    );
  }


  Widget _buildTransactionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAmountField(),
        const SizedBox(height: 16.0),
        _buildDateField(),
        const SizedBox(height: 16.0),
        _buildNotesField(),
        const SizedBox(height: 16.0),
        if (_isDebit) _buildAdditionalFields(),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: const InputDecoration(hintText: "Enter amount"),
    );
  }

  Widget _buildDateField() {
    return TextField(
      controller: _dateController,
      readOnly: true,
      onTap: _selectDate,
      decoration: const InputDecoration(
        hintText: "Select a date and time",
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      decoration: const InputDecoration(hintText: "Add notes"),
    );
  }

  Widget _buildAdditionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          focusNode: _categoryFocusNode,
          value: _categories.contains(_selectedCategory) ? _selectedCategory : null,
          items: _categories.map((categoryName) {
            return DropdownMenuItem<String>(
              value: categoryName,
              child: Text(categoryName),
            );
          }).toList()
            ..add(
              const DropdownMenuItem<String>(
                value: "New Category",
                child: Text("Create a new category"),
              ),
            ),
          onChanged: (newValue) {
            if (newValue == 'New Category') {
              _createNewCategory();
            } else {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
          hint: const Text("Select a category."),
        ),
        const SizedBox(height: 16),
        Text("Adresse: ${_currentAdress ?? 'Non spécifiée'}"),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _getCurrentLocation,
          child: const Text("Récupérer ma position actuelle"),
        ),
        const SizedBox(height: 10),
        _buildPhotosSection(), // Remplace la carte par la section des photos
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Reçus :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            ..._existingPhotos.map((url) => _buildPhotoWidget(url)),
            ..._photoFiles.map((file) => _buildPhotoWidget(file.path, isFile: true)),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text("Ajouter des reçus (2 max)"),
        ),
      ],
    );
  }

  Widget _buildPhotoWidget(String imagePath, {bool isFile = false}) {
    return Stack(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: isFile
              ? Image.file(
            File(imagePath),
            fit: BoxFit.cover,
          )
              : Image.network(
            imagePath,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error, color: Colors.red, size: 50));
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isFile) {
                  _photoFiles.removeWhere((file) => file.path == imagePath);
                } else {
                  _existingPhotos.remove(imagePath);
                }
              });
            },
            child: const Icon(Icons.close, color: Colors.red, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Type: "),
        const Text("Credit"),
        Switch(
          value: _isDebit,
          onChanged: (value) {
            setState(() {
              _isDebit = value;
              _categoriesLoaded = false;
              _loadCategories(); // Reload categories on type change
            });
          },
        ),
        const Text("Debit")
      ],
    );
  }

  Widget _buildRecurringSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Recurring"),
        Switch(
          value: _isRecurring,
          onChanged: (value) {
            setState(() {
              _isRecurring = value;
            });
          },
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Add Transaction' : 'Edit Transaction'),
      ),
      body: _categoriesLoaded
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSwitch(),
              const SizedBox(height: 16.0),
              _buildTransactionForm(),
              const SizedBox(height: 16.0),
              _buildRecurringSwitch(),
              _buildInvisibleMap(),
              Center(
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  child: Text(widget.transaction == null ? 'Add' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      )
          : const Center(child: CircularProgressIndicator()), // Loading indicator
    );
  }
}
