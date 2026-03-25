import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/globals.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/services/notification_action_handler.dart';
import 'package:tms_driver_app/services/topic_subscription_service.dart';

/// 📲 Enhanced Firebase Messaging Service
/// Implements production-ready notification handling with:
/// - Automatic FCM token refresh
/// - Notification action buttons (Accept/Reject)
/// - Background message handling (iOS-compatible)
/// - Notification categories with proper importance
/// - Token persistence and validation
class EnhancedFirebaseMessagingService {
  // ---- Notification Categories ----
  // HIGH: Heads-up notifications for urgent actions
  static const String _urgentChannelId = 'sv_driver_urgent';
  static const String _urgentChannelName = 'Urgent Alerts';
  static const String _urgentChannelDesc =
      'Critical dispatches and time-sensitive alerts';

  // DEFAULT: Normal priority for updates
  static const String _updatesChannelId = 'sv_driver_updates';
  static const String _updatesChannelName = 'Updates';
  static const String _updatesChannelDesc = 'General updates and notifications';

  // LOW: Background sync notifications
  static const String _backgroundChannelId = 'sv_driver_background';
  static const String _backgroundChannelName = 'Background Sync';
  static const String _backgroundChannelDesc =
      'Silent background updates and sync';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationActionHandler _actionHandler =
      NotificationActionHandler();

  static final EnhancedFirebaseMessagingService _instance =
      EnhancedFirebaseMessagingService._internal();
  factory EnhancedFirebaseMessagingService() => _instance;
  EnhancedFirebaseMessagingService._internal();

  bool _initialized = false;
  String? _currentToken;

