import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('battery_optimization');

  static Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableBatteryOptimization');
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('⚡ Battery optimization opt-out failed: $e');
    } on MissingPluginException catch (e) {
      if (kDebugMode) debugPrint('⚡ Battery optimization channel missing (native not wired?): $e');
    }
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true; // non-Android: treat as OK
    try {
      final isIgnoring =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimization');
      return isIgnoring ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('⚡ Failed to check battery optimization: $e');
      return false;
    } on MissingPluginException catch (e) {
      if (kDebugMode) debugPrint('⚡ Battery optimization channel missing (native not wired?): $e');
      return false;
    }
  }
}
