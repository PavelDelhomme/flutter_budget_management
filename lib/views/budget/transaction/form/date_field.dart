import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateField extends StatelessWidget {
  final TextEditingController dateController;

  const DateField({Key? key, required this.dateController}) : super(key: key);

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(initialDate.year - 1),
      lastDate: DateTime(initialDate.year + 1),
    );

    if (selectedDate != null) {
      dateController.text = DateFormat('EEEE d MMMM y', 'fr_FR').format(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: dateController,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: const InputDecoration(
        hintText: "Sélectionner la date",
      ),
    );
  }
}
