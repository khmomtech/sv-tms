// import 'dart:async';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/status.dart' as status;
// import 'package:flutter/foundation.dart';

// class WebSocketManager {
//   final String url;
//   final ValueChanged<String>? onMessage;
//   final VoidCallback? onConnected;
//   final VoidCallback? onDisconnected;
//   final ValueChanged<bool>? onReconnectingStatus;
//   final ValueChanged<dynamic>? onError;

//   WebSocketChannel? _channel;
//   Timer? _reconnectTimer;
//   bool _manuallyClosed = false;
//   bool _isConnected = false;

//   int _retryAttempts = 0;
//   static const int _maxRetryAttempts = 5;
//   static const Duration _baseDelay = Duration(seconds: 2);

//   WebSocketManager({
//     required this.url,
//     this.onMessage,
//     this.onConnected,
//     this.onDisconnected,
//     this.onReconnectingStatus,
//     this.onError,
//   });

//   ///  Start WebSocket connection
//   void connect() {
//     _manuallyClosed = false;
//     _retryAttempts = 0;
//     _openConnection();
//   }

//   /// 🌐 Establish the WebSocket connection
//   void _openConnection() {
//     try {
//       debugPrint('[ WebSocket] Connecting to $url');
//       _channel = WebSocketChannel.connect(Uri.parse(url));
//       _isConnected = true;

//       onConnected?.call();
//       onReconnectingStatus?.call(false);
//       _retryAttempts = 0;

//       _channel!.stream.listen(
//         (message) {
//           debugPrint('[📨 WebSocket] Message received: $message');
//           onMessage?.call(message);
//         },
//         onDone: () {
//           debugPrint('[ WebSocket] Disconnected (onDone)');
//           _handleDisconnect();
//         },
//         onError: (error) {
//           debugPrint('[ WebSocket] Error: $error');
//           _handleError(error);
//         },
//         cancelOnError: true,
//       );
//     } catch (e) {
//       debugPrint('[ WebSocket] Exception on connect: $e');
//       _handleError(e);
//     }
//   }

//   /// 🚫 Handle disconnection
//   void _handleDisconnect() {
//     _isConnected = false;
//     onDisconnected?.call();

//     if (!_manuallyClosed) {
//       _scheduleReconnect();
//     }
//   }

//   /// Handle error event
//   void _handleError(dynamic error) {
//     _isConnected = false;
//     onError?.call(error);

//     if (!_manuallyClosed) {
//       _scheduleReconnect();
//     }
//   }

//   ///  Reconnect logic with exponential backoff
//   void _scheduleReconnect() {
//     if (_retryAttempts >= _maxRetryAttempts) {
//       debugPrint('[ WebSocket] Max retry attempts reached.');
//       return;
//     }

//     _reconnectTimer?.cancel();
//     _retryAttempts++;

//     final delaySeconds = _calculateExponentialDelay();
//     debugPrint(
//         '[ WebSocket Retry] Attempt $_retryAttempts - Retrying in ${delaySeconds}s');

//     onReconnectingStatus?.call(true);

//     _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
//       if (!_manuallyClosed) {
//         _openConnection();
//       }
//     });
//   }

//   /// ⏱️ Calculate exponential backoff delay
//   int _calculateExponentialDelay() {
//     final exponent = (_retryAttempts <= _maxRetryAttempts)
//         ? _retryAttempts - 1
//         : _maxRetryAttempts - 1;
//     return _baseDelay.inSeconds * (1 << exponent);
//   }

//   ///  Send message safely
//   void send(String message) {
//     if (_isConnected && _channel != null) {
//       try {
//         _channel!.sink.add(message);
//         debugPrint('[ WebSocket] Sent: $message');
//       } catch (e) {
//         debugPrint('[ WebSocket] Send failed: $e');
//         _handleError(e);
//       }
//     } else {
//       debugPrint('[ WebSocket] Cannot send, not connected.');
//     }
//   }

//   /// 📴 Manual close
//   void close() {
//     _manuallyClosed = true;
//     _reconnectTimer?.cancel();

//     try {
//       _channel?.sink.close(status.goingAway);
//       debugPrint('[ WebSocket] Closed manually');
//     } catch (e) {
//       debugPrint('[ WebSocket] Error during close: $e');
//     } finally {
//       _isConnected = false;
//     }
//   }

//   /// 🔍 Check current connection status
//   bool get isConnected => _isConnected;
// }
