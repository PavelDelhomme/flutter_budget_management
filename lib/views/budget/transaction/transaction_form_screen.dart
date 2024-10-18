import 'dart:developer';
import 'dart:io';
// Flutter
import 'package:budget_management/models/good_models.dart';
import 'package:budget_management/utils/categories.dart';
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

import 'package:nominatim_geocoding/nominatim_geocoding.dart';

import '../../../utils/budgets.dart';
import '../../../services/utils_services/image_service.dart';
import '../../../services/utils_services/permissions_service.dart';
import '../../../utils/transactions.dart';


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
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isRecurring = false;
  bool _isDebit = false;
  LatLng? _userLocation;
  List<File> _receiptImages = [];
  List<String> _existingReceiptUrls = [];

  // Map
  final MapController _mapController = MapController();
  LatLng _defaultLocation = LatLng(48.8566, 2.3522); // Defaut paris
  String? _currentAdress;
  double _zoom = 16.0;

  @override
  void initState() {
    super.initState();
    Get.put(NominatimGeocoding());

    _loadCategories(); // Charger les catégories existantes
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      log("Transaction reçue : ${transaction.data()}");

      _isDebit = transaction['type'] ?? true;
      _notesController.text = transaction['notes'] ?? '';
      _amountController.text = transaction['amount']?.toString() ?? '';
      _selectedCategory = transaction['category']?.toString().trim();
      _isRecurring = transaction['isRecurring'] ?? false;
      final Timestamp? date = transaction['date'] as Timestamp?;
      _dateController.text = date != null ? DateFormat('yMd').format(date.toDate()) : DateFormat('yMd').format(DateTime.now());

      // Initialisation des reçus existants
      _existingReceiptUrls = List<String>.from(transaction['receiptUrls'] ?? []);
      // Localisation, uniquement pour les débits
      if (_isDebit) {
        final GeoPoint? location = transaction['location'] as GeoPoint?;
        _userLocation = location != null ? LatLng(location.latitude, location.longitude) : _defaultLocation;
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
          .where("type", isEqualTo: _isDebit ? 'debit' : 'credit')  // Charger en fonction du type (débit ou crédit)
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


  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year - 1),
      lastDate: DateTime(initialDate.year + 1),
    );

    if (selectedDate != null) {
      TimeOfDay? selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (selectedTime != null) {
        DateTime finalDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        setState(() {
          _dateController.text = DateFormat('yMd').add_jm().format(finalDateTime);
        });
      }
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

  Future<String> _getOrCreateBudgetId(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final budgetSnapshot = await FirebaseFirestore.instance
          .collection("budgets")
          .where('user_id', isEqualTo: user.uid)
          .where("month", isEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, 1)))
          .where('year', isEqualTo: Timestamp.fromDate(DateTime(date.year, 1, 1)))
          .get();

      if (budgetSnapshot.docs.isNotEmpty) {
        return budgetSnapshot.docs.first.id;
      } else {
        await createBudget(userId: user.uid, date: date);
        final newBudgetSnapshot = await FirebaseFirestore.instance
            .collection('budgets')
            .where('user_id', isEqualTo: user.uid)
            .where("month", isEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, 1)))
            .where('year', isEqualTo: Timestamp.fromDate(DateTime(date.year, 1, 1)))
            .get();
        return newBudgetSnapshot.docs.first.id;
      }
    }
    throw Exception("Impossible d'obtenir ou de créer le budget.");
  }

  Future<void> _saveTransaction() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && _amountController.text.isNotEmpty) {
      final amount = double.tryParse(_amountController.text.replaceAll(",", ".")) ?? 0.0;
      final notes = _notesController.text;
      final dateTransaction = _dateController.text.isNotEmpty ? DateFormat('yMd').parse(_dateController.text) : DateTime.now();
      final isReccuring = _isRecurring;

      List<String> newReceiptUrls = [];
      for (File image in _receiptImages) {
        String? url = await uploadImage(image, user.uid);
        if (url != null) {
          newReceiptUrls.add(url);
        }
      }

      // Fusionner les images existantes et nouvelles
      List<String> updatedReceiptUrls = [..._existingReceiptUrls, ...newReceiptUrls];

      // Conversion de la localisation
      GeoPoint? geoPoint;
      if (_userLocation != null) {
        geoPoint = GeoPoint(_userLocation!.latitude, _userLocation!.longitude);
      }

      try {
        String budgetId = await _getOrCreateBudgetId(dateTransaction);

        if (_isDebit) {
          await addDebitTransaction(
            budgetId: budgetId,
            categoryId: _selectedCategory!,
            userId: user.uid,
            date: dateTransaction,
            amount: amount,
            notes: notes,
            receiptUrls: updatedReceiptUrls,
            location: geoPoint,
            isRecurring: isReccuring,
          );
        } else {
          await addCreditTransaction(
            budgetId: budgetId,
            userId: user.uid,
            date: dateTransaction,
            amount: amount,
            notes: notes,
            isRecurring: isReccuring,
          );
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

  Widget _buildAdditionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Afficher ces champs uniquement si la transaction est de type Débit (donc _isDebit est true)
        if (_isDebit)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      value: "Nouvelle catégorie",
                      child: const Text("Créer une nouvelle catégorie"),
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
              ElevatedButton(
                  onPressed: _pickImage, child: const Text("Ajouter des reçus")),
              if (_receiptImages.isNotEmpty)
                Wrap(
                  children: _receiptImages.map((image) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                    );
                  }).toList(),
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
  }


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _receiptImages.add(File(pickedFile.path));
      });
    }
  }

  Widget _buildTransactionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Montant"),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (value) {
            _amountController.text = value.replaceAll(",", ".");
            _amountController.selection = TextSelection.fromPosition(
              TextPosition(offset: _amountController.text.length),
            );
          },
          decoration: const InputDecoration(hintText: "Saisissez le montant"),
        ),
        const SizedBox(height: 16.0),
        const Text("Date de la transaction"),
        TextField(
          controller: _dateController,
          readOnly: true,
          onTap: _selectDate,
          decoration: const InputDecoration(
            hintText: "Sélectionner une date et une heure",
          ),
        ),
        const SizedBox(height: 16.0),
        const Text("Notes"),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(hintText: "Ajouter des notes"),
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Récurrent"),
            Switch(
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
          ],
        ),
        _buildAdditionalFields(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Ajouter une transaction'
            : 'Modifier la transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Ajout du scroll
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Crédit"),
                  Switch(
                    value: _isDebit,
                    onChanged: (value) {
                      setState(() {
                        _isDebit = value;
                        _loadCategories();  // Recharger les catégories lorsque le type change
                      });
                    },
                  ),
                  const Text("Débit")
                ],
              ),

              // afficher un formulaire en fonction du type
              _buildTransactionForm(),
              // Bouton pour enregistrer la transaction
              Center(
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  child: Text(
                      widget.transaction == null ? 'Ajouter' : 'Mettre à jour'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
