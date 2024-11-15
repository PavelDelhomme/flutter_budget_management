import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSection extends StatefulWidget {
  final LatLng defaultLocation;
  final MapController mapController;
  final double zoom;
  final String? currentAddress;
  final LatLng? userLocation;
  final ValueChanged<LatLng> onLocationUpdate;
  final ValueChanged<String?> onAddressUpdate;
  final bool allowUserCurrentLocation;

  const LocationSection({
    Key? key,
    required this.defaultLocation,
    required this.mapController,
    required this.zoom,
    required this.onLocationUpdate,
    required this.onAddressUpdate,
    this.currentAddress,
    this.userLocation,
    this.allowUserCurrentLocation = false,
  }) : super(key: key);

  @override
  _LocationSectionState createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  String? _displayedAddress;
  bool _isLoadingAddress = false;
  LatLng? _newLocation;

  @override
  void initState() {
    super.initState();
    if (widget.currentAddress != null) {
      _displayedAddress = widget.currentAddress;
    } else if (widget.userLocation != null) {
      _updateAddress(widget.userLocation!);
    } else if (widget.allowUserCurrentLocation) {
      _getCurrentLocation();
    }
  }



  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      await _checkLocationPermissions();
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      _newLocation = newLocation;

      setState(() {
        widget.onLocationUpdate(newLocation);
        widget.mapController.move(newLocation, widget.zoom);
      });

      await _updateAddress(newLocation);
    } catch (e) {
      log("Erreur lors de la récupération de la localisation : $e");
      setState(() {
        _displayedAddress = "Adresse inconnue";
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _updateAddress(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      Placemark place = placemarks.first;
      String address = "${place.street}, ${place.locality}, ${place.administrativeArea}";
      setState(() {
        _displayedAddress = address;
      });
      widget.onAddressUpdate(address);
    } catch (e) {
      log("Erreur lors de la récupération de l'adresse : $e");
      setState(() {
        _displayedAddress = "Adresse inconnue";
      });
    }
  }

  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }


  Widget _buildInvisibleMap() {
    return SizedBox(
      height: 0,
      width: 0,
      child: FlutterMap(
        mapController: widget.mapController,
        options: MapOptions(
          initialCenter: widget.userLocation ?? widget.defaultLocation,
          initialZoom: widget.zoom,
        ),
        children: [
          _buildTileLayer(),
        ],
      ),
    );
  }

  Widget _buildTileLayer() {
    return TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: 'com.budget.budget_management',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isLoadingAddress
            ? const CircularProgressIndicator()
            : Text("Adresse: ${_displayedAddress ?? 'Non spécifiée'}"),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _getCurrentLocation,
          child: const Text("Récupérer la nouvelle localisation"),
        ),
        if (_newLocation != null)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _newLocation = null;
                _displayedAddress = widget.currentAddress;
              });
            },
            child: const Text("Garder l'ancienne localisation"),
          ),
        _buildInvisibleMap(),
      ],
    );
  }
}
