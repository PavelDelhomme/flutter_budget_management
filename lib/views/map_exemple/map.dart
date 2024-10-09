import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _defaultLocation = LatLng(48.8566, 2.3522); // Paris par défaut
  LatLng? _currentUserLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentUserLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentUserLocation!, 16.0);
      });
    } catch (e) {
      // En cas d'échec de récupération de la localisation, on garde la position par défaut
      setState(() {
        _currentUserLocation = _defaultLocation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte"),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentUserLocation ?? _defaultLocation,  // Utilisation de la position récupérée ou de Paris
          initialZoom: 16.0,
          onMapReady: () {
            // Action une fois la carte prête
            debugPrint("Carte prête !");
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.budget.budget_management',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentUserLocation ?? _defaultLocation,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  size: 50,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
