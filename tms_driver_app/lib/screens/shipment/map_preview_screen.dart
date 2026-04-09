// Flutter MapPreviewScreen with custom route, distance, duration, and real-time tracking

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapPreviewScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String routeCode;

  const MapPreviewScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.routeCode,
  });

  @override
  State<MapPreviewScreen> createState() => _MapPreviewScreenState();
}

class _MapPreviewScreenState extends State<MapPreviewScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String _distance = '';
  String _duration = '';
  Timer? _driverTimer;
  LatLng? _driverLatLng;

  @override
  void initState() {
    super.initState();
    _setupMap();
    _startDriverLocationUpdates();
  }

  Future<void> _setupMap() async {
    await _getDirections();
    _addPickupDropMarkers();
  }

  Future<void> _getDirections() async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.pickupLat},${widget.pickupLng}&destination=${widget.dropoffLat},${widget.dropoffLng}&key=YOUR_GOOGLE_MAPS_API_KEY');

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final route = data['routes'][0];
      final polyline = route['overview_polyline']['points'];
      final distance = route['legs'][0]['distance']['text'];
      final duration = route['legs'][0]['duration']['text'];

      final decodedPoints = _decodePolyline(polyline);
      setState(() {
        _distance = distance;
        _duration = duration;
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 6,
            points: decodedPoints,
          )
        };
      });
    }
  }

  void _addPickupDropMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Location'),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(widget.dropoffLat, widget.dropoffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Drop-off Location'),
      ),
    };
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _startDriverLocationUpdates() {
    _driverTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      // Replace this with real-time WebSocket or API polling to get current driver location
      final simulatedLatLng = LatLng(
        widget.pickupLat + 0.01,
        widget.pickupLng + 0.01,
      );

      setState(() {
        _driverLatLng = simulatedLatLng;
        _markers.removeWhere((m) => m.markerId == const MarkerId('driver'));
        _markers.add(Marker(
          markerId: const MarkerId('driver'),
          position: simulatedLatLng,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Driver Location'),
        ));
      });
    });
  }

  @override
  void dispose() {
    _driverTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route: ${widget.routeCode}'),
        backgroundColor: const Color(0xFF2563eb),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    )
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('$_distance • $_duration'),
                    ],
                  ),
                  if (_driverLatLng != null) const Text('📍 Tracking Driver'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
