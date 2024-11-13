import 'package:flutter/material.dart';

class DateField extends StatelessWidget {
  final TextEditingController dateController;
  final VoidCallback onDateTap;

  const DateField({Key? key, required this.dateController, required this.onDateTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: dateController,
      readOnly: true,
      onTap: onDateTap,
      decoration: const InputDecoration(
        hintText: "Sélectionner la date",
      ),
    );
  }
}
