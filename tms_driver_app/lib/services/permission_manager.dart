// 📁 lib/services/permission_manager.dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionManager {
  
  /// Request location permissions with Android 13+ optimization
  Future<bool> requestLocationPermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidLocationPermissions();
    } else if (Platform.isIOS) {
      return await _requestIOSLocationPermissions();
    }
    return false;
  }
  
  Future<bool> _requestAndroidLocationPermissions() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final androidVersion = androidInfo.version.sdkInt;
    
    print('📱 Android version: $androidVersion');
    
    // Step 1: Request foreground location (always first)
    print('Requesting foreground location permission...');
    final fgStatus = await Permission.locationWhenInUse.request();
    if (!fgStatus.isGranted) {
      print('Foreground location permission denied');
      return false;
    }
    print('Foreground location granted');
    
    // Step 2: Request background location (if foreground granted)
    // Android 10+ requires this as separate request
    if (androidVersion >= 29) {
      print('Requesting background location permission (Android 10+)...');
      
      // Show rationale first (optional - implement in UI layer)
      await Future.delayed(Duration(milliseconds: 500));
      
      final bgStatus = await Permission.locationAlways.request();
      if (!bgStatus.isGranted) {
        print('Background location not granted - app will work but tracking stops when backgrounded');
        // Don't fail completely - foreground location is still useful
      } else {
        print('Background location granted');
      }
    }
    
    // Step 3: Request notification permission (Android 13+)
    if (androidVersion >= 33) {
      print('Requesting notification permission (Android 13+)...');
      final notifStatus = await Permission.notification.request();
      if (!notifStatus.isGranted) {
        print('Notification permission not granted');
      } else {
        print('Notification permission granted');
      }
    }
    
    return true;
  }
  
  Future<bool> _requestIOSLocationPermissions() async {
    print('Requesting iOS location permissions...');
    
    // Request when-in-use first
    final whenInUseStatus = await Permission.locationWhenInUse.request();
    if (!whenInUseStatus.isGranted) {
      print('iOS location permission denied');
      return false;
    }
    print('iOS when-in-use location granted');
    
    // Request always (background) permission
    print('Requesting iOS always permission...');
    final alwaysStatus = await Permission.locationAlways.request();
    if (!alwaysStatus.isGranted) {
      print('iOS always permission not granted - background tracking limited');
    } else {
      print('iOS always permission granted');
    }
    
    return true;
  }
  
  /// Check if all required permissions are granted
  Future<bool> hasAllRequiredPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final androidVersion = androidInfo.version.sdkInt;
      
      final fgLocation = await Permission.locationWhenInUse.isGranted;
      if (!fgLocation) return false;
      
      // Background location required for production on Android 10+
      if (androidVersion >= 29) {
        final bgLocation = await Permission.locationAlways.isGranted;
        if (!bgLocation) return false;
      }
      
      return true;
    } else if (Platform.isIOS) {
      // For iOS, check both when-in-use and always
      final whenInUse = await Permission.locationWhenInUse.isGranted;
      final always = await Permission.locationAlways.isGranted;
      
      return whenInUse || always; // Either is acceptable
    }
    
    return false;
  }
  
  /// Check background location permission status
  Future<bool> hasBackgroundLocationPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 29) {
        return await Permission.locationAlways.isGranted;
      }
      // Pre-Android 10, background is included with foreground
      return await Permission.locationWhenInUse.isGranted;
    } else if (Platform.isIOS) {
      return await Permission.locationAlways.isGranted;
    }
    return false;
  }
  
  /// Check notification permission (Android 13+)
  Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.notification.isGranted;
      }
      // Pre-Android 13, notifications don't need runtime permission
      return true;
    }
    // iOS notification permissions handled separately via firebase_messaging
    return true;
  }
  
  /// Open app settings for manual permission grant
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
  
  /// Get detailed permission status
  Future<Map<String, PermissionStatus>> getDetailedPermissionStatus() async {
    final Map<String, PermissionStatus> status = {};
    
    status['locationWhenInUse'] = await Permission.locationWhenInUse.status;
    status['locationAlways'] = await Permission.locationAlways.status;
    
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        status['notification'] = await Permission.notification.status;
      }
    }
    
    return status;
  }
}
