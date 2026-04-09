// 📁 lib/utils/notification_helper.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Channel IDs — MUST match AndroidManifest & native service constants.
const String alertsChannelId   = 'sv_driver_alerts';         // HIGH  (heads-up)
const String updatesChannelId  = 'sv_driver_notifications';  // DEFAULT (quiet)
const String callChannelId     = 'sv_driver_call';            // MAX   (ringtone + full-screen)

/// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Optional: app-level handler to navigate when a notification is tapped
typedef NotificationTapHandler = void Function(Map<String, dynamic> data);
NotificationTapHandler? _onTap;

/// Allow app to register a tap handler (call once in main)
void setOnNotificationTapHandler(NotificationTapHandler handler) {
  _onTap = handler;
}

class NotificationHelper {
  /// Internal init guards (idempotent & concurrency-safe)
  static bool _initialized = false;
  static Completer<void>? _initCompleter;

  /// 🚨 High-importance channel (sound + heads-up)
  static const AndroidNotificationChannel _alertsChannel =
      AndroidNotificationChannel(
    alertsChannelId,
    'Smart Truck Driver Alerts',
    description: 'Urgent driver alerts (dispatch assignments, issues).',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// 📣 Default-importance channel (quiet updates)
  static const AndroidNotificationChannel _updatesChannel =
      AndroidNotificationChannel(
    updatesChannelId,
    'Smart Truck Driver Notifications',
    description: 'General notifications and background updates.',
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// 📲 Initialize local notifications and channels.
  /// Safe to call many times; concurrent calls will await the same work.
  static Future<void> initialize() async {
    if (_initialized) return;
    if (_initCompleter != null) {
      // Another caller is currently initializing; just await it.
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    try {
      // Basic platform init
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _handleNotificationTapBg,
      );

      // Ask push permission (iOS; no-op on Android pre-13)
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {
        // Non-fatal; ignore
      }

      if (Platform.isAndroid) {
        final androidImpl = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        // Android 13+ shows a runtime permission dialog
        try {
          await androidImpl?.requestNotificationsPermission();
        } catch (_) {
          // Older devices / impls; ignore
        }

        // Ensure channels exist (creating again is a no-op)
        await _ensureChannels(androidImpl);
      }

      _initialized = true;
      _initCompleter!.complete();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('NotificationHelper.initialize error: $e\n$st');
      }
      // Silence the completer's rejected future so it doesn't become an unhandled Zone error.
      _initCompleter!.future.ignore();
      _initCompleter!.completeError(e, st);
    } finally {
      // In case of errors, next call can retry (reset only if not initialized)
      if (!_initialized) _initCompleter = null;
    }
  }

  /// Creates/updates channels idempotently and verifies importance levels.
  static Future<void> _ensureChannels(
      AndroidFlutterLocalNotificationsPlugin? androidImpl) async {
    if (androidImpl == null) return;

    // Create or update channels. Re-creating is idempotent in Android 8+,
    // but importance cannot be lowered once created by the system UI.
    // So we always create both with correct IDs that match native.
    await androidImpl.createNotificationChannel(_alertsChannel);
    await androidImpl.createNotificationChannel(_updatesChannel);

    // Optional sanity check: list channels in debug
    if (kDebugMode) {
      try {
        final channels = await androidImpl.getNotificationChannels();
        final names =
            channels?.map((c) => '${c.id}:${c.importance}').join(', ');
        debugPrint('[🔔] Existing channels: $names');
      } catch (_) {}
    }
  }

  /// ☎️ Dedicated call channel (max importance, ringtone-like urgency)
  static const AndroidNotificationChannel _callChannel =
      AndroidNotificationChannel(
    callChannelId,
    'Incoming Calls',
    description: 'Incoming voice/video calls from dispatch.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const int _kCallNotificationId = 0xCA11;

  /// ☎️ Show an incoming-call heads-up notification from the background isolate.
  /// The [payload] is stored so the tap handler can restore call state.
  static Future<void> showCallNotification({
    required String callerName,
    required String channelName,
    String? payload,
  }) async {
    await _ensureReady();

    // Ensure call channel exists (idempotent)
    if (Platform.isAndroid) {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(_callChannel);
    }

    final androidDetails = AndroidNotificationDetails(
      _callChannel.id,
      _callChannel.name,
      channelDescription: _callChannel.description,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      ongoing: true,        // keeps notification pinned until dismissed
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.call,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'answer_call',
          'Answer',
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'decline_call',
          'Decline',
          cancelNotification: true,
        ),
      ],
      styleInformation: const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await flutterLocalNotificationsPlugin.show(
      _kCallNotificationId, // fixed ID so a second call replaces the first
      '📞 Incoming call',
      callerName.isNotEmpty ? 'Call from $callerName' : 'Incoming call from Dispatch',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Cancel the call notification (call answered/declined).
  static Future<void> cancelCallNotification() async {
    await flutterLocalNotificationsPlugin.cancel(_kCallNotificationId);
  }

  /// 🔥 Show a remote FCM message (foreground/background via our UI)
  static Future<void> showRemoteMessage(RemoteMessage message) async {
    await _ensureReady();
    await _showFromRemote(message);
  }

  /// Alias kept for compatibility
  static Future<void> show(RemoteMessage message) async {
    await _ensureReady();
    await _showFromRemote(message);
  }

  /// � Play only an alert sound (without a visible notification) while in-app.
  static Future<void> playAlertSound() async {
    await _ensureReady();

    final androidDetails = AndroidNotificationDetails(
      alertsChannelId,
      'Smart Truck Driver Alerts',
      channelDescription: 'Urgent driver alerts (dispatch assignments, issues).',
      importance: Importance.min,
      priority: Priority.low,
      playSound: true,
      enableVibration: false,
      showWhen: false,
      autoCancel: true,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.status,
      styleInformation: const DefaultStyleInformation(true, true),
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentSound: true),
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '',
      '',
      details,
      payload: null,
    );
  }

  /// �💡 Show a local (manual) notification
  static Future<void> showLocal(
    String title,
    String body, {
    bool urgent = false,
    Map<String, dynamic>? payload,
  }) async {
    await _ensureReady();

    final androidDetails = AndroidNotificationDetails(
      urgent ? _alertsChannel.id : _updatesChannel.id,
      urgent ? _alertsChannel.name : _updatesChannel.name,
      channelDescription:
          urgent ? _alertsChannel.description : _updatesChannel.description,
      importance: urgent ? Importance.max : Importance.defaultImportance,
      priority: urgent ? Priority.high : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.message,
      styleInformation: const BigTextStyleInformation(''),
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      // ID: use epoch seconds to avoid rapid collisions
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload == null ? null : jsonEncode(payload),
    );
  }

  // ---------------- internal helpers ----------------

  static Future<void> _ensureReady() async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (_) {
        // Platform not available (e.g. unit-test environment); skip notifications.
        return;
      }
    }
  }

