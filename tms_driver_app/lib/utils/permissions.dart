import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  static Future<void> checkAndRequest(
      GlobalKey<NavigatorState> navigatorKey) async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();

    final isAnyDenied = statuses.values
        .any((status) => status.isDenied || status.isPermanentlyDenied);

    if (isAnyDenied) {
      _showPermissionDialog(navigatorKey);
    }
  }

  static void _showPermissionDialog(GlobalKey<NavigatorState> navigatorKey) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Permissions Required'),
        content:
            const Text('Please grant Location and Notification permissions.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          )
        ],
      ),
    );
  }
}
