import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart'; // Pour la conversion des coordonnées en adresse

class TransactionDetailsModal extends StatelessWidget {
  final DocumentSnapshot transaction;

  const TransactionDetailsModal({Key? key, required this.transaction}) : super(key: key);

  Future<String> _getAddressFromLatLng(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      return placemarks.isNotEmpty ? placemarks.first.street ?? 'Adresse inconnue' : 'Adresse inconnue';
    } catch (e) {
      return 'Adresse inconnue';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupération des données de la transaction
    final data = transaction.data() as Map<String, dynamic>?;

    if (data == null) {
      return const Center(
        child: Text('Erreur : Aucune donnée disponible pour cette transaction.'),
      );
    }

    // Vérifie si la transaction est un débit ou un crédit
    final bool isDebit = transaction.reference.parent.id == 'debits';
    final amount = data['amount'] ?? 0.0;
    final date = DateFormat.yMMMMd().format((data['date'] as Timestamp).toDate());
    final notes = data['notes'] ?? '';
    final isRecurring = data['isRecurring'] ?? false;

    // Pour les débits, récupère les photos, la localisation et la catégorie
    final List<String> receiptUrls = isDebit && data.containsKey('photos')
        ? List<String>.from(data['photos'] ?? [])
        : [];

    final String? categoryId = isDebit ? data['categorie_id'] : null;
    final LatLng? location = data['localisation'] != null
        ? LatLng((data['localisation'] as GeoPoint).latitude, (data['localisation'] as GeoPoint).longitude)
        : null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Wrap(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Transaction du $date",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Montant : \$${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          if (categoryId != null) Text('Catégorie : $categoryId', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text('Notes : $notes', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text('Transaction récurrente : ${isRecurring ? 'Oui' : 'Non'}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),

          // Utilisation de FutureBuilder pour afficher l'adresse si la transaction est un débit
          if (location != null && isDebit)
            FutureBuilder<String>(
              future: _getAddressFromLatLng(location),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Chargement de l\'adresse...', style: TextStyle(fontSize: 18));
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Adresse inconnue', style: TextStyle(fontSize: 18));
                }
                return Text('Adresse : ${snapshot.data}', style: const TextStyle(fontSize: 18));
              },
            ),

          if (location != null && isDebit)
            SizedBox(
              height: 200,
              child: FlutterMap(
                mapController: MapController(),
                options: MapOptions(
                  initialCenter: location, // Utiliser initialCenter
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.budget.budget_management',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (receiptUrls.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Reçus :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: receiptUrls.map((url) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageScreen(imageUrl: url),
                          ),
                        );
                      },
                      child: SizedBox(
                        height: 100,
                        width: 100,
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error, color: Colors.red, size: 50));
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ImageScreen extends StatelessWidget {
  final String imageUrl;

  const ImageScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reçu"),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.error, color: Colors.red, size: 50),
            );
          },
        ),
      ),
    );
  }
}
