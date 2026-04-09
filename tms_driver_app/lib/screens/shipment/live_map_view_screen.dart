import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/settings_provider.dart';

class LiveMapViewScreen extends StatelessWidget {
  final LatLng currentLocation;
  final LatLng destination;
  final String etaText;

  const LiveMapViewScreen({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.etaText,
  });

  void _launchGoogleMapsNavigation() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${currentLocation.latitude},${currentLocation.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch Google Maps.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ផែនទីបញ្ជូន', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2563eb),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: currentLocation,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate: settingsProvider.mapTileUrlTemplate,
                    subdomains: const ['a', 'b', 'c'],
                    errorTileCallback: (tile, error, stackTrace) {
                      debugPrint('Failed to load tile: $error');
                    },
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: currentLocation,
                        child: const Icon(Icons.my_location,
                            color: Colors.blue, size: 32),
                      ),
                      Marker(
                        width: 40,
                        height: 40,
                        point: destination,
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 32),
                      ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [currentLocation, destination],
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ព័ត៌មានផ្លូវ',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 20),
                            const SizedBox(width: 8),
                            Text('អានម៉ោងដល់កំណត់៖ $etaText'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _launchGoogleMapsNavigation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon:
                              const Icon(Icons.navigation, color: Colors.white),
                          label: const Text('ចាប់ផ្តើមជើងដឹក',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
