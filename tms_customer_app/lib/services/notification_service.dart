import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Android notification channel used for all customer-facing notifications.
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'sv_tms_customer',
    'SV-TMS Notifications',
    description: 'Order status and delivery updates',
    importance: Importance.high,
  );

  /// Call once at app startup, after [Firebase.initializeApp()].
  ///
  /// [getToken]      — async callback that returns the current JWT access token
  /// [getCustomerId] — async callback that returns the logged-in customer's id
  Future<void> init({
    required Future<String?> Function() getToken,
    required Future<int?> Function() getCustomerId,
  }) async {
    if (_initialized) return;
    _initialized = true;

    // 1 — create Android notification channel (no-op on iOS / already exists)
    final androidImpl = _localNotifs.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_androidChannel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifs.initialize(initSettings);

    // 2 — request OS permission (iOS prompt; on Android 13+ triggers dialog)
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 3 — display foreground messages as local notifications
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      _localNotifs.show(
        message.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    });

    // 4 — push FCM token to backend now, and again whenever it rotates
    await _syncToken(getToken: getToken, getCustomerId: getCustomerId);
    messaging.onTokenRefresh.listen((_) async {
      await _syncToken(getToken: getToken, getCustomerId: getCustomerId);
    });
  }

  Future<void> _syncToken({
    required Future<String?> Function() getToken,
    required Future<int?> Function() getCustomerId,
  }) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      final authToken = await getToken();
      final customerId = await getCustomerId();
      if (authToken == null || customerId == null) return;

      final url = Uri.parse(
          '${ApiConstants.baseUrl}/api/customer/$customerId/device-token');
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'deviceToken': fcmToken}),
      );
      debugPrint('[FCM] Token sync → ${resp.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Token sync failed: $e');
    }
  }

  void dispose() {}
}