  static Future<void> _showFromRemote(RemoteMessage message) async {
    final data = message.data;
    final title = message.notification?.title ?? data['title'] ?? 'SV Trucking';
    final body =
        message.notification?.body ?? data['body'] ?? data['message'] ?? '';

    final priority = (data['priority'] ?? '').toString().toLowerCase();
    final type = (data['type'] ?? '').toString().toLowerCase();

    // Heads-up for dispatch/issue/high-priority
    final bool isAlert = priority == 'high' ||
        type == 'dispatch' ||
        type == 'issue' ||
        type == 'alert';

    final androidDetails = AndroidNotificationDetails(
      isAlert ? _alertsChannel.id : _updatesChannel.id,
      isAlert ? _alertsChannel.name : _updatesChannel.name,
      channelDescription:
          isAlert ? _alertsChannel.description : _updatesChannel.description,
      importance: isAlert ? Importance.max : Importance.defaultImportance,
      priority: isAlert ? Priority.high : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher', // consider a dedicated monochrome small icon
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction('open_app', 'បើកកម្មវិធី'),
      ],
      category: AndroidNotificationCategory.message,
      styleInformation: const BigTextStyleInformation(''),
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Stable-ish ID if messageId exists, otherwise generate
    final int notifId = (message.messageId ??
            '$title|$body|${DateTime.now().millisecondsSinceEpoch}')
        .hashCode;

    await flutterLocalNotificationsPlugin.show(
      notifId,
      title,
      body,
      details,
      // Keep full data for deep-link handling on tap
      payload: jsonEncode(data),
    );
  }

  /// 🚦 Foreground tap handler
  static void _handleNotificationTap(NotificationResponse response) {
    try {
      final raw = response.payload;
      if (raw == null || raw.isEmpty) {
        _onTap?.call(const {});
        return;
      }
      final Map<String, dynamic> data = jsonDecode(raw);
      if (kDebugMode) debugPrint('[🔔] Tapped payload: $data');
      _onTap?.call(data);
    } catch (e) {
      if (kDebugMode) debugPrint('[🔔] Tap parse error: $e');
      _onTap?.call(const {});
    }
  }

  /// 🚦 Background tap handler (Android may deliver while app is bg)
  @pragma('vm:entry-point')
  static void _handleNotificationTapBg(NotificationResponse response) {
    _handleNotificationTap(response);
  }
}
