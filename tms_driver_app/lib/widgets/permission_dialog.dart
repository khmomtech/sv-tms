import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> showPermissionDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Permission Required'),
      content: const Text(
          'This app needs location and notification permissions to work properly.'),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}
