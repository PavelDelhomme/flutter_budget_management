import 'dart:developer';
import 'dart:io';
// Flutter
import 'package:budget_management/models/good_models.dart';
import 'package:budget_management/utils/generate_ids.dart';
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
// Personnal dependencies
import 'package:budget_management/services/budget/add_transaction.dart';
import 'package:budget_management/services/image_service.dart';
import 'package:nominatim_geocoding/nominatim_geocoding.dart';

import '../../../services/permissions_service.dart';


class TransactionFormScreen extends StatefulWidget {
  final DocumentSnapshot? transaction;

  const TransactionFormScreen({Key? key, this.transaction}) : super(key: key);

  @override
  _TransactionFormScreenState createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  // Categories
  String? _selectedCategory;
  List<String> _categories = [];
  final FocusNode _categoryFocusNode = FocusNode();
  // Transaction
  late bool _typeTransactionController = false; // true = début, false = crédit
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isRecurring = false;
  LatLng? _userLocation;
  List<File> _receiptImages = [];
  List<String> _existingReceiptUrls = [];
  // Map
  final MapController _mapController = MapController();
  LatLng _defaultLocation = LatLng(48.8566, 2.3522); // Defaut paris
  String? _currentAdress;
  double _zoom = 16.0;


  // TODO ajouter bouton croix pour supprimer photo
  // TODO possibilité de rentrer l'adresse manuellement

  // TODO api pour rechercher les adresses :
  // TODO si il récupère une liste d'adresse la mettre en cache pour éviter de redemander continuellement les données
  // TODO masquer la carte pour le moment car non nécessaire
  // TODO champs de recherche pour entrer son adresse manuellement
  // TODO icone position localisation

