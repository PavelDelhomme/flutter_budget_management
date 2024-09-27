import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';



class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  @override Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          child: FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              backgroundColor: Colors.green,
              initialCenter: LatLng(48.11618809738349, -1.665820539550782),
              //RENNES -> TODO: get user location + mapbox credits
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.budget.budget_management',
              ),
              const MarkerLayer(
                markers: [
                  Marker(
                      point: LatLng(48.11618809738349, -1.665820539550782),
                      child: Icon(
                          Icons.location_on, size: 50, color: Colors.yellow),
                      width: 25,
                      height: 25
                  )
                ],
              )
            ],
          ),
        )
    );
  }
}