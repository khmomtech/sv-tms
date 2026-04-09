import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  GoogleMapController? _mapController;
  Marker? _driverMarker;
  LatLng? _lastPosition;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DriverProvider>(context);
    final position = provider.currentPosition;

    if (position == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentLatLng = LatLng(position.latitude, position.longitude);

    // Animate camera and marker only if location changed
    if (_lastPosition != null && _lastPosition != currentLatLng) {
      _animateToPosition(currentLatLng);
    }

    _lastPosition = currentLatLng;

    _driverMarker = Marker(
      markerId: const MarkerId('driver'),
      position: currentLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Driver', snippet: 'Live Location'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Live Location'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: currentLatLng, zoom: 16),
        markers: {_driverMarker!},
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_mapController != null) {
            _mapController!
                .animateCamera(CameraUpdate.newLatLng(currentLatLng));
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _animateToPosition(LatLng target) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLng(target));
    }
  }
}
