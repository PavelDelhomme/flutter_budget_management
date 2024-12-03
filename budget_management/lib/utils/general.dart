import 'package:flutter/material.dart';

Widget? checkSnapshot(AsyncSnapshot snapshot, {String errorMessage = "Erreur lors du chargement des données"}) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  if (snapshot.hasError) {
    return Center(child: Text(errorMessage));
  }

  if (!snapshot.hasData || snapshot.data == null) {
    return const Center(child: Text("Aucune donnée disponible."));
  }

  return null;
}
