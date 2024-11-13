import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChange;
  final VoidCallback onCreateCategory;

  const CategoryDropdown({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChange,
    required this.onCreateCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: categories.contains(selectedCategory) ? selectedCategory : null,
      items: categories.map((categoryName) {
        return DropdownMenuItem<String>(
          value: categoryName,
          child: Text(categoryName),
        );
      }).toList()
        ..add(
          DropdownMenuItem<String>(
            value: "New Category",
            child: Text("Créer une nouvelle catégorie"),
          ),
        ),
      onChanged: (newValue) {
        if (newValue == 'New Category') {
          onCreateCategory();
        } else {
          onCategoryChange(newValue);
        }
      },
      hint: Text("Sélectionner une catégorie"),
    );
  }
}
