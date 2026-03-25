import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketManager {
  final Duration reconnectDelay;
  final ValueChanged<String>? onMessage;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final Function(dynamic error)? onError;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _manuallyClosed = false;
  bool _isConnected = false;
  bool _authInvalid = false;

  WebSocketManager({
    this.reconnectDelay = const Duration(seconds: 5),
    this.onMessage,
    this.onConnected,
    this.onDisconnected,
    this.onError,
  });

  /// 🌐 Start WebSocket connection
  void connect() {
    _manuallyClosed = false;
    _authInvalid = false;
    _initConnection();
  }

  /// 🛠 Initialize WebSocket connection
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
      final wsUrl = await ApiConstants.getDriverLocationWebSocketUrlWithToken(token);
      debugPrint('[🌐 WebSocket] Connecting to: ${wsUrl.replaceAll(RegExp(r'token=[^&]+'), 'token=***')}');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      onConnected?.call();

      _channel!.stream.listen(
        (message) {
          debugPrint('[📨 WebSocket] Message received: $message');
          onMessage?.call(message);
        },
        onDone: () {
          _isConnected = false;
          debugPrint('[WebSocket] Connection closed.');
          onDisconnected?.call();
          if (!_manuallyClosed && !_authInvalid) _scheduleReconnect();
        },
        onError: (error) {
          _isConnected = false;
          debugPrint('[ WebSocket] Error: $error');
          onError?.call(error);
          if (!_manuallyClosed && !_authInvalid) _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isConnected = false;
      debugPrint('[ WebSocket] Exception during connect: $e');
      onError?.call(e);
      if (!_authInvalid) _scheduleReconnect();
    }
  }

  ///  Schedule a reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;

    _reconnectTimer = Timer(reconnectDelay, () {
      if (!_manuallyClosed) {
        debugPrint('[ WebSocket] Attempting to reconnect...');
        connect();
      }
    });
  }

  ///  Send message through the socket
  void send(String message) {
    try {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(message);
        debugPrint('[ WebSocket] Message sent: $message');
      } else {
        debugPrint('[WebSocket] Cannot send, not connected.');
      }
    } catch (e) {
      debugPrint('[ WebSocket] Error sending message: $e');
      onError?.call(e);
    }
  }

  ///  Manually close the WebSocket connection
  void close() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    try {
      _channel?.sink.close(status.goingAway);
      debugPrint('[ WebSocket] Connection closed manually.');
    } catch (e) {
      debugPrint('[ WebSocket] Error during manual close: $e');
    }
  }

  ///  Check if WebSocket is currently connected
  bool get isConnected => _isConnected;
}
