import 'dart:developer';
import 'dart:io';
// Flutter
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
// Personnal dependencies
import 'package:budget_management/services/budget/add_transaction.dart';
import 'package:budget_management/services/image_service.dart';


class TransactionFormScreen extends StatefulWidget {
  final String? budgetId;
  final DocumentSnapshot? transaction;

  const TransactionFormScreen({Key? key, this.budgetId, this.transaction}) : super(key: key);

  @override
  _TransactionFormScreenState createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final FocusNode _categoryFocusNode = FocusNode();
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  double _allocatedAmount = 0.0;
  double _spentAmount = 0.0;
  double _remainingAmountForCategory = 0.0;
  bool _useSavings = false;
  bool _isRecurring = false;

  LatLng? _userLocation;
  List<File> _receiptImages = [];
  List<String> _existingReceiptUrls = [];

  // Pour la carte
  final MapController _mapController = MapController();
  LatLng _defaultLocation = LatLng(48.8566, 2.3522); // Paris par défaut
  String _selectedTileLayer = 'OpenStreetMap';
  double _zoom = 16.0;
  String? _currentAdress;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      _descriptionController.text = transaction['description'];
      _amountController.text = transaction['amount'].toString();
      _selectedCategory = transaction['category']?.toString().trim();
      _isRecurring = transaction['isRecurring'] ?? false;
      _dateController.text = DateFormat('yMd').format((transaction['date'] as Timestamp).toDate());

      _existingReceiptUrls = List<String>.from(transaction['receiptUrls'] ?? []);
      if (transaction['location'] != null) {
        GeoPoint location = transaction['location'];
        _userLocation = LatLng(location.latitude, location.longitude);
      }
    } else {
      _amountController.addListener(_updateRemainingAmountWithInput);
      _dateController.text = DateFormat('yMd').add_jm().format(DateTime.now());
      _getCurrentLocation(); // Récupération de la localisation actuel à l'initialisation
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Charger les catégories après que le context est complètement initialisé
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateRemainingAmountWithInput);
    _amountController.dispose();
    _categoryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      //Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_userLocation!, _zoom);
      });

      // Obtenir l'adresse à partir des coordonnées
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _currentAdress = placemarks.first.street;
      });
    } catch (e) {
      setState(() {
        _userLocation = _defaultLocation;
        _currentAdress = "Dresse inconnue";
      });
    }
  }
  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(1.0, 18.0);
      _mapController.move(_userLocation ?? _defaultLocation, _zoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(1.0, 18.0);
      _mapController.move(_userLocation ?? _defaultLocation, _zoom);
    });
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


  Future<void> _loadCategories() async {
    try {
      if (widget.budgetId != null) {
        final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(widget.budgetId).get();
        final List<dynamic> categories = budgetDoc.data()?['categories'] ?? [];

        setState(() {
          _categories = categories.map((category) {
            return {
              'name': (category['name'] as String).trim(),
              'allocatedAmount': category['allocatedAmount'],
              'spentAmount': category['spentAmount'],
            };
          }).toSet().toList();
          _isLoadingCategories = false;
        });
      } else {
        _isLoadingCategories = false;

        // Utiliser SchedulerBinding pour exécuter après le build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Budget non trouvé.")),
          );
        });
      }
    } catch (e) {
      _isLoadingCategories = false;
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors du chargement des catégories: $e")),
          );
          log("Erreur lors du chargement des catégories : $e");
        });
      }
    }
  }

  void _calculateRemainingAmount(String categoryName) {
    final selectedCategoryData = _categories.firstWhere(
          (category) => category['name'] == categoryName,
      orElse: () => {},
    );

    if (selectedCategoryData.isNotEmpty) {
      setState(() {
        _allocatedAmount = (selectedCategoryData['allocatedAmount'] as num?)?.toDouble() ?? 0.0;
        _spentAmount = (selectedCategoryData['spentAmount'] as num?)?.toDouble() ?? 0.0;
        _remainingAmountForCategory = _allocatedAmount - _spentAmount;

        _updateRemainingAmountWithInput();
      });
    }
  }

  void _updateRemainingAmountWithInput() {
    final inputAmount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _remainingAmountForCategory = _allocatedAmount - _spentAmount - inputAmount;
    });
  }

  Future<void> _saveTransaction() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && _descriptionController.text.isNotEmpty && _amountController.text.isNotEmpty && _selectedCategory != null) {
      // Convertir les virgules en points avant la sauvegarde
      String amountText = _amountController.text.replaceAll(",", ".");
      final amount = double.tryParse(amountText) ?? 0.0;

      final description = _descriptionController.text;
      final date = _dateController.text.isNotEmpty
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
        if (widget.transaction == null) {
          await addTransaction(
            description: description,
            amount: amount,
            categoryId: _selectedCategory!,
            budgetId: widget.budgetId!,
            useSavings: _useSavings,
            isRecurring: _isRecurring,
            //receiptUrls: receiptUrls.isNotEmpty ? receiptUrls.join(',') : null,
            receiptUrls: updatedReceiptUrls.isNotEmpty ? updatedReceiptUrls : null,
            location: _userLocation != null ? GeoPoint(_userLocation!.latitude, _userLocation!.longitude) : null,
          );
        } else {
          await FirebaseFirestore.instance.collection('transactions').doc(widget.transaction!.id).update({
            'description': description,
            'amount': amount,
            'category': _selectedCategory!,
            'isRecurring': _isRecurring,
            'receiptUrls': updatedReceiptUrls.isNotEmpty ? updatedReceiptUrls : null,
            'date': Timestamp.fromDate(date),
            'location': _userLocation != null ? GeoPoint(_userLocation!.latitude, _userLocation!.longitude) : null,
          });
        }
        if (mounted) {
          Navigator.pop(context);
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
    final allocatedAmountController = TextEditingController();

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
                TextField(
                  controller: allocatedAmountController,
                  decoration: const InputDecoration(labelText: "Montant alloué"),
                  keyboardType: TextInputType.number,
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
                onPressed: () {
                  final newCategory = {
                    'name': newCategoryNameController.text.trim(),
                    'allocatedAmount': double.tryParse(allocatedAmountController.text) ?? 0.0,
                    'spentAmount': 0.0,
                  };

                  setState(() {
                    _categories.add(newCategory); // Ajoute la nouvelle catégorie à la liste
                    _selectedCategory = newCategory['name'] as String?; // Sélectionne automatiquement la nouvelle catégorie
                  });

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

  void _convertCommaToDotInAmount() {
    String currentText = _amountController.text;
    _amountController.text = currentText.replaceAll(",", ".");
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
        child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView( // Ajout du scroll
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
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
                value: _categories.any((category) => category['name'] == _selectedCategory) ? _selectedCategory : null,
                items: _categories
                    .map((category) => category['name'])
                    .toSet() // Remove duplicates
                    .map((categoryName) {
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
                      if (_selectedCategory != null) {
                        _calculateRemainingAmount(_selectedCategory!);
                      }
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
              if (_receiptImages.isNotEmpty)
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
            ],
          ),
        ),
      ),
    );
  }

}
