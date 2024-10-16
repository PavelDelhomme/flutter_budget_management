import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../navigation/custom_drawer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _defaultLocation = LatLng(48.8566, 2.3522); // Paris par défaut
  LatLng? _currentUserLocation;
  String _selectedTileLayer = 'OpenStreetMap'; // Choix du layer par défaut
  double _zoom = 16.0; // Niveau de zoom par défaut

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
        _mapController.move(_currentUserLocation!, _zoom);
      });
    } catch (e) {
      setState(() {
        _currentUserLocation = _defaultLocation;
      });
    }
  }

  Widget _buildTileLayer() {
    // Choix de la source de tuiles en fonction de l'option sélectionnée
    switch (_selectedTileLayer) {
      case 'OpenStreetMap':
        return TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.budget.budget_management',
        );
      case 'OpenLayers':
        return TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.budget.budget_management',
        );
      default:
        /*
        return TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.budget.budget_management',
        );*/
        return TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.budget.budget_management',
        );
    }
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(1.0, 18.0); // Limite le zoom de 1 à 18
      _mapController.move(_currentUserLocation ?? _defaultLocation, _zoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(1.0, 18.0); // Limite le zoom de 1 à 18
      _mapController.move(_currentUserLocation ?? _defaultLocation, _zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(activeItem: 'map'),
      appBar: AppBar(
        title: const Text("Carte"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTileLayer = value;
              });
            },
            itemBuilder: (BuildContext context) {
              return {'OpenStreetMap', 'OpenLayers'}
                  .map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentUserLocation ?? _defaultLocation,
              initialZoom: _zoom,
            ),
            children: [
              _buildTileLayer(),
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
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                  mini: true,
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                  mini: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
