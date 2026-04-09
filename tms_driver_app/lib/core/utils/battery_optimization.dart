import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Request the system to ignore battery optimizations
Future<void> requestIgnoreBatteryOptimizations(BuildContext context) async {
  final status = await Permission.ignoreBatteryOptimizations.status;

  if (status.isDenied || status.isRestricted) {
    final result = await Permission.ignoreBatteryOptimizations.request();
    if (!result.isGranted) {
      _showBatteryDialog(context);
    }
  }
}

void _showBatteryDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Battery Optimization'),
      content: const Text(
        'To ensure background tracking works reliably, please allow the app to ignore battery optimization.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
