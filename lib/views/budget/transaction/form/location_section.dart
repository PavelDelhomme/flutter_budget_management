import 'package:flutter/material.dart';

class LocationSection extends StatelessWidget {
  final String? currentAddress;
  final VoidCallback onLocationUpdate;

  const LocationSection({
    Key? key,
    required this.currentAddress,
    required this.onLocationUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Adresse: ${currentAddress ?? 'Non spécifiée'}"),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onLocationUpdate,
          child: const Text("Récupérer ma position actuelle"),
        ),
      ],
    );
  }
}
