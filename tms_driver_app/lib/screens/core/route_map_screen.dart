//  Full Flutter Code for RouteMapScreen with Fixed Navigation & Realtime Tracking
import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
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
    final apiKey =
        'AIzaSyB4qSBWNEHfHj2zeKKicu5UsTBMcMPpq9Q'; // Replace with your real API Key

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${pickup.latitude},${pickup.longitude}&destination=${dropoff.latitude},${dropoff.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final points =
            _decodePolyline(data['routes'][0]['overview_polyline']['points']);
        final distance =
            data['routes'][0]['legs'][0]['distance']['text'] ?? '--';
        final duration =
            data['routes'][0]['legs'][0]['duration']['text'] ?? '--';
        setState(() {
          _distance = distance;
          _duration = duration;
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: points,
            ),
          };
          _markers = {
            Marker(
              markerId: const MarkerId('pickup'),
              position: pickup,
              infoWindow: const InfoWindow(title: 'Pickup Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
            Marker(
              markerId: const MarkerId('dropoff'),
              position: dropoff,
              infoWindow: const InfoWindow(title: 'Drop-off Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          };
        });
      }
    }
  }

  void _startRealtimeTracking() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final provider = Provider.of<DriverProvider>(context, listen: false);
      final position = provider.currentPosition;
      if (position != null) {
        final driverMarker = Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(position.latitude, position.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Driver'),
        );
        setState(() {
          _markers.removeWhere((m) => m.markerId.value == 'driver');
          _markers.add(driverMarker);
        });

        _mapController.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
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
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: initialPosition, zoom: 13),
            onMapCreated: (controller) => _mapController = controller,
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
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
