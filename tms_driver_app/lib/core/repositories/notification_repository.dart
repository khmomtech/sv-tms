// 📁 lib/core/repositories/notification_repository.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/repositories/base_repository.dart';

/// Repository for notification-related data operations
/// 
/// Handles:
/// - Fetching notifications
/// - Marking as read
/// - Deleting notifications
/// - Badge count management
class NotificationRepository extends BaseRepository {
  final SharedPreferences _prefs;
  
  static const String _cacheKey = 'cached_notifications';
  static const String _badgeCountKey = 'notification_badge_count';

  NotificationRepository({
    required Dio dio,
    required SharedPreferences prefs,
  })  : _prefs = prefs,
        super(dio: dio);

  // ============================================================
  // Fetch Notifications
  // ============================================================

  /// Get all notifications for driver
  Future<List<Map<String, dynamic>>> getNotifications({
    required String driverId,
    int page = 0,
    int size = 50,
  }) async {
    return executeWithRetry(
      () async {
        final response = await dio.get(
          '${ApiConstants.baseUrl}${ApiConstants.notificationEndpoints['list']}',
          queryParameters: {
            'driverId': driverId,
            'page': page,
            'size': size,
            'sort': 'createdAt,DESC',
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final notifications = _extractNotifications(response.data);
          if (page == 0) {
            // Only cache first page
            await _cacheNotifications(notifications);
          }
          return notifications;
        }
        return [];
      },
      label: 'getNotifications',
    );
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String driverId) async {
    return executeWithRetry(
      () async {
        final response = await dio.get(
          '${ApiConstants.baseUrl}${ApiConstants.notificationEndpoints['unread-count']}',
          queryParameters: {'driverId': driverId},
        );

        if (response.statusCode == 200 && response.data != null) {
          final count = response.data['count'] ?? 0;
          await _cacheBadgeCount(count);
          return count;
        }
        return 0;
      },
      label: 'getUnreadCount',
    );
  }

  List<Map<String, dynamic>> _extractNotifications(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('content')) {
      return List<Map<String, dynamic>>.from(data['content'] ?? []);
    } else if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  // ============================================================
  // Notification Actions
  // ============================================================

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    return executeWithRetry(
      () async {
        final response = await dio.put(
          '${ApiConstants.baseUrl}${ApiConstants.notificationEndpoints['mark-read']!.replaceAll('{id}', notificationId.toString())}',
        );

        return response.statusCode == 200;
      },
      label: 'markAsRead',
    );
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead(String driverId) async {
    return executeWithRetry(
      () async {
        final response = await dio.put(
          '${ApiConstants.baseUrl}${ApiConstants.notificationEndpoints['mark-all-read']}',
          queryParameters: {'driverId': driverId},
        );

        return response.statusCode == 200;
      },
      label: 'markAllAsRead',
    );
  }

  /// Delete notification
  Future<bool> deleteNotification(int notificationId) async {
    return executeWithRetry(
      () async {
        final response = await dio.delete(
          '${ApiConstants.baseUrl}${ApiConstants.notificationEndpoints['delete']!.replaceAll('{id}', notificationId.toString())}',
        );

        return response.statusCode == 200;
      },
      label: 'deleteNotification',
    );
  }

  /// Delete all notifications
  Future<bool> deleteAllNotifications(String driverId) async {
    return executeWithRetry(
      () async {
        final response = await dio.delete(
          '${ApiConstants.baseUrl}${ApiConstants.notificationEndpoints['delete-all']}',
          queryParameters: {'driverId': driverId},
        );

        return response.statusCode == 200;
      },
      label: 'deleteAllNotifications',
    );
  }

  // ============================================================
  // Cache Management
  // ============================================================

  Future<void> _cacheNotifications(List<Map<String, dynamic>> notifications) async {
    try {
      await _prefs.setString(_cacheKey, jsonEncode(notifications));
    } catch (e) {
      log('Error caching notifications: $e');
    }
  }

  Future<void> _cacheBadgeCount(int count) async {
    try {
      await _prefs.setInt(_badgeCountKey, count);
    } catch (e) {
      log('Error caching badge count: $e');
    }
  }

  /// Get cached notifications for offline support
  Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    try {
      final cached = _prefs.getString(_cacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
    } catch (e) {
      log('Error reading cached notifications: $e');
    }
    return [];
  }

  /// Get cached badge count
  int getCachedBadgeCount() {
    return _prefs.getInt(_badgeCountKey) ?? 0;
  }

  /// Clear notification cache
  Future<void> clearCache() async {
    await Future.wait([
      _prefs.remove(_cacheKey),
      _prefs.remove(_badgeCountKey),
    ]);
  }
}
