import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

Future<void> checkLocationServices(BuildContext ctx) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text("Les services de localisation sont désactivés. Veuillez les activer pour utiliser cette fonctionnalité.")),
    );
    return;
  }
}

Future<void> checkLocationPermission(BuildContext ctx) async {
  LocationPermission permission;

  // Vérification de si la permission est déjà accordée
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      log("Erreur: Permission de localisation refusée.");
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text("Vous devez accorder la permission de localisation pour utiliser cette fonctionnalité.")),
      );
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    log("Erreur: Permission de localisation refusée en permanence.");
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text("Permission de localisation refusée de manière permanente. Veuillez activer la permission dans les paramètres.")),
    );
    return;
  }

}