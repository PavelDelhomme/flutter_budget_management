import 'dart:developer';
import 'dart:io';
// Flutter
import 'package:budget_management/views/budget/transaction/form/amount_field.dart';
import 'package:flutter/material.dart';
// Others
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Map
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';

import 'package:nominatim_geocoding/nominatim_geocoding.dart';

// My package
import '../../../services/budgets.dart';
import '../../../services/categories.dart';
import '../../../services/transactions.dart';
import '../../../services/image_service.dart';
import 'form/category_dropdown.dart';
import 'form/date_field.dart';
import 'form/location_section.dart';
import 'form/photos_section.dart';
import 'form/type_switch.dart';
import 'form/recurring_switch.dart';
import 'form/notes_field.dart';


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

  // Images
  final List<File> _photoFiles = [];
  List<String> _existingPhotos = [];

  // Map
  LatLng? _userLocation;
  final MapController _mapController = MapController();
  final LatLng _defaultLocation = const LatLng(48.8566, 2.3522); // Defaut paris
  String? _currentAdress;
  final double _zoom = 16.0;

  bool _isLoading = false;

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

      if (_isDebit) {
        _existingPhotos = List<String>.from(transaction['photos'] ?? []);

        // Localisation, uniquement pour les débits
        // Vérifier si les données existent et si le champ "location" est présent
        final data = transaction.data() as Map<String, dynamic>?; // Cast explicite en Map
        if (data != null && data.containsKey('location')) {
          final GeoPoint location = data['location'] as GeoPoint;
          _userLocation = LatLng(location.latitude, location.longitude);
        } else {
          _userLocation = _defaultLocation; // Valeur par défaut si "location" n'existe pas
        }

        // Assurez-vous que _selectedCategory est défini uniquement pour les débits
        _selectedCategory = transaction['categorie_id']?.toString().trim();
      }

    } else {
      _dateController.text = DateFormat('yMd').add_jm().format(DateTime.now());
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
        _categoriesLoaded = true;

        // Définir la catégorie sélectionnée pour les transactions de type débit seulement
        if (_isDebit && widget.transaction != null) {
          final categoryId = widget.transaction!['categorie_id']?.toString();
          if (categoryId != null && _categories.contains(categoryId)) {
            _selectedCategory = categoryId;
          } else if (_categories.isNotEmpty) {
            _selectedCategory = _categories[0];
          }
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories[0]; // Par défaut pour une nouvelle transaction
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

  void _updateLocation(LatLng location) {
    setState(() {
      _userLocation = location;
    });
  }

  void _updateAddress(String? address) {
    setState(() {
      _currentAdress = address;
    });
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
                  await CategoryService().createCategory(categoryController.text.trim(), user.uid, type);

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


  Future<void> _pickImage() async {
    if (_photoFiles.length + _existingPhotos.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous ne pouvez ajourter que 2 reçus.")),
      );
      return;
    }

    final XFile? pickedFile = await ImageService().showImageSourceDialog(context);

    if (pickedFile != null) {
      setState(() {
        _photoFiles.add(File(pickedFile.path));
      });
    }
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

    setState(() {
      _isLoading = true; // Début du chargement
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final amount = double.tryParse(_amountController.text.replaceAll(",", ".")) ?? 0.0;
      final notes = _notesController.text;
      final dateTransaction = _dateController.text.isNotEmpty ? DateFormat('yMd').parse(_dateController.text) : DateTime.now();
      final isRecurring = _isRecurring;

      List<String> newPhotos = [];
      for (File image in _photoFiles) {
        String? url = await ImageService().uploadImage(image);
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
            await TransactionService().addDebitTransaction(
              budgetService: BudgetService(),
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
            await TransactionService().addCreditTransaction(
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
      } finally {
        _isLoading = false;
      }
    }
  }

  Widget _buildTypeSwitch() {
    return TypeSwitch(
      isDebit: _isDebit,
      isTransactionExisting: widget.transaction != null,
      onTypeChange: (value) {
        setState(() {
          _isDebit = value;
          _categoriesLoaded = false;
          _loadCategories();
        });
      },
    );
  }
  Widget _buildRecurringSwitch() {
    return RecurringSwitch(
      isRecurring: _isRecurring,
      onRecurringChange: (value) {
        setState(() {
          _isRecurring = value;
        });
      },
    );
  }

  Widget _buildAdditionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryDropdown(
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategoryChange: (value) {
            setState(() => _selectedCategory = value);
          },
          onCreateCategory: _createNewCategory,
        ),
        const SizedBox(height: 16),
        LocationSection(
          defaultLocation: _defaultLocation,
          mapController: _mapController,
          zoom: _zoom,
          currentAddress: _currentAdress,
          userLocation: _userLocation,
          onLocationUpdate: _updateLocation,
          onAddressUpdate: _updateAddress,
          allowUserCurrentLocation: widget.transaction == null,
        ),
        const SizedBox(height: 16),
        PhotosSection(
          photoFiles: _photoFiles,
          existingPhotos: _existingPhotos,
          onAddPhoto: _pickImage,
          onRemovePhoto: (imagePath) {
            setState(() {
              if (_photoFiles.any((file) => file.path == imagePath)) {
                _photoFiles.removeWhere((file) => file.path == imagePath);
              } else {
                _existingPhotos.remove(imagePath);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTransactionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountField(amountController: _amountController),
        const SizedBox(height: 16.0),
        DateField(dateController: _dateController),
        const SizedBox(height: 16.0),
        NotesField(notesController: _notesController),
        const SizedBox(height: 16.0),
        if (_isDebit) _buildAdditionalFields(),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Ajouter Transaction' : 'Modifier Transaction'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categoriesLoaded
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSwitch(),
              const SizedBox(height: 16.0),
              _buildRecurringSwitch(),
              const SizedBox(height: 16.0),
              _buildTransactionForm(),
              const SizedBox(height: 16.0),
              Center(
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  child: Text(widget.transaction == null ? 'Ajouter' : 'Modifier'),
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
