import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../services/auth_service.dart';

// Simple notification model - adapt as needed
class NotificationItem {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      read: json['read'] as bool? ?? false,
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  final AuthService authService;
  final String wsBaseUrl;

  StompClient? _stompClient;
  bool _connecting = false;
  bool _subscribed = false;
  String? _lastToken;
  String? _lastCustomerId;
  int _reconnectAttempts = 0;
  bool _manuallyDisconnected = false;

  final List<NotificationItem> _notifications = [];
  final Set<int> _seenIds = {};
  int _unreadCountServer = 0;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCountServer;
  bool get isConnected => _stompClient?.connected == true;

  NotificationProvider({
    required this.authService,
    String? baseUrl,
  }) : wsBaseUrl = _convertToWsUrl(baseUrl ?? 'http://localhost:8080') {
    // Listen to auth changes to auto-connect/disconnect
    authService.addListener(_onAuthChanged);
  }

  /// Convert HTTP(S) URL to WS(S) URL
  static String _convertToWsUrl(String httpUrl) {
    final uri = Uri.parse(httpUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.host}:${uri.port}/ws';
  }

  void _onAuthChanged() async {
    if (authService.isAuthenticated && authService.currentUser != null) {
      // Check if we have a valid token before connecting
      final token = await authService.getToken();
      if (token != null && token.isNotEmpty) {
        // Prefer numeric customerId when available; fall back to username
        final usr = authService.currentUser!;
        final customerId = usr.customerId != null
            ? usr.customerId!.toString()
            : usr.username;
        connectWebSocket(customerId);
      } else {
        debugPrint(
            '[WS] No valid token available, skipping WebSocket connection');
        disconnectWebSocket();
      }
    } else {
      disconnectWebSocket();
    }
  }

  /// 🔔 Connect to WebSocket (/ws, not /ws-sockjs)
  Future<void> connectWebSocket(String customerId) async {
    // Avoid duplicate connects
    if (_stompClient?.connected == true) {
      debugPrint('[WS] ℹ️ WebSocket already connected');
      return;
    }
    if (_connecting) {
      debugPrint('[WS] ℹ️ WebSocket connection is in progress');
      return;
    }

    final token = await authService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[WS] Missing token for WebSocket');
      return;
    }

    // Check if user is still authenticated
    if (!authService.isAuthenticated) {
      debugPrint(
          '[WS] User not authenticated, skipping WebSocket connection');
      return;
    }

    // If token changed, ensure clean reconnect
    final tokenChanged = (_lastToken != null && _lastToken != token);
    _lastToken = token;
    _lastCustomerId = customerId;

    _manuallyDisconnected = false;
    _subscribed = false;
    _reconnectAttempts = tokenChanged ? 0 : _reconnectAttempts;

    // Build WebSocket URL dynamically from base URL
    final wsUrl = '$wsBaseUrl?token=$token';

    debugPrint('[WS] Connecting to WebSocket: $wsUrl');
    debugPrint('[WS] Customer ID: $customerId');
    debugPrint('[WS] Token length: ${token.length}');

    // Cleanup previous client if any
    _stompClient?.deactivate();

    _connecting = true;
    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          debugPrint('[WS] STOMP WebSocket connected successfully');
          debugPrint('[WS] Connection frame: ${frame.toString()}');
          _connecting = false;
          _reconnectAttempts = 0;

          final topic = '/topic/customer-notification/$customerId';
          if (!_subscribed) {
            debugPrint('Subscribing to $topic');
            _stompClient?.subscribe(
              destination: topic,
              callback: (frame) {
                final body = frame.body;
                if (body == null) return;
                try {
                  final jsonData = jsonDecode(body) as Map<String, dynamic>;
                  final newNotification = NotificationItem.fromJson(jsonData);

                  // De-duplicate by ID
                  if (!_seenIds.contains(newNotification.id)) {
                    _seenIds.add(newNotification.id);
                    _notifications.insert(0, newNotification);
                    _notifications
                        .sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    if (!newNotification.read) {
                      _unreadCountServer++;
                    }
                    debugPrint('🆕 New notification: ${newNotification.title}');
                    notifyListeners();
                  } else {
                    debugPrint(
                        '↩️ Duplicate notification ignored: ${newNotification.id}');
                  }
                } catch (e) {
                  debugPrint('WebSocket JSON parse error: $e');
                }
              },
            );
            _subscribed = true;
          }
        },
        onStompError: (frame) {
          debugPrint('[WS] STOMP Error: ${frame.body}');
        },
        onWebSocketError: (error) {
          debugPrint('[WS] WebSocket transport error: $error');
          // If it's an authentication error, don't retry immediately
          if (error.toString().contains('401') ||
              error.toString().contains('403')) {
            debugPrint(
                '[WS] Authentication error detected, stopping reconnection attempts');
            _manuallyDisconnected = true;
          }
        },
        onDisconnect: (frame) {
          debugPrint('[WS] 🛑 WebSocket connection closed');
          debugPrint('[WS] Disconnect frame: ${frame.toString()}');
          _connecting = false;
          _subscribed = false;
          if (!_manuallyDisconnected) {
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
    if (_reconnectAttempts > 10) {
      debugPrint('[WS] Too many reconnect attempts, giving up');
      return;
    }

    _reconnectAttempts++;
    // base backoff = 5s, cap at 60s, add jitter up to +2s to avoid thundering herd
    final base = min(60, 5 * _reconnectAttempts);
    final jitter = Random().nextInt(3); // 0..2 seconds
    final delay = Duration(seconds: base + jitter);
    debugPrint(
        '[WS]Attempting WebSocket reconnect in ${delay.inSeconds}s... (attempt $_reconnectAttempts)');

    Future.delayed(delay, () async {
      if (_manuallyDisconnected) return;

      // Check if still authenticated before reconnecting
      if (!authService.isAuthenticated) {
        debugPrint('[WS] User no longer authenticated, stopping reconnection');
        return;
      }

      final customerId = _lastCustomerId;
      final token = await authService.getToken();
      if (customerId == null || token == null) {
        debugPrint('[WS] Missing customerId or token for reconnection');
        return;
      }
      connectWebSocket(customerId);
    });
  }

  /// ✋ Manual disconnect
  void disconnectWebSocket() {
    _manuallyDisconnected = true;
    _subscribed = false;
    _connecting = false;
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

  @override
  void dispose() {
    authService.removeListener(_onAuthChanged);
    disconnectWebSocket();
    super.dispose();
  }
}
