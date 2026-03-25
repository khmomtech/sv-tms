import 'package:flutter/material.dart';
import 'package:tms_driver_app/core/utils/location_permissions.dart';

class LocationGateScreen extends StatefulWidget {
  final Future<void> Function()
      onReady; // called when permission OK (start service here)
  const LocationGateScreen({super.key, required this.onReady});

  @override
  State<LocationGateScreen> createState() => _LocationGateScreenState();
}

class _LocationGateScreenState extends State<LocationGateScreen> {
  bool _busy = false;

  Future<void> _check() async {
    setState(() => _busy = true);
    final ok =
        await LocationPermissionGate.ensureBackgroundLocationAuthorized();
    setState(() => _busy = false);
    if (ok) await widget.onReady();
  }

  @override
  void initState() {
    super.initState();
    // Auto-check when screen opens (nice UX)
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enable Location')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
                'To update your live location in the background, please choose '
                '“Allow all the time”. This keeps dispatch updated even when the '
                'screen is off.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _busy ? null : _check,
              child: Text(_busy ? 'Checking…' : 'Enable background location'),
            ),
          ],
        ),
      ),
    );
  }
}
