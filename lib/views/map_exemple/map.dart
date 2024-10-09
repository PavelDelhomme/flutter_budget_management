import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';


class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentUserLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérification des services de localisation activé ou non
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // les service pas activer on ne fait rien on termine
      return;
    }

    // Demande des permission si ce n'est pas actuellement granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Les permissions n'ont pas été accorder on termine
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Les permission on été renié de façon permanente
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentUserLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(_currentUserLocation!, 16.0);
    });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: _currentUserLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentUserLocation!,
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
                point: _currentUserLocation!,
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.location_on,
                  size: 50,
                  color: Colors.blue,
                )
              ),
            ],
          )
        ],
      )
    );
  }
}