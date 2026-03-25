import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionGate {
  /// Ensure location services are ON and app has “Allow all the time”.
  /// Returns true when everything is good to start LocationService.kt
  static Future<bool> ensureBackgroundLocationAuthorized() async {
    // 0) Are location services enabled (GPS)?
    final servicesEnabled = await Geolocator.isLocationServiceEnabled();
    if (!servicesEnabled) {
      // Try to nudge the user
      await Geolocator.openLocationSettings();
      // Give the OS time; user may come back later—recheck next time.
      return false;
    }

    // 1) Ask for "While in use" first (required by Android policy)
    final whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted) {
      final res = await Permission.locationWhenInUse.request();
      if (!res.isGranted) {
        // If permanently denied, send to app settings
        if (res.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
    }

    // 2) Then ask for "Always" (background). iOS uses same call but you only care about Android.
    // On Android 11+ this may bounce the user to Settings; permission_handler handles as best as OS allows.
    var always = await Permission.locationAlways.status;
    if (!always.isGranted) {
      final res = await Permission.locationAlways.request();
      always = res;
      if (!always.isGranted) {
        // If user selected “Allow only while using the app”
        // we must guide them to Settings → “Allow all the time”.
        if (always.isPermanentlyDenied || always.isDenied) {
          await openAppSettings();
        }
        return false;
      }
    }

    // 3) Optional: double-check background via Geolocator (some OEMs are quirky)
    if (Platform.isAndroid) {
      final bgOk = await _androidBackgroundOk();
      if (!bgOk) {
        // As a last resort: open app settings again
        await openAppSettings();
        return false;
      }
    }

    return true;
  }

  static Future<bool> _androidBackgroundOk() async {
    // There’s no perfect API; we trust permission_handler result.
    // You could add extra heuristics here if needed.
    return (await Permission.locationAlways.status).isGranted;
  }
}
