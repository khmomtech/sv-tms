import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/globals.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/providers/call_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/utils/notification_helper.dart';
import 'package:provider/provider.dart';

// ── SharedPreferences key where background isolate persists pending calls ──
const String _kPendingCallKey = 'pending_incoming_call';

/// Register FCM, sync device token, and set up message listeners.
Future<void> setupFirebaseMessaging(
    GlobalKey<NavigatorState> navigatorKey) async {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  final NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

  // ── Sync FCM token with backend ────────────────────────────────────────────
  final String? token = await messaging.getToken();
  final prefs = await SharedPreferences.getInstance();
  final driverId = prefs.getString('driverId');
  final lastSyncedToken = prefs.getString('last_synced_device_token');
  final accessToken = await ApiConstants.getAccessToken();

  if (token != null &&
      token != lastSyncedToken &&
      driverId != null &&
      accessToken != null) {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/driver/update-device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'driverId': driverId, 'deviceToken': token}),
      );
      if (response.statusCode == 200) {
        await prefs.setString('last_synced_device_token', token);
        debugPrint('[FCM] Token synced with backend');
      }
    } catch (e) {
      debugPrint('[FCM] Failed to sync token: $e');
    }
  }

  // ── Message listeners ──────────────────────────────────────────────────────
  FirebaseMessaging.onMessage
      .listen((msg) => _handleForegroundMessage(msg, navigatorKey));
  FirebaseMessaging.onMessageOpenedApp
      .listen((msg) => _handleMessageTap(msg, navigatorKey));
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ── Check for call that arrived while app was killed ──────────────────────
  await _drainPendingCall(navigatorKey);
}

// ══════════════════════════════════════════════════════════════════════════════
// TOP-LEVEL background handler — runs in a separate isolate.
// IMPORTANT: must be a top-level function and annotated @pragma('vm:entry-point')
// ══════════════════════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Firebase may not be initialized in background isolate
    debugPrint('[BG-FCM] Received: type=${message.data['type']}');

    final type = message.data['type']?.toString().toUpperCase();

    if (type == 'INCOMING_CALL') {
      // Persist call data so the app can read it when brought to foreground.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kPendingCallKey,
        jsonEncode({
          'channelName': message.data['channelName'] ?? '',
          'callerName':  message.data['callerName']  ?? 'Dispatch',
          'sessionId':   message.data['sessionId']   ?? '',
          'driverId':    message.data['driverId']     ?? '',
          'arrivedAt':   DateTime.now().toIso8601String(),
        }),
      );
      debugPrint('[BG-FCM] Persisted INCOMING_CALL to SharedPreferences');
      // Show a heads-up local notification so the user sees it on locked screen.
      await NotificationHelper.initialize();
      await NotificationHelper.showCallNotification(
        callerName: message.data['callerName'] ?? 'Dispatch',
        channelName: message.data['channelName'] ?? '',
        payload: jsonEncode(message.data),
      );
    } else {
      // Default handling for all other message types
      await NotificationHelper.initialize();
      await NotificationHelper.showRemoteMessage(message);
    }
  } catch (e, st) {
    // ignore: avoid_print
    print('[BG-FCM] Handler error: $e\n$st');
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Foreground message handler
// ══════════════════════════════════════════════════════════════════════════════

void _handleForegroundMessage(
    RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
  final type = message.data['type']?.toString().toUpperCase();

  if (type == 'INCOMING_CALL') {
    // If STOMP is already connected the ChatProvider will handle this via STOMP.
    // Reaching here means either STOMP missed it or this is a duplicate push.
    // Route directly to IncomingCallScreen if no call is active.
    _navigateToIncomingCall(message.data, navigatorKey);
  } else {
    NotificationHelper.showRemoteMessage(message);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Notification tap handler (app was backgrounded, user tapped notification)
// ══════════════════════════════════════════════════════════════════════════════

void _handleMessageTap(
    RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
  final data = message.data;
  final type = (data['type'] ?? '').toString().toUpperCase();

  switch (type) {
    case 'INCOMING_CALL':
      _navigateToIncomingCall(data, navigatorKey);
      break;
    case 'NOTIFICATION':
      _push(navigatorKey, AppRoutes.notifications);
      break;
    case 'ORDER':
      _push(navigatorKey, AppRoutes.dashboard);
      break;
    default:
      _push(navigatorKey, AppRoutes.notifications);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Pending-call drain — reads SharedPreferences on app open after kill
// ══════════════════════════════════════════════════════════════════════════════

/// Call this once during app startup (after navigatorKey is mounted) to
/// surface any incoming call that arrived while the app was killed.
Future<void> _drainPendingCall(GlobalKey<NavigatorState> navigatorKey) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPendingCallKey);
    if (raw == null) return;

    final payload = jsonDecode(raw) as Map<String, dynamic>;
    // Only surface calls that arrived in the last 45 seconds (ring timeout).
    final arrivedAt = DateTime.tryParse(payload['arrivedAt'] ?? '');
    if (arrivedAt == null ||
        DateTime.now().difference(arrivedAt).inSeconds > 45) {
      await prefs.remove(_kPendingCallKey);
      debugPrint('[FCM] Pending call expired, discarding.');
      return;
    }

    // Remove so we don't show it twice
    await prefs.remove(_kPendingCallKey);
    debugPrint('[FCM] Draining pending INCOMING_CALL: ${payload['channelName']}');
    _navigateToIncomingCall(payload.map((k, v) => MapEntry(k, v.toString())), navigatorKey);
  } catch (e) {
    debugPrint('[FCM] Error draining pending call: $e');
  }
}

/// Public helper so main.dart can call it once the navigator is ready.
Future<void> drainPendingFcmCall(GlobalKey<NavigatorState> navigatorKey) =>
    _drainPendingCall(navigatorKey);

// ══════════════════════════════════════════════════════════════════════════════
// Navigation helpers
// ══════════════════════════════════════════════════════════════════════════════

void _navigateToIncomingCall(
    Map<String, dynamic> data, GlobalKey<NavigatorState> navigatorKey) {
  final channelName = data['channelName']?.toString() ?? '';
  final callerName  = data['callerName']?.toString()  ?? 'Dispatch';
  final sessionId   = int.tryParse(data['sessionId']?.toString() ?? '');
  final driverId    = int.tryParse(data['driverId']?.toString()  ?? '');

  if (channelName.isEmpty) {
    debugPrint('[FCM] INCOMING_CALL missing channelName, skipping navigation');
    return;
  }

  final context = navigatorKey.currentState?.overlay?.context;
  if (context == null) {
    debugPrint('[FCM] Navigator not ready yet, skipping INCOMING_CALL navigation');
    return;
  }

  // Feed the channel info into CallProvider so the state machine knows about it
  try {
    final callProvider = Provider.of<CallProvider>(context, listen: false);
    if (callProvider.state == CallState.idle) {
      callProvider.handleIncomingCall(
        channelName: channelName,
        callerName: callerName,
      );
      Navigator.of(context).pushNamed(
        AppRoutes.incomingCall,
        arguments: IncomingCallRouteArgs(
          channelName: channelName,
          callerName: callerName,
          sessionId: sessionId,
          driverId: driverId,
        ),
      );
    } else {
      debugPrint('[FCM] Already in a call (state=${callProvider.state}), ignoring duplicate INCOMING_CALL');
    }
  } catch (e) {
    debugPrint('[FCM] Could not get CallProvider: $e');
  }
}

void _push(GlobalKey<NavigatorState> navigatorKey, String route) {
  final context = navigatorKey.currentState?.overlay?.context;
  if (context != null) {
    Navigator.of(context).pushNamed(route);
  }
}
