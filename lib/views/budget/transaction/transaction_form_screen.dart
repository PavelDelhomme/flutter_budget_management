import 'dart:io';

import 'package:budget_management/services/budget/add_transaction.dart';
import 'package:budget_management/services/image_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';  // Pour formater les dates

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
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  double _allocatedAmount = 0.0; // Montant alloué à la catégorie
  double _spentAmount = 0.0; // Montant déjà dépensé dans la catégorie
  double _remainingAmountForCategory = 0.0;  // Montant restant dans la catégorie
  bool _useSavings = false;
  bool _isRecurring = false;
  List<File> _receiptImages = [];


  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      _descriptionController.text = transaction['description'];
      _amountController.text = transaction['amount'].toString();
      _selectedCategory = transaction['category'];
      _isRecurring = transaction['isRecurring'] ?? false;
      _dateController.text = DateFormat('yMd').format((transaction['date'] as Timestamp).toDate());
      if (transaction['receiptUrl'] != null) {
        _receiptImages = [File(transaction['receiptUrl'])];
      }
    } else {
      _amountController.addListener(_updateRemainingAmountWithInput);
      _dateController.text = DateFormat('yMd').add_jm().format(DateTime.now());
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateRemainingAmountWithInput);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      if (widget.budgetId != null) {
        final budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(widget.budgetId).get();
        final List<dynamic> categories = budgetDoc.data()?['categories'] ?? [];

        setState(() {
          _categories = categories.map((category) => category as Map<String, dynamic>).toList();
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _isLoadingCategories = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Budget non trouvé.")),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des catégories: $e")),
      );
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

        // Recalculer le montant restant en fonction du montant actuel de la transaction
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
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final description = _descriptionController.text;
      final date = DateTime.tryParse(_dateController.text) ?? DateTime.now();
      String? receiptUrl;

  }

  Future<void> _addTransaction() async {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final date = DateTime.tryParse(_dateController.text) ?? DateTime.now();

      // Affichage d'un indicateur de progression pendant l'ajout
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Uploader chaque image et récupérer les URLs
      List<String> receiptUrls = [];
      for (File image in _receiptImages) {
        String? receiptUrl = await uploadImage(image, user.uid);
        if (receiptUrl != null) {
          receiptUrls.add(receiptUrl);
        }
      }

      //bool isRecurring = false;  // À ajuster en fonction de la logique utilisateur (par exemple, via un checkbox)

      String? selectedSavingCategory;  // Ajouter une option pour la catégorie d'économies

      if (_useSavings) {
        // Logique pour sélectionner la catégorie d'économies
        selectedSavingCategory = await _selectSavingCategory();
      }

      try {
        await addTransaction(
          description: _descriptionController.text,
          amount: amount,
          categoryId: _selectedCategory!,
          budgetId: widget.budgetId!,
          useSavings: _useSavings,
          isRecurring: _isRecurring,
          savingCategoryId: selectedSavingCategory,  // Passer la catégorie d'économies sélectionnée
          receiptUrl: receiptUrls.isNotEmpty ? receiptUrls.join(',') : null,
        );

        Navigator.pop(context); // Fermeture du loader
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction ajoutée avec succès.")),
        );
        Navigator.pop(context); // Retourne à l'écran précèdent
      } catch (e) {
        Navigator.pop(context); // Fermeture du loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${e.toString()}")),
        );
      }
    }
  }

  void _openAddPhotoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Prendre une photo"),
                onTap: () async {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choisir depuis la galerie"),
                onTap: () async {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _receiptImages.add(File(pickedFile.path));
      });
    }
  }

  Future<String?> _selectSavingCategory() async {
    // Logique pour afficher une boîte de dialogue permettant à l'utilisateur de choisir la catégorie d'économies
    final selectedCategory = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisissez une catégorie d\'économies'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _categories.map((category) {
              return ListTile(
                title: Text(category['name']),
                onTap: () {
                  Navigator.pop(context, category['id']);
                },
              );
            }).toList(),
          ),
        );
      },
    );
    return selectedCategory;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Montant'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date'), // Todo Ajouter automatiquement le jour actuel comme date
              keyboardType: TextInputType.datetime,
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
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['name'],
                  child: Text(category['name']),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue;
                  if (_selectedCategory != null) {
                    _calculateRemainingAmount(_selectedCategory!);
                  }
                });
              },
              hint: const Text('Sélectionner une catégorie'),
            ),
            if (_selectedCategory != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  'Montant restant dans la catégorie: \$${_remainingAmountForCategory.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: _remainingAmountForCategory < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            CheckboxListTile(
              title: const Text("Transaction récurrente"),
              value: _isRecurring,
              onChanged: (bool? value) {
                setState(() {
                  _isRecurring = value ?? false;
                });
              },
            ),
            const SizedBox(height: 10),
            
            // Affichage des apercus des images
            if (_receiptImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: _receiptImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Image.file(_receiptImages[index], fit: BoxFit.cover),
                      Positioned(
                        right: -10,
                        top: -10,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _receiptImages.removeAt(index);
                            });
                          },
                        ),
                      )
                    ],
                  );
                },
              ),
            ElevatedButton(
                onPressed: () => _openAddPhotoModal(context),
                child: const Text("Ajouter une photo de reçu"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addTransaction,
              child: const Text('Ajouter la transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
