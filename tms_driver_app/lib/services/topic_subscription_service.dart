import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopicSubscriptionService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static bool _apnsWarningShown = false;

  Future<bool> _isTopicOpsAvailable() async {
    if (!Platform.isIOS) return true;
    try {
      final apns = await _firebaseMessaging.getAPNSToken();
      final ready = apns != null && apns.isNotEmpty;
      if (!ready) {
        if (!_apnsWarningShown) {
          debugPrint('FCM topics skipped: APNS token not ready yet.');
          _apnsWarningShown = true;
        }
        return false;
      }
      _apnsWarningShown = false;
      return true;
    } catch (_) {
      return false;
    }
  }

  String? _sanitizeTopic(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // Allowed: [a-zA-Z0-9-_.~%]
    final buf = StringBuffer();
    for (final codeUnit in trimmed.codeUnits) {
      final ch = String.fromCharCode(codeUnit);
      final isAllowed = RegExp(r'[a-zA-Z0-9\-\_\.\~%]').hasMatch(ch);
      if (isAllowed) {
        buf.write(ch);
      } else if (ch.trim().isEmpty) {
        buf.write('-');
      } else {
        buf.write('-');
      }
    }
    var topic = buf.toString();
    // Collapse repeated '-' and trim
    topic = topic.replaceAll(RegExp(r'-{2,}'), '-');
    topic = topic.replaceAll(RegExp(r'^-+|-+$'), '');
    if (topic.isEmpty) return null;
    return topic.length > 900 ? topic.substring(0, 900) : topic;
  }

  ///  Subscribe to dynamic topics: driver ID, zone, vehicle type, etc.
  Future<void> subscribeToDynamicTopics() async {
    try {
      if (!await _isTopicOpsAvailable()) return;
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driverId')?.trim();
      final zone = prefs.getString('driverZone')?.toLowerCase().trim();
      final vehicleType = prefs.getString('vehicleType')?.toLowerCase().trim();

      if (driverId != null && driverId.isNotEmpty) {
        final topic = _sanitizeTopic('driver-$driverId');
        if (topic != null) {
          await _firebaseMessaging.subscribeToTopic(topic);
          debugPrint(' Subscribed to: $topic');
        }
      }

      if (zone != null && zone.isNotEmpty) {
        final topic = _sanitizeTopic('zone-$zone');
        if (topic != null) {
          await _firebaseMessaging.subscribeToTopic(topic);
          debugPrint(' Subscribed to: $topic');
        }
      }

      if (vehicleType != null && vehicleType.isNotEmpty) {
        final topic = _sanitizeTopic('vehicle-$vehicleType');
        if (topic != null) {
          await _firebaseMessaging.subscribeToTopic(topic);
          debugPrint(' Subscribed to: $topic');
        }
      }

      final allDrivers = _sanitizeTopic('all-drivers');
      if (allDrivers != null) {
        await _firebaseMessaging.subscribeToTopic(allDrivers);
        debugPrint(' Subscribed to: $allDrivers');
      }
    } catch (e) {
      debugPrint(' Error subscribing to topics: $e');
    }
  }

  /// 🚫 Unsubscribe from all known topics
  Future<void> unsubscribeFromAllTopics() async {
    try {
      if (!await _isTopicOpsAvailable()) return;
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driverId')?.trim();
      final zone = prefs.getString('driverZone')?.toLowerCase().trim();
      final vehicleType = prefs.getString('vehicleType')?.toLowerCase().trim();

      if (driverId != null && driverId.isNotEmpty) {
        final topic = _sanitizeTopic('driver-$driverId');
        if (topic != null) {
          await _firebaseMessaging.unsubscribeFromTopic(topic);
          debugPrint('🚫 Unsubscribed from: $topic');
        }
      }

      if (zone != null && zone.isNotEmpty) {
        final topic = _sanitizeTopic('zone-$zone');
        if (topic != null) {
          await _firebaseMessaging.unsubscribeFromTopic(topic);
          debugPrint('🚫 Unsubscribed from: $topic');
        }
      }

      if (vehicleType != null && vehicleType.isNotEmpty) {
        final topic = _sanitizeTopic('vehicle-$vehicleType');
        if (topic != null) {
          await _firebaseMessaging.unsubscribeFromTopic(topic);
          debugPrint('🚫 Unsubscribed from: $topic');
        }
      }

      final allDrivers = _sanitizeTopic('all-drivers');
      if (allDrivers != null) {
        await _firebaseMessaging.unsubscribeFromTopic(allDrivers);
        debugPrint('🚫 Unsubscribed from: $allDrivers');
      }
    } catch (e) {
      debugPrint(' Error unsubscribing from topics: $e');
    }
  }

  ///  Refresh all subscriptions (unsubscribe + subscribe)
  Future<void> resubscribe() async {
    debugPrint(' Re-subscribing to all FCM topics...');
    try {
      await unsubscribeFromAllTopics();
      await subscribeToDynamicTopics();
    } catch (e) {
      debugPrint(' Error during re-subscription: $e');
    }
  }
}
