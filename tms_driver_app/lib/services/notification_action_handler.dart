import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tms_driver_app/core/globals.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

/// Callback types for action handling (typedef must be at top-level, not inside class)
typedef ActionCallback = Future<void> Function(
    String actionId, Map<String, dynamic> payload);

/// 📱 Enhanced Notification Action Handler
/// Handles notification actions (Accept/Reject) from notification UI
class NotificationActionHandler {
  static final NotificationActionHandler _instance =
      NotificationActionHandler._internal();
  factory NotificationActionHandler() => _instance;
  NotificationActionHandler._internal();

  final Map<String, ActionCallback> _actionCallbacks = {};

  /// 🔧 Initialize action handler with callbacks
  Future<void> initialize({
    ActionCallback? onAcceptJob,
    ActionCallback? onRejectJob,
    ActionCallback? onViewDetails,
    ActionCallback? onMarkRead,
  }) async {
    if (onAcceptJob != null) {
      _actionCallbacks['accept_job'] = onAcceptJob;
    }
    if (onRejectJob != null) {
      _actionCallbacks['reject_job'] = onRejectJob;
    }
    if (onViewDetails != null) {
      _actionCallbacks['view_details'] = onViewDetails;
    }
    if (onMarkRead != null) {
      _actionCallbacks['mark_read'] = onMarkRead;
    }

    debugPrint('🎬 NotificationActionHandler initialized with ${_actionCallbacks.length} callbacks');
  }

  /// 📲 Register action callback dynamically
  void registerActionCallback(String actionId, ActionCallback callback) {
    _actionCallbacks[actionId] = callback;
    debugPrint('Registered action callback: $actionId');
  }

  /// 🎯 Handle notification response (tap or action button)
  Future<void> handleNotificationResponse(
      NotificationResponse response) async {
    try {
      final actionId = response.actionId;
      final payload = response.payload;

      if (payload == null || payload.isEmpty) {
        debugPrint('Empty notification payload');
        return;
      }

      final Map<String, dynamic> data = jsonDecode(payload);
      debugPrint('🔔 Notification action: $actionId | data: $data');

      // Handle action button press
      if (actionId != null && _actionCallbacks.containsKey(actionId)) {
        await _actionCallbacks[actionId]!(actionId, data);
        return;
      }

      // Handle notification tap (no action ID = main notification tap)
      if (actionId == null) {
        _navigateFromPayload(data);
      }
    } catch (e, st) {
      debugPrint('Error handling notification response: $e\n$st');
    }
  }

  /// 🔀 Navigate based on notification type
  void _navigateFromPayload(Map<String, dynamic> data) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) {
      debugPrint('Navigation context is null');
      return;
    }

    final type = data['type']?.toString().toLowerCase();
    final referenceId = data['referenceId']?.toString();
    final notificationId = data['notificationId']?.toString();

    debugPrint('🔀 Navigating: type=$type, ref=$referenceId, notifId=$notificationId');

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
      case 'problem_report':
        Navigator.pushNamed(context, AppRoutes.reportIssueList);
        break;

      case 'message':
        Navigator.pushNamed(context, AppRoutes.messages + '/chat');
        break;

      case 'document_required':
        Navigator.pushNamed(context, AppRoutes.documents);
        break;

      case 'location_update':
        // Navigate to map/tracking screen
        Navigator.pushNamed(context, AppRoutes.home);
        break;

      default:
        // Fallback: go to notifications list
        Navigator.pushNamed(context, AppRoutes.notifications);
    }
  }

  /// 🎨 Create notification with action buttons based on type
  AndroidNotificationDetails createAndroidDetailsWithActions({
    required String channelId,
    required String channelName,
    String? channelDescription,
    required String notificationType,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    // Define actions based on notification type
    final List<AndroidNotificationAction> actions = _getActionsForType(notificationType);

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      actions: actions,
      category: _getCategoryForType(notificationType),
      styleInformation: const BigTextStyleInformation(''),
      ticker: 'SV Trucking',
    );
  }

  /// 🎯 Get action buttons based on notification type
  List<AndroidNotificationAction> _getActionsForType(String type) {
    switch (type.toLowerCase()) {
      case 'dispatch':
      case 'job_assigned':
        return [
          const AndroidNotificationAction(
            'accept_job',
            'Accept',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'reject_job',
            'Reject',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'view_details',
            'View',
            showsUserInterface: true,
          ),
        ];

      case 'issue':
      case 'problem_report':
        return [
          const AndroidNotificationAction(
            'view_details',
            'View Issue',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'mark_read',
            'Mark Read',
            showsUserInterface: false,
          ),
        ];

      case 'message':
        return [
          const AndroidNotificationAction(
            'view_details',
            'Open Message',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'mark_read',
            'Dismiss',
            showsUserInterface: false,
          ),
        ];

      case 'document_required':
        return [
          const AndroidNotificationAction(
            'view_details',
            'Upload Document',
            showsUserInterface: true,
          ),
        ];

      default:
        return [
          const AndroidNotificationAction(
            'view_details',
            'Open',
            showsUserInterface: true,
          ),
        ];
    }
  }

  /// 📁 Get notification category for type
  AndroidNotificationCategory _getCategoryForType(String type) {
    switch (type.toLowerCase()) {
      case 'dispatch':
      case 'job_assigned':
        return AndroidNotificationCategory.event;
      case 'message':
        return AndroidNotificationCategory.message;
      case 'issue':
      case 'problem_report':
        return AndroidNotificationCategory.error;
      case 'location_update':
        return AndroidNotificationCategory.navigation;
      default:
        return AndroidNotificationCategory.message;
    }
  }

  /// 🗑️ Clear action callbacks
  void dispose() {
    _actionCallbacks.clear();
  }
}