  @override
  void initState() {
    super.initState();
    Get.put(NominatimGeocoding());

    _loadCategories(); // Charger les catégories existantes
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      log("Transaction reçue : ${transaction.data()}");

      _typeTransactionController = transaction['type'] ?? false;
      _notesController.text = transaction['notes'] ?? '';
      _amountController.text = transaction['amount']?.toString() ?? '';
      _selectedCategory = transaction['category']?.toString().trim();
      _isRecurring = transaction['isRecurring'] ?? false;

      // Vérification de la date
      final Timestamp? date = transaction['date'] as Timestamp?;
      if (date != null) {
        _dateController.text = DateFormat('yMd').format(date.toDate());
      } else {
        _dateController.text = DateFormat('yMd').format(DateTime.now());
      }

      // Initialisation des reçus existants
      _existingReceiptUrls = List<String>.from(transaction['receiptUrls'] ?? []);

      // Localisation
      final GeoPoint? location = transaction['location'] as GeoPoint?;
      if (location != null) {
        _userLocation = LatLng(location.latitude, location.longitude);
      } else {
        // Valeur par défaut si la localisation est absente
        _userLocation = _defaultLocation;
      }
    } else {
      // Nouvelle transaction : initialisez avec les valeurs par défaut
      //_amountController.addListener(_updateRemainingAmountWithInput);
      _dateController.text = DateFormat('yMd').add_jm().format(DateTime.now());
      _getCurrentLocation(); // Récupérer la localisation actuelle
    }
  }

  Future<void> _loadCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where("userId", isEqualTo: user.uid)
          .get();
      setState(() {
        _categories = categoriesSnapshot.docs.map((doc) => doc['name'].toString()).toSet().toList();
      });
    }
  }

  /*@override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Charger les catégories après que le context est complètement initialisé
    _loadCategories();
  }*/

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
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_userLocation!, _zoom);
      });

      // Utilisation de Nominatim pour obtenir l'adresse via un Coordinate
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        Placemark place = placemarks.first;

        setState(() {
          _currentAdress = "${place.street}, ${place.locality}, ${place.administrativeArea}";
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
      subdomains: ['a', 'b', 'c'],
      userAgentPackageName: 'com.budget.budget_management',
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


  Future<void> _saveTransaction() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && _notesController.text.isNotEmpty && _amountController.text.isNotEmpty && _selectedCategory != null) {
      final typeTransaction = _typeTransactionController;

      // Convertir les virgules en points avant la sauvegarde
      final amount = double.tryParse(_amountController.text.replaceAll(",", ".")) ?? 0.0;

      final notes = _notesController.text;
      final dateTransaction = _dateController.text.isNotEmpty
          ? DateFormat('yMd').parse(_dateController.text)
          : DateTime.now();

      List<String> newReceiptUrls = [];
      for (File image in _receiptImages) {
        String? url = await uploadImage(image, user.uid);
        if (url != null) {
          newReceiptUrls.add(url);
        }
      }

      // Fusionner les images existantes et nouvelles
      List<String> updatedReceiptUrls = [..._existingReceiptUrls, ...newReceiptUrls];

      try {
        // Création de l'objet UserTransaction
        UserTransaction userTransaction = UserTransaction(
          id: generateTransactionId(),
          type: typeTransaction,
          categorie_id: _selectedCategory!,
          user_id: user.uid,
          date: dateTransaction,
          notes: notes,
          isRemaining: _isRecurring,
        );

        if (widget.transaction == null) {
          // Ajout d'une nouvelle transaction
          await addTransaction(
            type: typeTransaction,
            userTransaction: userTransaction,
            amount: amount,
            localisation: _userLocation,
            photos: updatedReceiptUrls.isNotEmpty ? updatedReceiptUrls : null,
          );
        } else {
          // Mettre à jour la transaction existante
          await FirebaseFirestore.instance.collection('transactions').doc(widget.transaction!.id).update({
            'type_transaction': typeTransaction,
            'amount': amount,
            'category': _selectedCategory!,
            'date': Timestamp.fromDate(dateTransaction),
            'notes': notes,
            'isRecurring': _isRecurring,
            'receiptUrls': updatedReceiptUrls.isNotEmpty ? updatedReceiptUrls : null,
            'location': _userLocation != null ? GeoPoint(_userLocation!.latitude, _userLocation!.longitude) : null,
          });
        }

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.transaction == null ? "Transaction ajoutée" : "Transaction mise à jour")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e")),
        );
      }
    }
  }
  void _createNewCategory() async {
    final newCategoryNameController = TextEditingController();

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Nouvelle catégorie"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newCategoryNameController,
                  decoration: const InputDecoration(labelText: "Nom de la catégorie"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Annuler"),
              ),
              TextButton(
                onPressed: () async {
                  final newCategoryName = newCategoryNameController.text.trim();

                  // Empêcher les doublons
                  if (newCategoryName.isNotEmpty && !_categories.contains(newCategoryName)) {
                    // Ajouter dans Firestore et mettre à jour localement
                    await FirebaseFirestore.instance.collection("categories").add({'name': newCategoryName});
                    setState(() {
                      _categories.add(newCategoryName);
                      _selectedCategory = newCategoryName;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("La catégorie existe déjà ou est invalide.")),
                    );
                  }

                  Navigator.of(context).pop();
                },
                child: const Text("Ajouter"),
              ),
            ],
          );
        }
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _receiptImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  // Méthode pour supprimer une image existante
  void _removeExistingImage(String url) {
    setState(() {
      _existingReceiptUrls.remove(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Ajouter une transaction' : 'Modifier la transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Ajout du scroll
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Description'),
                textInputAction: TextInputAction.next,
                onEditingComplete: () {
                  FocusScope.of(context).nextFocus();
                },
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Montant', hintText: 'Entrez le montant'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(_categoryFocusNode);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date'),
                keyboardType: TextInputType.datetime,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                },
                onTap: () async {
                  DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (selectedDate != null) {
                    _dateController.text = DateFormat.yMd().format(selectedDate);
                  }
                },
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
                    DropdownMenuItem<String>(
                      value: 'New',
                      child: const Text("Créer une nouvelle catégorie"),
                    ),
                  ),
                onChanged: (newValue) {
                  if (newValue == 'New') {
                    _createNewCategory();
                  } else {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
                hint: const Text("Sélectionner une catégorie"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImages,
                child: const Text("Ajouter des reçus"),
              ),
              const SizedBox(height: 20),

              // Affichage des images existantes
              if (_existingReceiptUrls.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Reçus existants :", style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: _existingReceiptUrls.map((url) {
                        return Stack(
                          children: [
                            Image.network(
                              url,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _removeExistingImage(url);
                                },
                              ),
                            )
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // Affichage des nouvelles images ajoutées
              if (_receiptImages.isNotEmpty) //todo ajouter la petites croix pour supprimer le recu l'image
                //todo limite de 3 image
                Wrap(
                  spacing: 8,
                  children: _receiptImages.map((image) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        image,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 20),

              // Affichage de l'adresse
              if (_currentAdress != null)
                Text(
                  "Adresse : $_currentAdress",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              // todo affichage saisie de l'adrese avec proposition automatique via API
              // todo Liste des propositions
              //todo Icon(Icons.my_location); pour récuéprer localisationn utilisateur

              // Intégration de la carte dans le formulaire
              _buildMap(),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text("Récupérer ma position actuelle"),
              ),

              const SizedBox(height: 20),
              CheckboxListTile(
                title: const Text("Transaction récurrente"),
                value: _isRecurring,
                onChanged: (newValue) {
                  setState(() {
                    _isRecurring = newValue ?? false;
                  });
                },
              ),
              Center(
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    child: Text(widget.transaction == null ? 'Ajouter la transaction' : 'Mettre à jour la transaction'),
                  )
              ),
              //todo après ajout de la transaction il faut mettre a jour la liste des transactions du coup quand même enfaite
            ],
          ),
        ),
      ),
    );
  }
}
