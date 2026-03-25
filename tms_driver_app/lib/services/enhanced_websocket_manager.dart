import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

/// 🌐 Enhanced WebSocket Manager with Exponential Backoff
/// Implements production-ready reconnection strategy with:
/// - Exponential backoff (5s → 60s cap)
/// - Jitter to prevent thundering herd
/// - Connection health monitoring
/// - Automatic ping/pong heartbeat
class EnhancedWebSocketManager {
  final ValueChanged<String>? onMessage;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final Function(dynamic error)? onError;
  final Duration Function(int attempt)? customBackoffStrategy;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _manuallyClosed = false;
  bool _isConnected = false;
  bool _authInvalid = false;
  int _reconnectAttempts = 0;
  DateTime? _lastMessageReceivedAt;
  DateTime? _lastConnectedAt;

  // Backoff configuration
  static const int _baseBackoffSeconds = 5;
  static const int _maxBackoffSeconds = 60;
  static const int _maxJitterSeconds = 3;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _heartbeatTimeout = Duration(seconds: 90);

  EnhancedWebSocketManager({
    this.onMessage,
    this.onConnected,
    this.onDisconnected,
    this.onError,
    this.customBackoffStrategy,
  });

  /// 🌐 Start WebSocket connection
  void connect() {
    _manuallyClosed = false;
    _authInvalid = false;
    _initConnection();
  }

  /// 🛠 Initialize WebSocket connection with timeout
  Future<void> _initConnection() async {
    try {
      final token = await ApiConstants.ensureFreshTrackingToken() ??
          await ApiConstants.ensureFreshAccessToken();
      if (token == null || token.isEmpty) {
        _authInvalid = true;
        debugPrint('[🌐 WebSocket] 🚫 No valid token; abort connect');
        onError?.call(StateError('No valid token'));
        return;
      }

      final wsUrl =
          await ApiConstants.getDriverLocationWebSocketUrlWithToken(token);
      debugPrint(
          '[🌐 WebSocket] Connecting (attempt ${_reconnectAttempts + 1}) to: ${_maskToken(wsUrl)}');

      // Create connection with timeout
      final connectFuture = _createConnection(wsUrl);
      final timeoutFuture = Future.delayed(_connectionTimeout, () {
        throw TimeoutException(
            'WebSocket connection timeout after ${_connectionTimeout.inSeconds}s');
      });

      await Future.any([connectFuture, timeoutFuture]);

      _isConnected = true;
      _reconnectAttempts = 0; // Reset on successful connection
      _lastConnectedAt = DateTime.now();
      _startHeartbeat();
      onConnected?.call();

      debugPrint(
          '[WebSocket] Connected successfully at ${_lastConnectedAt!.toIso8601String()}');
    } catch (e) {
      _isConnected = false;
      debugPrint('[WebSocket] Connection failed: $e');
      onError?.call(e);
      if (!_authInvalid && !_manuallyClosed) {
        _scheduleReconnect();
      }
    }
  }

  /// 🔗 Create WebSocket connection
  Future<void> _createConnection(String wsUrl) async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          _lastMessageReceivedAt = DateTime.now();
          debugPrint('[📨 WebSocket] Message received: $message');

          // Handle ping/pong heartbeat
          if (message == 'ping') {
            _sendPong();
            return;
          }

