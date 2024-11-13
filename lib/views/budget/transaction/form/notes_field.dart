import 'package:flutter/material.dart';

class NotesField extends StatelessWidget {
  final TextEditingController notesController;

  const NotesField({Key? key, required this.notesController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: notesController,
      decoration: const InputDecoration(hintText: "Ajouter des notes"),
    );
  }
}
