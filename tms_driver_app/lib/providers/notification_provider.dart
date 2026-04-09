import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  // ----------------------- State -----------------------
  final List<NotificationItem> _notifications = [];
  final Set<int> _seenIds = <int>{}; // de-dup incoming notifications

  bool isLoading = false;
  int _page = 0;
  int _size = 20;
  bool _hasMore = true;
  int _unreadCountServer = 0;

  // Optional: track incremental polling
  DateTime? _lastFetchedAt;
  DateTime? _fetchBackoffUntil;
  DateTime? _lastFetchErrorLoggedAt;

  StompClient? _stompClient;
  bool _manuallyDisconnected = false;
  bool _subscribed = false;
  bool _connecting = false;
  int _reconnectAttempts = 0;
  int _unauthorizedAttempts = 0;
  static const int _maxUnauthorizedAttempts = 3;
  bool _authInvalid = false;
  String? _lastDriverId;
  String? _lastToken;

  List<NotificationItem> get notifications => _notifications; // newest-first
  int get unreadCount => _notifications.where((n) => !n.read).length;
  int get unreadCountServer => _unreadCountServer;
  bool get hasMore => _hasMore;

  // ----------------------- REST helpers -----------------------
  Uri _buildListUri({
    required String baseUrl,
    required String driverId,
    String order = 'unreadFirst',
    bool unreadOnly = false,
    DateTime? since,
    int page = 0,
    int size = 20,
  }) {
    return Uri.parse('$baseUrl/notifications/driver/$driverId').replace(
      queryParameters: <String, String>{
        'order': order, // unreadFirst | newest
        'unreadOnly': unreadOnly.toString(),
        if (since != null) 'since': since.toIso8601String(),
        'page': page.toString(),
        'size': size.toString(),
      },
    );
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await ApiConstants.ensureFreshAccessToken();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  Future<(String driverId, String baseApi)> _loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driverId');
    if (driverId == null || driverId.isEmpty) {
      debugPrint('[Notifications] Missing driverId → skip operation');
      // Throwing causes noisy crash logs; instead callers should guard.
      throw Exception('Missing driverId');
    }
    // keep shape, though baseApi not strictly needed now
    return (driverId, ApiConstants.baseUrl);
  }

  // ----------------------- REST APIs -----------------------
  /// Initial fetch (or refresh) with unread-first ordering.
  Future<bool> fetchNotifications({
    String order = 'unreadFirst',
    bool unreadOnly = false,
    int page = 0,
    int size = 20,
    DateTime? since, // pass _lastFetchedAt for incremental sync
  }) async {
    final now = DateTime.now();
    if (_fetchBackoffUntil != null && now.isBefore(_fetchBackoffUntil!)) {
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      final (driverId, _) = await _loadIds();
      final headers = await _authHeaders();

      // Build primary list URI and fallbacks.
      final uriCandidates = <Uri>{
        _buildListUri(
          baseUrl: ApiConstants.baseUrl, // ensure /api prefix
          driverId: driverId,
          order: order,
          unreadOnly: unreadOnly,
          page: page,
          size: size,
          since: since,
        ),
        // Older backend variants
        Uri.parse('${ApiConstants.baseUrl}/notifications/driver/$driverId/all'),
        Uri.parse('${ApiConstants.baseUrl}/notifications/driver/$driverId'),
      };

      http.Response? resp;
      for (final cand in uriCandidates) {
        try {
          resp = await http.get(cand, headers: headers).timeout(
                const Duration(seconds: 10),
              );
          if (resp.statusCode == 200 && resp.body.isNotEmpty) {
            break;
          }
        } catch (e) {
          debugPrint('Notification fetch candidate failed: $cand -> $e');
          continue;
        }
      }

      if (resp == null) {
        debugPrint('[NotificationProvider] No candidate URI returned a response');
        return false;
      }

      if (resp.statusCode != 200) {
        if (resp.statusCode >= 500) {
          _fetchBackoffUntil = DateTime.now().add(const Duration(seconds: 60));
        }
        final logNow = DateTime.now();
        final shouldLog = _lastFetchErrorLoggedAt == null ||
            logNow.difference(_lastFetchErrorLoggedAt!) >
                const Duration(seconds: 30);
        if (shouldLog) {
          _lastFetchErrorLoggedAt = logNow;
          debugPrint(
              '[NotificationProvider] Failed to fetch notifications: ${resp.statusCode}');
        }
        return false;
      }

      _fetchBackoffUntil = null;
      final body =
          json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

      Map<String, dynamic> payload = const <String, dynamic>{};
      final dynamic dataNode = body['data'];
      if (dataNode is Map<String, dynamic>) {
        payload = dataNode;
      } else if (dataNode is Map) {
        payload = dataNode.cast<String, dynamic>();
      } else if (body['content'] is List) {
        payload = body;
      }

      // Supports both:
      // 1) { data: { content, page, size, last, unreadCount } }
      // 2) { content, number, size, last, ... } (Spring Page direct)
      final content = (payload['content'] as List<dynamic>? ?? <dynamic>[]);
      final unreadCountFromServerRaw = payload['unreadCount'];
      final unreadCountFromServer = unreadCountFromServerRaw is num
          ? unreadCountFromServerRaw.toInt()
          : content.where((e) {
              if (e is Map<String, dynamic>) return e['read'] != true;
              if (e is Map) return e['read'] != true;
              return false;
            }).length;
      final pageNum = (payload['page'] as num?)?.toInt() ??
          (payload['number'] as num?)?.toInt() ??
          0;
      final pageSize = (payload['size'] as num?)?.toInt() ?? content.length;
      final isLast = payload['last'] as bool? ?? true;

      final items = content
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (page == 0 && since == null && !unreadOnly) {
        // Full refresh
        _notifications
          ..clear()
          ..addAll(items);
        _seenIds
          ..clear()
          ..addAll(_notifications.map((e) => e.id));
      } else {
        // Append/merge new page or incremental since
        for (final it in items) {
          if (!_seenIds.contains(it.id)) {
            _seenIds.add(it.id);
            _notifications.add(it);
          }
        }
        // Keep newest->oldest in memory
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _page = pageNum;
      _size = pageSize;
      _hasMore = !isLast;
      _unreadCountServer = unreadCountFromServer;
      _lastFetchedAt = DateTime.now();

      debugPrint(
          'Notifications fetched: ${_notifications.length} (page=$pageNum size=$pageSize last=$isLast)');
      return true;
    } catch (e) {
      // Gracefully ignore missing driverId cases
      if (e.toString().contains('Missing driverId')) {
        debugPrint('fetchNotifications skipped: Missing driverId');
      } else {
        final logNow = DateTime.now();
        final shouldLog = _lastFetchErrorLoggedAt == null ||
            logNow.difference(_lastFetchErrorLoggedAt!) >
                const Duration(seconds: 30);
        if (shouldLog) {
          _lastFetchErrorLoggedAt = logNow;
          debugPrint(
              '[NotificationProvider] Exception during fetchNotifications: $e');
        }
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Load next page (keeps current ordering flags).
  Future<void> fetchNextPage({
    String order = 'unreadFirst',
    bool unreadOnly = false,
  }) async {
    if (!_hasMore) return;
    await fetchNotifications(
      order: order,
      unreadOnly: unreadOnly,
      page: _page + 1,
      size: _size,
      since: null,
    );
  }

  /// Incremental refresh using last fetch time (server supports `since`).
  Future<void> fetchSinceLast({
    String order = 'unreadFirst',
    bool unreadOnly = false,
  }) async {
    await fetchNotifications(
      order: order,
      unreadOnly: unreadOnly,
      page: 0,
      size: _size,
      since: _lastFetchedAt,
    );
  }

  /// 📍 Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final (driverId, _) = await _loadIds();
      final headers = await _authHeaders();
      final uri = Uri.parse(
          '${ApiConstants.baseUrl}/notifications/driver/$driverId/mark-all-read');

      final response = await http.patch(uri, headers: headers);
      if (response.statusCode == 200) {
        for (var n in _notifications) {
          n.read = true;
        }
        _unreadCountServer = 0;
        debugPrint('All notifications marked as read');
        notifyListeners();
      } else {
        debugPrint('Failed to mark all as read: ${response.statusCode}');
        throw Exception('Failed to mark all as read');
      }
    } catch (e) {
      if (e.toString().contains('Missing driverId')) {
        debugPrint('markAllAsRead skipped: Missing driverId');
      } else {
        debugPrint(' Exception during markAllAsRead: $e');
      }
    }
  }

  /// 📍 Mark single notification as read (driver-scoped route)
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final (driverId, _) = await _loadIds();
      final headers = await _authHeaders();
      final uri = Uri.parse(
          '${ApiConstants.baseUrl}/notifications/driver/$driverId/$notificationId/read');

      final resp = await http.put(uri, headers: headers);
      if (resp.statusCode == 200) {
        final idx = _notifications.indexWhere((n) => n.id == notificationId);
        if (idx != -1 && !_notifications[idx].read) {
          _notifications[idx].read = true;
          _unreadCountServer = (_unreadCountServer - 1).clamp(0, 1 << 30);
          notifyListeners();
        }
        debugPrint('Notification $notificationId marked as read');
      } else {
        debugPrint('Failed to mark notification as read: ${resp.statusCode}');
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      if (e.toString().contains('Missing driverId')) {
        debugPrint('markNotificationAsRead skipped: Missing driverId');
      } else {
        debugPrint(' Error marking notification as read: $e');
      }
    }
  }

  /// 🗑️ Delete a single notification (optimistic UI + revert on failure)
  Future<void> deleteNotification(int id) async {
    final (driverId, _) = await _loadIds();
    final headers = await _authHeaders();
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/notifications/driver/$driverId/$id');

    // Find target + prepare optimistic changes
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) {
      debugPrint('ℹ️ deleteNotification: id=$id not found locally');
      return;
    }

    final removed = _notifications[index];
    final wasUnread = !removed.read;

    // Optimistic remove
    _notifications.removeAt(index);
    _seenIds.remove(id);
    if (wasUnread) {
      _unreadCountServer = (_unreadCountServer - 1).clamp(0, 1 << 30);
    }
    notifyListeners();

    try {
      final resp = await http.delete(uri, headers: headers);
      if (resp.statusCode != 200 && resp.statusCode != 204) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      debugPrint('🗑️ Deleted notification $id');
    } catch (e) {
      // Revert on failure
      _notifications.insert(index, removed);
      _seenIds.add(id);
      if (wasUnread) _unreadCountServer++;
      notifyListeners();
      if (e.toString().contains('Missing driverId')) {
        debugPrint('deleteNotification skipped: Missing driverId');
      } else {
        debugPrint('Failed to delete notification $id: $e');
      }
    }
  }

  /// 🧹 Delete all READ notifications (optional helper)
  Future<void> deleteAllRead() async {
    final (driverId, _) = await _loadIds();
    final headers = await _authHeaders();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}/notifications/driver/$driverId/delete-read');

    // Optimistic snapshot
    final before = List<NotificationItem>.from(_notifications);
    final beforeSeen = Set<int>.from(_seenIds);

    _notifications.removeWhere((n) => n.read);
    _seenIds
      ..clear()
      ..addAll(_notifications.map((e) => e.id));
    notifyListeners();

    try {
      final resp = await http.delete(uri, headers: headers);
      if (resp.statusCode != 200 && resp.statusCode != 204) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      debugPrint('🧹 Deleted all read notifications');
    } catch (e) {
      // Revert
      _notifications
        ..clear()
        ..addAll(before);
      _seenIds
        ..clear()
        ..addAll(beforeSeen);
      notifyListeners();
      if (e.toString().contains('Missing driverId')) {
        debugPrint('deleteAllRead skipped: Missing driverId');
      } else {
        debugPrint('Failed to delete read notifications: $e');
      }
    }
  }

  /// 🗃️ Bulk delete by IDs (optional helper for future multi-select UI)
  Future<void> deleteMany(List<int> ids) async {
    if (ids.isEmpty) return;
    final (driverId, _) = await _loadIds();
    final headers = await _authHeaders();
    final uri = Uri.parse(
        '${ApiConstants.baseUrl}/notifications/driver/$driverId/batch');

    // Optimistic remove
    final before = List<NotificationItem>.from(_notifications);
    final beforeSeen = Set<int>.from(_seenIds);
    int unreadRemoved = 0;

    _notifications.removeWhere((n) {
      final remove = ids.contains(n.id);
      if (remove && !n.read) unreadRemoved++;
      return remove;
    });
    _seenIds
      ..clear()
      ..addAll(_notifications.map((e) => e.id));
    _unreadCountServer = (_unreadCountServer - unreadRemoved).clamp(0, 1 << 30);
    notifyListeners();

    try {
      // NOTE: If your server rejects bodies on DELETE, change to POST:
      // final resp = await http.post(
      //   Uri.parse('${ApiConstants.baseUrl}/notifications/driver/$driverId/batch-delete'),
      //   headers: {...headers, 'Content-Type': 'application/json'},
      //   body: jsonEncode({'ids': ids}),
      // );
      final resp = await http.delete(
        uri,
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ids': ids}),
      );

      if (resp.statusCode != 200 && resp.statusCode != 204) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      debugPrint('🗃️ Deleted ${ids.length} notifications');
    } catch (e) {
      // Revert
      _notifications
        ..clear()
        ..addAll(before);
      _seenIds
        ..clear()
        ..addAll(beforeSeen);
      _unreadCountServer += unreadRemoved;
      notifyListeners();
      if (e.toString().contains('Missing driverId')) {
        debugPrint('deleteMany skipped: Missing driverId');
      } else {
        debugPrint('Failed bulk delete: $e');
      }
    }
  }

  // ----------------------- WebSocket / STOMP -----------------------
  /// 🔔 Connect to WebSocket (/ws, not /ws-sockjs)
  Future<void> connectWebSocket(String driverId) async {
    if (_authInvalid) {
      debugPrint('WebSocket disabled due to repeated unauthorized errors');
      return;
    }
    // Avoid duplicate connects
    if (_stompClient?.connected == true) {
      debugPrint('ℹ️ WebSocket already connected');
      return;
    }
    if (_connecting) {
      debugPrint('ℹ️ WebSocket connection is in progress');
      return;
    }

    final token = _normalizeToken(await ApiConstants.getAccessToken());
    if (token == null || driverId.isEmpty) {
      debugPrint('Missing token or driverId for WebSocket');
      return;
    }

    // If token changed, ensure clean reconnect
    final tokenChanged = (_lastToken != null && _lastToken != token);
    _lastToken = token;
    _lastDriverId = driverId;

    _manuallyDisconnected = false;
    _subscribed = false;
    _reconnectAttempts = tokenChanged ? 0 : _reconnectAttempts;

    // Build ws URL from baseUrl but target /ws
    final baseUri = Uri.parse(ApiConstants.baseUrl.replaceFirst('/api', ''));
    final wsProtocol = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final port = (baseUri.hasPort &&
            baseUri.port != 0 &&
            baseUri.port != 80 &&
            baseUri.port != 443)
        ? ':${baseUri.port}'
        : '';
    final wsUrl =
        '$wsProtocol://${baseUri.host}$port/ws?token=${Uri.encodeQueryComponent(token)}';

    debugPrint('Connecting to WebSocket: ${_maskToken(wsUrl)}');

    // Cleanup previous client if any
    _stompClient?.deactivate();

    _connecting = true;
    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          debugPrint('WebSocket connected');
          _connecting = false;
          _reconnectAttempts = 0;
          _unauthorizedAttempts = 0;

          final topic = '/topic/driver-notification/$driverId';
          final allTopic = '/topic/driver-notification/all';
          if (!_subscribed) {
            debugPrint('Subscribing to $topic and $allTopic');
            _stompClient?.subscribe(
              destination: topic,
              callback: _handleNotificationFrame,
            );
            _stompClient?.subscribe(
              destination: allTopic,
              callback: _handleNotificationFrame,
            );
            _subscribed = true;
          }
        },
        onStompError: (frame) {
          debugPrint('STOMP Error: ${frame.body}');
          if (_looksUnauthorized(frame.body ?? frame.headers.toString())) {
            _handleUnauthorized();
          }
        },
        onWebSocketError: (error) {
          debugPrint('WebSocket transport error: $error');
          if (_looksUnauthorized(error.toString())) {
            _handleUnauthorized();
          }
        },
        onDisconnect: (_) {
          debugPrint('🛑 WebSocket connection closed');
          _connecting = false;
          _subscribed = false;
          if (!_manuallyDisconnected && !_authInvalid) {
            _scheduleReconnect();
          }
        },
        reconnectDelay: const Duration(seconds: 0), // we manage our own backoff
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    try {
      _stompClient!.activate();
    } catch (e) {
      _connecting = false;
      debugPrint('WebSocket activation error: $e');
      if (!_manuallyDisconnected) {
        _scheduleReconnect();
      }
    }
  }

  ///Auto reconnect with exponential backoff + jitter
  void _scheduleReconnect() {
    if (_authInvalid) return;
    _reconnectAttempts++;
    // base backoff = 5s, cap at 60s, add jitter up to +2s to avoid thundering herd
    final base = min(60, 5 * _reconnectAttempts);
    final jitter = Random().nextInt(3); // 0..2 seconds
    final delay = Duration(seconds: base + jitter);
    debugPrint('♻️ Attempting WebSocket reconnect in ${delay.inSeconds}s...');

    Future.delayed(delay, () async {
      if (_manuallyDisconnected) return;
      final driverId = _lastDriverId;
      final token = await ApiConstants.getAccessToken();
      if (driverId == null || driverId.isEmpty || token == null) return;
      connectWebSocket(driverId);
    });
  }

  /// ✋ Manual disconnect
  void disconnectWebSocket() {
    _manuallyDisconnected = true;
    _subscribed = false;
    _connecting = false;
    _reconnectAttempts = 0;
    _unauthorizedAttempts = 0;
    _authInvalid = false;
    try {
      _stompClient?.deactivate();
    } catch (_) {}
    _stompClient = null;
    debugPrint('🧹 WebSocket manually disconnected');
  }

  /// 📍 Local mark as read only (no API)
  void markAsRead(int id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].read) {
      _notifications[index].read = true;
      _unreadCountServer = (_unreadCountServer - 1).clamp(0, 1 << 30);
      notifyListeners();
    }
  }

  // Returns only notifications marked as important (e.g., priority or type)
  List<NotificationItem> get importantUpdates =>
      _notifications.where((n) => n.isImportant).toList();

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }

  String? _normalizeToken(String? token) {
    if (token == null) return null;
    final trimmed = token.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('Bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  void _handleNotificationFrame(StompFrame frame) {
    final body = frame.body;
    if (body == null) return;
    try {
      final jsonData = jsonDecode(body) as Map<String, dynamic>;
      final newNotification = NotificationItem.fromJson(jsonData);

      // De-duplicate by ID
      if (!_seenIds.contains(newNotification.id)) {
        _seenIds.add(newNotification.id);
        _notifications.insert(0, newNotification);
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (!newNotification.read) {
          _unreadCountServer++;
        }
        debugPrint('🆕 New notification: ${newNotification.title}');
        notifyListeners();
      } else {
        debugPrint('↩️ Duplicate notification ignored: ${newNotification.id}');
      }
    } catch (e) {
      debugPrint('WebSocket JSON parse error: $e');
    }
  }

  bool _looksUnauthorized(String text) {
    final t = text.toLowerCase();
    return t.contains('unauthorized') ||
        t.contains('401') ||
        t.contains('forbidden') ||
        t.contains('403') ||
        t.contains('invalid token') ||
        t.contains('expired') ||
        t.contains('jwt');
  }

  void _handleUnauthorized() {
    _unauthorizedAttempts++;
    if (_unauthorizedAttempts <= _maxUnauthorizedAttempts) {
      return;
    }

    _authInvalid = true;
    _manuallyDisconnected = true;
    _connecting = false;
    _subscribed = false;
    try {
      _stompClient?.deactivate();
    } catch (_) {}
    _stompClient = null;
    debugPrint(
        'WebSocket disabled after repeated unauthorized errors (notifications)');
  }

  String _maskToken(String url) {
    return url.replaceAll(RegExp(r'token=[^&]+'), 'token=***');
  }
}