  /// 🚀 Initialize FCM with all enhancements
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('📲 FCM already initialized');
      return;
    }
    _initialized = true;

    debugPrint('📲 Initializing Enhanced Firebase Messaging...');

    // iOS: show notifications while app is in foreground
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Request permissions
    await _requestPermissions();

    // Init local notifications + create channels
    await _initLocalNotifications();
    await _ensureAndroidChannels();

    // Initialize action handler with callbacks
    await _initializeActionHandler();

    // Wire listeners
    await _registerListeners();

    // Handle initial message (app opened via notification)
    await _handleInitialMessage();

    // Token management
    await _syncTokenWithBackend();

    // Subscribe to topics
    await TopicSubscriptionService().subscribeToDynamicTopics();

    // Monitor token refresh
    _monitorTokenRefresh();

    debugPrint('Enhanced Firebase Messaging initialized successfully');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // FCM permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // iOS: require explicit user action
      criticalAlert: false, // iOS: don't request critical alerts initially
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('User denied notification permissions');
    }

    // Android 13+ runtime permission via local notifications plugin
    final androidImpl =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    debugPrint('Android notification permission: $granted');
  }

  /// 🔔 Initialize local notifications
  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        await _actionHandler.handleNotificationResponse(response);
      },
      onDidReceiveBackgroundNotificationResponse:
          _backgroundNotificationHandler,
    );

    debugPrint('🔔 Local notifications initialized');
  }

  /// 📁 Create notification channels (Android 8+)
  Future<void> _ensureAndroidChannels() async {
    final androidImpl =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    // Urgent channel (heads-up)
    await androidImpl.createNotificationChannel(
      const AndroidNotificationChannel(
        _urgentChannelId,
        _urgentChannelName,
        description: _urgentChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF0000),
        showBadge: true,
      ),
    );

    // Updates channel (default)
    await androidImpl.createNotificationChannel(
      const AndroidNotificationChannel(
        _updatesChannelId,
        _updatesChannelName,
        description: _updatesChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // Background channel (silent)
    await androidImpl.createNotificationChannel(
      const AndroidNotificationChannel(
        _backgroundChannelId,
        _backgroundChannelName,
        description: _backgroundChannelDesc,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );

    debugPrint('📁 Created 3 Android notification channels');
  }

  /// 🎬 Initialize notification action handler
  Future<void> _initializeActionHandler() async {
    await _actionHandler.initialize(
      onAcceptJob: _handleAcceptJob,
      onRejectJob: _handleRejectJob,
      onViewDetails: _handleViewDetails,
      onMarkRead: _handleMarkRead,
    );
  }

  /// Register FCM message listeners
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

  /// 🟢 Handle initial message (app launched via notification)
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🟢 App launched via FCM: ${initialMessage.data}');
      _navigateFromPayload(initialMessage.data);
    }
  }

  /// 🔁 Monitor FCM token refresh
  void _monitorTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('🔁 FCM Token refreshed: ${newToken.substring(0, 20)}...');
      _currentToken = newToken;

      // Persist token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);

      // Sync with backend
      await _syncTokenWithBackend(newToken: newToken);

      // Resubscribe to topics with new token
      await TopicSubscriptionService().resubscribe();
    });
  }

  /// Sync FCM token with backend
  Future<void> _syncTokenWithBackend({String? newToken}) async {
    try {
      final token = newToken ?? await _firebaseMessaging.getToken();
      if (token == null) {
        debugPrint('FCM token is null, skipping sync');
        return;
      }

      _currentToken = token;

      // Persist locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);

      final driverId = prefs.getString('driverId');
      final authToken = await ApiConstants.getAccessToken();

      if (driverId != null && authToken != null) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/driver/update-device-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'driverId': driverId,
            'deviceToken': token,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          debugPrint('FCM token synced successfully');
        } else {
          debugPrint('Token sync failed: ${response.statusCode}');
        }
      } else {
        debugPrint('Missing driverId or auth token for FCM sync');
      }
    } catch (e) {
      debugPrint('Token sync error: $e');
    }
  }

  /// 🔔 Show notification with category-based styling
  Future<void> _showNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Extract fields
    final title = notification?.title ?? data['title'] ?? 'SV Trucking';
    final body =
        notification?.body ?? data['body'] ?? data['message'] ?? '';
    final type = data['type']?.toString() ?? 'general';
    final priority = data['priority']?.toString().toLowerCase() ?? 'normal';

    // Determine channel and importance
    final bool isUrgent = priority == 'high' ||
        type == 'dispatch' ||
        type == 'job_assigned' ||
        type == 'issue';

    final bool isSilent = priority == 'low' || type == 'background_sync';

    final channelId = isUrgent
        ? _urgentChannelId
        : (isSilent ? _backgroundChannelId : _updatesChannelId);

    final channelName = isUrgent
        ? _urgentChannelName
        : (isSilent ? _backgroundChannelName : _updatesChannelName);

    final channelDesc = isUrgent
        ? _urgentChannelDesc
        : (isSilent ? _backgroundChannelDesc : _updatesChannelDesc);

    // Create notification details with actions
    final androidDetails = _actionHandler.createAndroidDetailsWithActions(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDesc,
      notificationType: type,
      importance: isUrgent ? Importance.max : (isSilent ? Importance.low : Importance.high),
      priority: isUrgent ? Priority.high : (isSilent ? Priority.low : Priority.defaultPriority),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        // Use message ID hash for stable notification ID
        (message.messageId ?? DateTime.now().toIso8601String()).hashCode,
        title,
        body,
        details,
        payload: jsonEncode(data),
      );

      debugPrint('🔔 Notification shown: $title (channel: $channelId)');
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  // ======== Action Callbacks ========

  Future<void> _handleAcceptJob(
      String actionId, Map<String, dynamic> payload) async {
    debugPrint('Accepting job: ${payload['referenceId']}');

    try {
      final dispatchId = payload['referenceId'];
      if (dispatchId == null) return;

      final authToken = await ApiConstants.getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/dispatch/$dispatchId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Job accepted successfully');
        // Show success notification
        await _showLocalNotification(
          'Job Accepted',
          'You have accepted the dispatch assignment',
          isUrgent: false,
        );
      } else {
        debugPrint('Failed to accept job: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error accepting job: $e');
    }
  }

  Future<void> _handleRejectJob(
      String actionId, Map<String, dynamic> payload) async {
    debugPrint('Rejecting job: ${payload['referenceId']}');

    try {
      final dispatchId = payload['referenceId'];
      if (dispatchId == null) return;

      final authToken = await ApiConstants.getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/dispatch/$dispatchId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Job rejected successfully');
      }
    } catch (e) {
      debugPrint('Error rejecting job: $e');
    }
  }

  Future<void> _handleViewDetails(
      String actionId, Map<String, dynamic> payload) async {
    debugPrint('👁️ Viewing details: $payload');
    _navigateFromPayload(payload);
  }

  Future<void> _handleMarkRead(
      String actionId, Map<String, dynamic> payload) async {
    debugPrint('✔️ Marking as read: ${payload['notificationId']}');
    // Dismiss notification silently
  }

  // ======== Helpers ========

  void _navigateFromPayload(Map<String, dynamic> data) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;

    final type = data['type']?.toString().toLowerCase();
    final referenceId = data['referenceId']?.toString();

    switch (type) {
      case 'dispatch':
      case 'job_assigned':
        if (referenceId != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.dispatchDetail,
            arguments: {'dispatchId': referenceId},
          );
        }
        break;
      case 'issue':
        Navigator.pushNamed(context, AppRoutes.reportIssueList);
        break;
      case 'message':
        Navigator.pushNamed(context, AppRoutes.messages + '/chat');
        break;
      default:
        Navigator.pushNamed(context, AppRoutes.notifications);
    }
  }

  Future<void> _showLocalNotification(String title, String body,
      {bool isUrgent = false}) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isUrgent ? _urgentChannelId : _updatesChannelId,
          isUrgent ? _urgentChannelName : _updatesChannelName,
          importance: isUrgent ? Importance.max : Importance.high,
        ),
      ),
    );
  }

  // ======== Topic Management ========

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Get current FCM token
  Future<String?> getCurrentToken() async {
    return _currentToken ?? await _firebaseMessaging.getToken();
  }

  /// Force token refresh
  Future<void> forceTokenRefresh() async {
    try {
      await _firebaseMessaging.deleteToken();
      final newToken = await _firebaseMessaging.getToken();
      if (newToken != null) {
        await _syncTokenWithBackend(newToken: newToken);
      }
    } catch (e) {
      debugPrint('Error forcing token refresh: $e');
    }
  }
}

/// 🌙 Background notification handler (top-level function for iOS)
@pragma('vm:entry-point')
Future<void> _backgroundNotificationHandler(
    NotificationResponse response) async {
  debugPrint('🌙 Background notification handled: ${response.payload}');
  // Handle background notification tap
  await NotificationActionHandler().handleNotificationResponse(response);
}
