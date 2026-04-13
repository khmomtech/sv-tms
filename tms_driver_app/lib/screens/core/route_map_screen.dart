//  Full Flutter Code for RouteMapScreen with Fixed Navigation & Realtime Tracking
import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';

class RouteMapScreen extends StatefulWidget {
  final LatLng pickup;
  final LatLng dropoff;

  const RouteMapScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _polylinePoints = [];
  List<Marker> _markers = [];
  String _distance = '--';
  String _duration = '--';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _checkLocationPermission();
      await _loadRoute();
      _startRealtimeTracking();
    });
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('permissions.location_required_title'.tr()),
              content:
                  Text('permissions.map_permission_message'.tr()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ok'.tr()),
                )
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _loadRoute() async {
    final pickup = widget.pickup;
    final dropoff = widget.dropoff;
    // Use OSRM public API for routing (no API key required)
    final url =
        'https://router.project-osrm.org/route/v1/driving/${pickup.longitude},${pickup.latitude};${dropoff.longitude},${dropoff.latitude}?overview=full&geometries=polyline&steps=false';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final points = _decodePolyline(route['geometry']);
        final distance = route['distance'] != null
            ? (route['distance'] / 1000).toStringAsFixed(2) + ' km'
            : '--';
        final duration = route['duration'] != null
            ? (route['duration'] / 60).toStringAsFixed(0) + ' min'
            : '--';
        setState(() {
          _polylinePoints = points;
          _distance = distance;
          _duration = duration;
          _markers = [
            Marker(
              width: 40,
              height: 40,
              point: pickup,
              child: const Icon(Icons.location_on, color: Colors.blue, size: 36),
            ),
            Marker(
              width: 40,
              height: 40,
              point: dropoff,
              child: const Icon(Icons.flag, color: Colors.red, size: 36),
            ),
          ];
        });
      }
    }
  }

  void _startRealtimeTracking() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final provider = Provider.of<DriverProvider>(context, listen: false);
      final position = provider.currentPosition;
      if (position != null) {
        final driverLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          // Remove any previous driver marker
          _markers.removeWhere((m) => m.key == const ValueKey('driver_marker'));
          _markers.add(
            Marker(
              key: const ValueKey('driver_marker'),
              width: 40,
              height: 40,
              point: driverLatLng,
              child: const Icon(Icons.directions_car, color: Colors.green, size: 36),
            ),
          );
        });
        // Optionally move map to driver
        _mapController.move(driverLatLng, _mapController.zoom);
      }
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    // Polyline decoding for OSRM (same as Google)
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;
      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.pickup.latitude == 0.0
        ? const LatLng(11.5564, 104.9282) // Phnom Penh fallback
        : widget.pickup;

    return Scaffold(
      appBar: AppBar(title: const Text('Map Route')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: initialPosition,
              zoom: 13,
              maxZoom: 18,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.svtrucking.tms_driver_app',
              ),
              if (_polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polylinePoints,
                      color: Colors.blue,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Distance: $_distance',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('ETA: $_duration',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