          onMessage?.call(message);
        },
        onDone: () {
          _isConnected = false;
          _stopHeartbeat();
          debugPrint('[WebSocket] Connection closed.');
          onDisconnected?.call();
          if (!_manuallyClosed && !_authInvalid) {
            _scheduleReconnect();
          }
        },
        onError: (error) {
          _isConnected = false;
          _stopHeartbeat();
          
          // Check if error is 401 Unauthorized
          final errorStr = error.toString().toLowerCase();
          if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
            debugPrint('[WebSocket] 401 Unauthorized error detected - forcing token refresh');
            _handle401Error();
            return;
          }
          
          debugPrint('[WebSocket] Stream error: $error');
          onError?.call(error);
          if (!_manuallyClosed && !_authInvalid) {
            _scheduleReconnect();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      // Check for 401 in connection error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
        debugPrint('[WebSocket] 401 during connection - forcing token refresh');
        _handle401Error();
      }
      rethrow;
    }
  }

  /// 🔐 Handle 401 Unauthorized - force token refresh and reconnect
  Future<void> _handle401Error() async {
    debugPrint('[🔐 WebSocket] Handling 401 - will refresh token and retry');
    _isConnected = false;
    _stopHeartbeat();
    
    try {
      // Close existing connection
      _channel?.sink.close(status.goingAway);
      _channel = null;
    } catch (_) {}

    // Force token refresh (clearTokens not needed - refreshAccessToken handles expired tokens)
    final newToken = await ApiConstants.refreshAccessToken();
    if (newToken == null || newToken.isEmpty) {
      debugPrint('[WebSocket] Token refresh failed - marking auth invalid');
      _authInvalid = true;
      onError?.call(StateError('Token refresh failed after 401'));
      return;
    }

    // Schedule reconnect with fresh token (shorter delay for auth refresh)
    debugPrint('[WebSocket] Token refreshed successfully, reconnecting in 2s');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (!_manuallyClosed && !_authInvalid) {
        _reconnectAttempts = 0; // Reset attempts after successful auth
        _initConnection();
      }
    });
  }

  ///Schedule reconnection with exponential backoff + jitter
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) {
      debugPrint('[⏳ WebSocket] Reconnect timer already active');
      return;
    }

    _reconnectAttempts++;

    // Calculate delay: exponential backoff with cap + jitter
    final int delaySeconds = customBackoffStrategy != null
        ? customBackoffStrategy!(_reconnectAttempts).inSeconds
        : _calculateBackoff(_reconnectAttempts);

    final delay = Duration(seconds: delaySeconds);

    debugPrint(
        '[♻️ WebSocket] Scheduling reconnect #$_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer = Timer(delay, () {
      if (!_manuallyClosed) {
        debugPrint('[WebSocket] Attempting reconnect #$_reconnectAttempts...');
        _initConnection();
      }
    });
  }

  /// 📐 Calculate exponential backoff with jitter
  int _calculateBackoff(int attempt) {
    // Exponential: 5s, 10s, 20s, 40s, 60s (capped)
    final baseDelay = min(_baseBackoffSeconds * pow(2, attempt - 1).toInt(),
        _maxBackoffSeconds);

    // Add random jitter (0-3 seconds) to prevent thundering herd
    final jitter = Random().nextInt(_maxJitterSeconds + 1);

    return baseDelay + jitter;
  }

  /// 💓 Start heartbeat timer (ping server every 30s)
  void _startHeartbeat() {
    _stopHeartbeat(); // Clear any existing timer

    _heartbeatTimer =
        Timer.periodic(_heartbeatInterval, (timer) {
      if (!_isConnected) {
        _stopHeartbeat();
        return;
      }

      // Check if we've received any message recently
      if (_lastMessageReceivedAt != null) {
        final timeSinceLastMessage =
            DateTime.now().difference(_lastMessageReceivedAt!);

        if (timeSinceLastMessage > _heartbeatTimeout) {
          debugPrint(
              '[💔 WebSocket] Heartbeat timeout (${timeSinceLastMessage.inSeconds}s since last message)');
          _handleConnectionDead();
          return;
        }
      }

      // Send ping
      _sendPing();
    });

    debugPrint('[💓 WebSocket] Heartbeat started (${_heartbeatInterval.inSeconds}s interval)');
  }

  /// 🛑 Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 🏓 Send ping message
  void _sendPing() {
    try {
      if (_isConnected && _channel != null) {
        _channel!.sink.add('ping');
        debugPrint('[🏓 WebSocket] Ping sent');
      }
    } catch (e) {
      debugPrint('[WebSocket] Failed to send ping: $e');
      _handleConnectionDead();
    }
  }

  /// 🏓 Send pong response
  void _sendPong() {
    try {
      if (_isConnected && _channel != null) {
        _channel!.sink.add('pong');
        debugPrint('[🏓 WebSocket] Pong sent');
      }
    } catch (e) {
      debugPrint('[WebSocket] Failed to send pong: $e');
    }
  }

  /// 💀 Handle dead connection
  void _handleConnectionDead() {
    debugPrint('[💀 WebSocket] Connection appears dead, forcing reconnect');
    _isConnected = false;
    _stopHeartbeat();
    try {
      _channel?.sink.close(status.abnormalClosure);
    } catch (_) {}
    _channel = null;

    if (!_manuallyClosed && !_authInvalid) {
      _scheduleReconnect();
    }
  }

  /// 📤 Send message through the socket
  void send(String message) {
    try {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(message);
        debugPrint('[📤 WebSocket] Message sent: $message');
      } else {
        debugPrint('[WebSocket] Cannot send, not connected. Buffering not implemented.');
        // TODO: Implement message buffering for offline queue
      }
    } catch (e) {
      debugPrint('[WebSocket] Error sending message: $e');
      onError?.call(e);
    }
  }

  /// 🛑 Manually close the WebSocket connection
  void close() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    try {
      _channel?.sink.close(status.goingAway);
      _isConnected = false;
      debugPrint('[🛑 WebSocket] Connection closed manually.');
    } catch (e) {
      debugPrint('[WebSocket] Error during manual close: $e');
    }
  }

  /// 🔍 Get connection status
  bool get isConnected => _isConnected;

  /// 📊 Get connection stats (for debugging)
  Map<String, dynamic> getConnectionStats() {
    return {
      'connected': _isConnected,
      'reconnectAttempts': _reconnectAttempts,
      'lastConnectedAt': _lastConnectedAt?.toIso8601String(),
      'lastMessageReceivedAt': _lastMessageReceivedAt?.toIso8601String(),
      'manuallyDisconnected': _manuallyClosed,
      'authInvalid': _authInvalid,
      'uptime': _lastConnectedAt != null
          ? DateTime.now().difference(_lastConnectedAt!).inSeconds
          : 0,
    };
  }

  /// Mask token in URL for logging
  String _maskToken(String url) {
    return url.replaceAll(RegExp(r'token=[^&]+'), 'token=***');
  }

  /// 🧹 Dispose resources
  void dispose() {
    close();
  }
}
