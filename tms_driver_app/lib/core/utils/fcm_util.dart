import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/providers/user_provider.dart';

class FCMUtil {
  static Future<void> syncTokenToBackend(
      BuildContext context, UserProvider userProvider,
      {Function(bool success)? onResult}) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || userProvider.userId == null) {
        debugPrint(' FCM or userId is null.');
        onResult?.call(false);
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/driver/update-device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userProvider.accessToken}',
        },
        body: jsonEncode({
          'driverId': userProvider.userId,
          'deviceToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint(' FCM token synced.');
        onResult?.call(true);
      } else {
        debugPrint(' Failed to sync FCM token: ${response.body}');
        onResult?.call(false);
      }
    } catch (e) {
      debugPrint(' Error syncing FCM token: $e');
      onResult?.call(false);
    }
  }
}
