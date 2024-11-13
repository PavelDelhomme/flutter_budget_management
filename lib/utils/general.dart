import 'dart:math';

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

/// Calcule la date du mois suivant, en tenant compte des années et de la fin du mois.
DateTime calculateNewDate(DateTime originalDate) {
  int year = originalDate.year;
  int month = originalDate.month + 1;

  if (month > 12) {
    month = 1;
    year++;
  }

  int day = originalDate.day;
  int lastDayOfMonth = DateTime(year, month + 1, 0).day;

  if (day > lastDayOfMonth) {
    day = lastDayOfMonth;
  }

  return DateTime(year, month, day);
}
