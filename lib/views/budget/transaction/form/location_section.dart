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

      // Vérifier si la localisation a réellement changé
      if (widget.userLocation != null && _locationsAreEqual(newLocation, widget.userLocation!)) {
        log("La localisation récupérée est identique à l'ancienne. Aucun changement.");
        _newLocation = null;
      } else {
        _newLocation = newLocation;
        widget.onLocationUpdate(newLocation);
        widget.mapController.move(newLocation, widget.zoom);
        await _updateAddress(newLocation);
      }
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
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = "${place.street}, ${place.locality}, ${place.administrativeArea}";
        setState(() {
          _displayedAddress = address.isNotEmpty ? address : "Adresse non spécifiée";
        });
        widget.onAddressUpdate(address);
      } else {
        setState(() {
          _displayedAddress = "Adresse non spécifiée";
        });
      }
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

  /// Vérifie si deux localisations sont identiques
  bool _locationsAreEqual(LatLng location1, LatLng location2) {
    return location1.latitude == location2.latitude &&
        location1.longitude == location2.longitude;
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
  Widget build(BuildContext context) {
    final hasNewLocation = _newLocation != null &&
        (widget.userLocation == null || !_locationsAreEqual(_newLocation!, widget.userLocation!));

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
        if (hasNewLocation)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _newLocation = null;

                // Restaurer l'ancienne localisation
                widget.onLocationUpdate(widget.userLocation ?? widget.defaultLocation);

                // Restaurer l'ancienne adresse affichée
                _displayedAddress = widget.currentAddress;
              });
              log("Ancienne localisation restaurée : ${widget.userLocation}");
              log("Ancienne adresse restaurée : $_displayedAddress");
            },
            child: const Text("Garder l'ancienne localisation"),
          ),
        ElevatedButton(
          onPressed: () {
            // Définir la localisation pour Marseille
            LatLng marseilleLocation = LatLng(43.2965, 5.3698);
            setState(() {
              _newLocation = marseilleLocation;
              widget.onLocationUpdate(marseilleLocation);
              widget.mapController.move(marseilleLocation, widget.zoom);
            });
            _updateAddress(marseilleLocation);
            log("Localisation modifiée pour Marseille");
          },
          child: const Text("Modifier pour Marseille"),
        ),
        _buildInvisibleMap(),
      ],
    );
  }
}
