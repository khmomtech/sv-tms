import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/globals.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/services/topic_subscription_service.dart';

class FirebaseMessagingService {
  // ---- Channel constants (Android) ----
  static const String _alertsChannelId = 'sv_driver_notifications';
  static const String _alertsChannelName = 'SV Trucking – Alerts';
  static const String _alertsChannelDesc =
      'Dispatches, warnings, and important updates';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // iOS: show notifications while app is in foreground
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android 13+: ask for notification permission (via plugin, separate from FCM)
    await _requestPermissions();

    // Init local notifications + create loud channel on Android
    await _initLocalNotifications();
    await _ensureAndroidAlertsChannel();

    // Wire listeners + initial message
    await _registerListeners();
    await _handleInitialMessage();

    // Token sync + topics
    await _syncTokenWithBackend();
    await TopicSubscriptionService().subscribeToDynamicTopics();

    // Keep server up-to-date on token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('🔁 New FCM Token: $newToken');
      await _syncTokenWithBackend(newToken: newToken);
      await TopicSubscriptionService().resubscribe();
    });
  }

  Future<void> _requestPermissions() async {
    // FCM permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Android 13+ runtime permission via local notifications plugin
    final androidImpl =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload);
            _navigateFromPayload(data);
          } catch (e) {
            debugPrint('Payload parse error: $e');
          }
        }
      },
    );
  }

  /// Create a **high-importance** channel for loud alerts (sound + vibration).
  Future<void> _ensureAndroidAlertsChannel() async {
    final androidImpl =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    final existing = await androidImpl.getNotificationChannels() ??
        <AndroidNotificationChannel>[];
    final alreadyThere = existing.any((c) => c.id == _alertsChannelId);

    if (!alreadyThere) {
      final channel = const AndroidNotificationChannel(
        _alertsChannelId,
        _alertsChannelName,
        description: _alertsChannelDesc,
        importance: Importance.high, // heads-up
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await androidImpl.createNotificationChannel(channel);
      debugPrint('🔔 Created Android alerts channel: $_alertsChannelId');
    }
  }

  Future<void> _registerListeners() async {
    // Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
          '📩 FCM Foreground: ${message.notification?.title} | ${message.data}');
      await _showNotification(message);
    });

    // When user taps a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notification opened: ${message.data}');
      _navigateFromPayload(message.data);
    });
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🟢 App launched via FCM: ${initialMessage.data}');
      _navigateFromPayload(initialMessage.data);
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    // If server only sends data payload, still show a local notification
    final title = notification?.title ?? message.data['title'] ?? 'SV Trucking';
    final body = notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        '';

    const androidDetails = AndroidNotificationDetails(
      _alertsChannelId,
      _alertsChannelName,
      channelDescription: _alertsChannelDesc,
      importance: Importance.high, // heads-up
      priority: Priority.high, // pre-O behavior
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.message,
      styleInformation: BigTextStyleInformation(''),
      ticker: 'SV Trucking',
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _localNotifications.show(
        // unique-ish id so alerts don't overwrite each other
        DateTime.now().millisecondsSinceEpoch.remainder(0x7FFFFFFF),
        title,
        body,
        details,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('❗ Notification error: $e');
    }
  }

  Future<void> _syncTokenWithBackend({String? newToken}) async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null || apnsToken.isEmpty) {
          debugPrint('Token sync skipped: APNS token not ready yet.');
          return;
        }
      }

      final token = newToken ?? await _firebaseMessaging.getToken();
      debugPrint('Synced FCM Token: $token');

      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driverId');
      final authToken = await ApiConstants.getAccessToken();

      if (token != null && driverId != null && authToken != null) {
        final response = await http.post(
          Uri.parse(
              '${ApiConstants.baseUrl}/driver/update-device-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'driverId': driverId,
            'deviceToken': token,
          }),
        );
        debugPrint('🔁 Token sync response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Token sync error: $e');
    }
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) {
      debugPrint('Navigation context is null');
      return;
    }

    final type = data['type'];
    final referenceId = data['referenceId'];
    debugPrint('🔀 Navigating from notification: $type | $referenceId');

    switch (type) {
      case 'dispatch':
        Navigator.pushNamed(
          context,
          AppRoutes.dispatchDetail,
          arguments: {'dispatchId': referenceId},
        );
        break;
      case 'issue':
        Navigator.pushNamed(context, AppRoutes.reportIssueList);
        break;
      default:
        Navigator.pushNamed(context, AppRoutes.notifications);
    }
  }

  // ------ Topic helpers ------
  Future<void> subscribeToTopic(String topic) async =>
      _firebaseMessaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) async =>
      _firebaseMessaging.unsubscribeFromTopic(topic);

  Future<void> resubscribeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driverId');
    final zone = prefs.getString('driverZone');
    final vehicleType = prefs.getString('vehicleType');

    if (driverId != null) {
      await subscribeToTopic('driver-$driverId');
    }
    if (zone != null) {
      await subscribeToTopic('zone-${zone.toLowerCase()}');
    }
    if (vehicleType != null) {
      await subscribeToTopic('vehicle-${vehicleType.toLowerCase()}');
    }
    await subscribeToTopic('all-drivers');
  }
}
