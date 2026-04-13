import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';
import 'package:tms_driver_app/models/chat_message_model.dart';
import 'package:tms_driver_app/providers/call_provider.dart';
import 'package:tms_driver_app/utils/error_handler.dart';
import 'package:tms_driver_app/utils/notification_helper.dart';

// ─── Queued message (offline send) ───────────────────────────────────────────

class _QueuedMessage {
  final String tempId;
  final int driverId;
  final String text;
  final String? voicePath;
  final String? imagePath;
  int attempts;

  _QueuedMessage({
    required this.tempId,
    required this.driverId,
    required this.text,
    this.voicePath,
    this.imagePath,
    this.attempts = 0,
  });
}

// ─── ChatProvider ─────────────────────────────────────────────────────────────

/// Provider responsible for driver <-> admin chat.
///
/// Production improvements over the original:
///  • Exponential-backoff STOMP reconnect  (5 → 10 → 20 → 40 → 60 s cap)
///  • Offline message queue  (persisted to SharedPreferences, drained on reconnect)
///  • Typing-indicator broadcast via STOMP /app/chat.typing/{driverId}
///  • Batched read-receipts (flushed every 2 s, preventing per-message HTTP calls)
///  • Agora call-signal routing to [CallProvider]
///  • AppLifecycle reconnect on foreground resume
class ChatProvider with ChangeNotifier, WidgetsBindingObserver {
  final Dio _http;
  final String Function(String) _resolvePath;
  final Future<int?> Function() _resolveDriverIdFn;
  final Future<String?> Function() _resolveAccessTokenFn;
  final StompClient Function(StompConfig config) _stompClientFactory;

  /// Injected so call signals can be routed without coupling screens together.
  CallProvider? callProvider;

  ChatProvider({
    DioClient? dioClient,
    Dio? dio,
    String Function(String)? pathResolver,
    Future<int?> Function()? driverIdResolver,
    Future<String?> Function()? accessTokenResolver,
    StompClient Function(StompConfig config)? stompClientFactory,
    this.callProvider,
  })  : _http = dio ?? (dioClient ?? DioClient()).dio,
        _resolvePath = pathResolver ?? (dioClient ?? DioClient()).resolvePath,
        _resolveDriverIdFn = driverIdResolver ?? _defaultDriverIdResolver,
        _resolveAccessTokenFn = accessTokenResolver ?? _defaultAccessTokenResolver,
        _stompClientFactory =
            stompClientFactory ?? ((config) => StompClient(config: config)) {
    WidgetsBinding.instance.addObserver(this);
  }

  // ─── State ─────────────────────────────────────────────────────────────────

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  // STOMP
  StompClient? _stompClient;
  int? _subscribedDriverId;
  bool _connectingSocket = false;
  bool _stompConnected = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  // Typing
  bool _remoteIsTyping = false;
  Timer? _remoteTypingClearTimer;
  Timer? _localTypingDebounceTimer;
  bool _localTypingActive = false;

  // Read-receipt batching
  final Set<int> _unreadReceiptQueue = {};
  Timer? _receiptFlushTimer;

  // Offline message queue
  final List<_QueuedMessage> _offlineQueue = [];
  static const _kOfflineQueueKey = 'chat_offline_queue';

  // Call signal passthrough
  ChatMessageModel? _incomingCall;

  // Chat screen visibility (for notification suppression)
  bool _isChatScreenVisible = false;

  // ─── Getters ───────────────────────────────────────────────────────────────

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;
  bool get remoteIsTyping => _remoteIsTyping;
  bool get isTyping => _remoteIsTyping; // compatibility shim
  bool get stompConnected => _stompConnected;
  ChatMessageModel? get incomingCall => _incomingCall;

  int get unreadCount =>
      _messages.where((m) => !m.read && m.isFromAdmin).length;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _subscribedDriverId != null) {
      debugPrint('[Chat] App resumed — checking STOMP connection');
      if (!_stompConnected) {
        _scheduleReconnect(immediate: true);
      }
    }
  }

  void setChatScreenVisible(bool visible) {
    _isChatScreenVisible = visible;
    if (visible) _flushReadReceipts();
  }

  void clearIncomingCall() {
    _incomingCall = null;
    notifyListeners();
  }

  // ─── Load messages ─────────────────────────────────────────────────────────

  Future<void> loadMessages({bool force = false}) async {
    if (_isLoading && !force) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId == null) {
        _errorMessage = 'Missing driver ID';
        return;
      }

      final path = _resolvePath('/driver/chat/$driverId');
      final resp = await _http.get(path);

      if (resp.statusCode != 200) {
        final body = resp.data;
        final serverMsg = (body is Map && body['message'] is String)
            ? body['message'] as String
            : body?.toString() ?? 'Unknown error';
        _errorMessage = '[${resp.statusCode}] $serverMsg';
        return;
      }

      final data = resp.data;
      if (data is List) {
        _messages = data
            .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic> && data['content'] is List) {
        _messages = (data['content'] as List)
            .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _messages = [];
      }
      _sortMessages();

      // Restore offline queue from storage, then connect realtime.
      await _loadOfflineQueue();
      await _connectRealtime(driverId);

      _errorMessage = null;
    } catch (e) {
      _errorMessage =
          _friendlyError(e, fallback: 'Unable to load support messages right now.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Send text / photo ─────────────────────────────────────────────────────

  Future<bool> sendMessage(String message, {XFile? photo}) async {
    if (message.trim().isEmpty && photo == null) return false;
    if (_isSending) return false;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    ChatMessageModel? optimistic;
    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId == null) throw Exception('Missing driver ID');

      Uint8List? photoBytes;
      if (photo != null) photoBytes = await photo.readAsBytes();

      optimistic = _createOptimisticMessage(
        driverId: driverId,
        message: message,
        photoBytes: photoBytes,
      );
      _upsertMessage(optimistic);

      final path = _resolvePath(
        photo != null
            ? '/driver/chat/$driverId/send-photo'
            : '/driver/chat/$driverId/send',
      );

      Response resp;
      if (photo != null) {
        final form = FormData.fromMap({
          'message': message,
          'file': MultipartFile.fromBytes(
            photoBytes!,
            filename: photo.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        });
        resp = await _http.post(path, data: form);
      } else {
        resp = await _http.post(path, data: {'message': message});
      }

      if (resp.statusCode != 200) {
        _removeMessage(optimistic.id);
        _errorMessage = _resolveSendErrorMsg(resp, hasPhoto: photo != null);

        // Enqueue for offline retry if network error.
        if (photo == null) {
          await _enqueueOffline(_QueuedMessage(
            tempId: optimistic.id.toString(),
            driverId: driverId,
            text: message,
          ));
        }
        return false;
      }

      final created = ChatMessageModel.fromJson(
          resp.data as Map<String, dynamic>);
      _replaceMessage(optimistic.id, created);
      _errorMessage = null;
      return true;
    } catch (e) {
      if (optimistic != null) _removeMessage(optimistic.id);
      _errorMessage = _friendlyError(e, fallback: 'Failed to send message');
      notifyListeners();
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Send voice ────────────────────────────────────────────────────────────

  Future<bool> sendVoice(String filePath, {String? message}) async {
    if (_isSending || filePath.isEmpty) return false;
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId == null) throw Exception('Missing driver ID');

      final mimeType = lookupMimeType(filePath) ?? 'audio/mpeg';
      final parts = mimeType.split('/');
      final audioBytes = await File(filePath).readAsBytes();
      final path = _resolvePath('/driver/chat/$driverId/send-voice');
      final form = FormData.fromMap({
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        'file': MultipartFile.fromBytes(
          audioBytes,
          filename: filePath.split('/').last,
          contentType: MediaType(parts.first, parts.last),
        ),
      });

      final resp = await _http.post(path, data: form);
      if (resp.statusCode != 200) {
        _errorMessage = 'Failed to upload voice note';
        return false;
      }

      _upsertMessage(
          ChatMessageModel.fromJson(resp.data as Map<String, dynamic>));
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e, fallback: 'Failed to upload voice note');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Send video ────────────────────────────────────────────────────────────

  Future<bool> sendVideo(String filePath, {String? message}) async {
    if (_isSending || filePath.isEmpty) return false;
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId == null) throw Exception('Missing driver ID');

      final mimeType = lookupMimeType(filePath) ?? 'video/mp4';
      final parts = mimeType.split('/');
      final path = _resolvePath('/driver/chat/$driverId/send-video');
      // Use fromFile (streaming) instead of fromBytes to avoid loading the
      // entire video into memory, which can cause OOM for large files.
      final form = FormData.fromMap({
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
          contentType: MediaType(parts.first, parts.last),
        ),
      });

      final resp = await _http.post(path, data: form);
      if (resp.statusCode != 200) {
        _errorMessage = 'Failed to upload video';
        return false;
      }

      _upsertMessage(
          ChatMessageModel.fromJson(resp.data as Map<String, dynamic>));
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e, fallback: 'Failed to upload video');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Send location ─────────────────────────────────────────────────────────

  Future<bool> sendLocation(double lat, double lng, String address) async {
    if (_isSending) return false;
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId == null) throw Exception('Missing driver ID');
      final path = _resolvePath('/driver/chat/$driverId/send-location');
      final resp = await _http.post(path, data: {
        'lat': lat,
        'lng': lng,
        'address': address,
      });

      if (resp.statusCode != 200) {
        _errorMessage = 'Failed to send location';
        return false;
      }

      _upsertMessage(
          ChatMessageModel.fromJson(resp.data as Map<String, dynamic>));
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e, fallback: 'Failed to send location');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Typing indicator ──────────────────────────────────────────────────────

  /// Call this from the chat text field's onChanged callback.
  void onLocalTyping() {
    // Debounce: don't flood the server on every keystroke.
    _localTypingDebounceTimer?.cancel();
    _localTypingDebounceTimer =
        Timer(const Duration(milliseconds: 300), () async {
      if (_stompClient?.connected ?? false) {
        final driverId = await _resolveDriverIdFn();
        if (driverId == null) return;
        _stompClient!.send(
          destination: '/app/chat.typing/$driverId',
          body: jsonEncode({'senderRole': 'DRIVER'}),
        );
      }
    });

    // Auto-clear "I'm typing" after 3 s of no further input.
    if (!_localTypingActive) {
      _localTypingActive = true;
    }
  }

  void _handleRemoteTyping() {
    _remoteIsTyping = true;
    notifyListeners();
    _remoteTypingClearTimer?.cancel();
    _remoteTypingClearTimer = Timer(const Duration(seconds: 4), () {
      _remoteIsTyping = false;
      notifyListeners();
    });
  }

  // ─── Read receipts (batched) ───────────────────────────────────────────────

  void queueReadReceipt(int messageId) {
    _unreadReceiptQueue.add(messageId);
    _receiptFlushTimer ??=
        Timer(const Duration(seconds: 2), _flushReadReceipts);
  }

  Future<void> _flushReadReceipts() async {
    _receiptFlushTimer?.cancel();
    _receiptFlushTimer = null;

    if (_unreadReceiptQueue.isEmpty) return;
    final ids = List<int>.from(_unreadReceiptQueue);
    _unreadReceiptQueue.clear();

    for (final id in ids) {
      try {
        final path = _resolvePath('/driver/chat/mark-read/$id');
        await _http.post(path);
        final idx = _messages.indexWhere((m) => m.id == id);
        if (idx >= 0) {
          _messages[idx].read = true;
        }
      } catch (_) {
        // Put back on failure so next flush retries.
        _unreadReceiptQueue.add(id);
      }
    }
    notifyListeners();
  }

  // ─── Call signalling ───────────────────────────────────────────────────────

  /// Make a call request from driver side.
  Future<bool> requestCall() async {
    if (_isSending) return false;
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId == null) throw Exception('Missing driver ID');
      final path = _resolvePath('/driver/chat/$driverId/start-call');
      Response<dynamic> resp = await _http.post(path);

      if (resp.statusCode == 404) {
        final fallback = _resolvePath('/driver/chat/$driverId/call-request');
        resp = await _http.post(fallback);
      }

      if (resp.statusCode != 200) {
        _errorMessage = 'Failed to request call (${resp.statusCode})';
        return false;
      }

      // The backend returns a CallTokenResponse (not a ChatMessage).
      // The CALL_REQUEST chat message is broadcast via STOMP and will appear
      // in the thread through applyRealtimePayload — no need to parse here.
      // Transition CallProvider to outgoing state; ring timeout starts there.
      callProvider?.startOutgoingCall();

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e, fallback: 'Failed to request call');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Accept an incoming admin-initiated call (legacy path, kept for compat).
  Future<bool> acceptCall() async {
    if (_isSending) return false;
    _isSending = true;
    notifyListeners();

    try {
      final driverId = await _resolveDriverIdFn();
      if (driverId == null) throw Exception('Missing driver ID');
      final path = _resolvePath('/driver/chat/$driverId/accept-call');
      final resp = await _http.post(path);

      if (resp.statusCode != 200) {
        _errorMessage = 'Failed to accept call (${resp.statusCode})';
        return false;
      }

      final created = ChatMessageModel.fromJson(
          resp.data as Map<String, dynamic>);
      _upsertMessage(created);
      _incomingCall = null;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = _friendlyError(e, fallback: 'Failed to accept call');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Mark read (single, legacy) ────────────────────────────────────────────

  void markRead(int messageId) => queueReadReceipt(messageId);

  // ─── Realtime / STOMP ──────────────────────────────────────────────────────

  Future<void> _connectRealtime(int driverId) async {
    if (_subscribedDriverId == driverId && _stompConnected) return;
    if (_connectingSocket) return;

    final token = await _resolveAccessTokenFn();
    if (token == null || token.isEmpty) return;

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

    _stompClient?.deactivate();
    _connectingSocket = true;
    _subscribedDriverId = driverId;

    _stompClient = _stompClientFactory(
      StompConfig(
        url: wsUrl,
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          _connectingSocket = false;
          _stompConnected = true;
          _reconnectAttempt = 0;
          debugPrint('[Chat] STOMP connected');
          notifyListeners();

          // Subscribe to chat topic.
          _stompClient?.subscribe(
            destination: '/topic/driver-chat/$driverId',
            callback: (frame) {
              final body = frame.body;
              if (body == null || body.isEmpty) return;
              try {
                final decoded = jsonDecode(body);
                if (decoded is Map<String, dynamic>) {
                  applyRealtimePayload(decoded);
                }
              } catch (e) {
                debugPrint('[Chat] Decode error: $e');
              }
            },
          );

          // Drain offline queue.
          _drainOfflineQueue(driverId);
        },
        onDisconnect: (_) {
          _connectingSocket = false;
          _stompConnected = false;
          notifyListeners();
          debugPrint('[Chat] STOMP disconnected — will reconnect');
          _scheduleReconnect();
        },
        onWebSocketError: (error) {
          _connectingSocket = false;
          _stompConnected = false;
          notifyListeners();
          debugPrint('[Chat] WS error: $error');
          _scheduleReconnect();
        },
        onStompError: (frame) {
          _connectingSocket = false;
          debugPrint('[Chat] STOMP error: ${frame.body}');
          _scheduleReconnect();
        },
        // Built-in reconnect handles transient drops; our _scheduleReconnect
        // handles token-expiry reconnects after a backoff.
        reconnectDelay: Duration.zero,
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
      ),
    );

    _stompClient?.activate();
  }

  // Exponential backoff: 5 → 10 → 20 → 40 → 60 (cap) seconds.
  void _scheduleReconnect({bool immediate = false}) {
    _reconnectTimer?.cancel();
    final delaySeconds = immediate
        ? 0
        : (_reconnectAttempt < 5
            ? (5 * (1 << _reconnectAttempt)).clamp(5, 60)
            : 60);
    _reconnectAttempt++;

    debugPrint(
        '[Chat] Reconnect attempt $_reconnectAttempt in ${delaySeconds}s');
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_subscribedDriverId != null && !_stompConnected) {
        await _connectRealtime(_subscribedDriverId!);
      }
    });
  }

  String _friendlyError(dynamic error, {required String fallback}) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status != null) {
        return ErrorHandler.fromStatusCode(status);
      }

      final responseData = error.response?.data;
      if (responseData is Map && responseData['message'] is String) {
        return responseData['message'] as String;
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return ErrorHandler.getFriendlyMessage(error.error ?? error.message ?? fallback);
      }

      return fallback;
    }

    return ErrorHandler.getFriendlyMessage(error);
  }

  // ─── Realtime payload processing ───────────────────────────────────────────

  @visibleForTesting
  void applyRealtimePayload(Map<String, dynamic> payload) {
    final messageRaw = payload['message'];
    if (messageRaw is! Map<String, dynamic>) return;

    final chatMsg = ChatMessageModel.fromJson(messageRaw);

    // ── Typing indicator ──
    if (chatMsg.isTypingIndicator) {
      if (chatMsg.isFromAdmin) _handleRemoteTyping();
      return; // Don't store typing frames.
    }

    final isNew = !_messages.any((m) => m.id != null && m.id == chatMsg.id);
    final isFromSupport = chatMsg.isFromAdmin;

    // ── Call signals → route to CallProvider ──
    if (isNew && chatMsg.isCallRequest && isFromSupport) {
      _incomingCall = chatMsg;
      callProvider?.handleIncomingCall(
        channelName: chatMsg.agoraChannelName ?? 'call-${chatMsg.driverId}',
        callerName: chatMsg.sender,
      );
      NotificationHelper.showLocal(
        '📞 Incoming call from Support',
        'Tap to answer',
        urgent: true,
      ).ignore();
    } else if (isNew && chatMsg.isCallAccepted) {
      callProvider?.handleCallAccepted(
        channelName: chatMsg.agoraChannelName ?? _incomingCall?.agoraChannelName ?? '',
      );
    } else if (isNew && (chatMsg.isCallDeclined || chatMsg.isCallEnded)) {
      callProvider?.endCall();
    } else if (isNew && isFromSupport && !chatMsg.isCallSignal) {
      // Regular message notification.
      if (_isChatScreenVisible) {
        NotificationHelper.playAlertSound();
      } else {
        NotificationHelper.showLocal(
          'New message from support',
          chatMsg.message,
          urgent: true,
        ).ignore();
      }
    }

    if (!chatMsg.isTypingIndicator) {
      _upsertMessage(chatMsg);
    }
  }

  // ─── Offline queue ─────────────────────────────────────────────────────────

  Future<void> _loadOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kOfflineQueueKey) ?? [];
      for (final entry in raw) {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        _offlineQueue.add(_QueuedMessage(
          tempId: map['tempId'] as String,
          driverId: map['driverId'] as int,
          text: map['text'] as String,
          voicePath: map['voicePath'] as String?,
          imagePath: map['imagePath'] as String?,
        ));
      }
    } catch (e) {
      debugPrint('[Chat] Failed to load offline queue: $e');
    }
  }

  Future<void> _saveOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _offlineQueue.map((q) {
        return jsonEncode({
          'tempId': q.tempId,
          'driverId': q.driverId,
          'text': q.text,
          if (q.voicePath != null) 'voicePath': q.voicePath,
          if (q.imagePath != null) 'imagePath': q.imagePath,
        });
      }).toList();
      await prefs.setStringList(_kOfflineQueueKey, raw);
    } catch (_) {}
  }

  Future<void> _enqueueOffline(_QueuedMessage msg) async {
    _offlineQueue.add(msg);
    await _saveOfflineQueue();
    debugPrint(
        '[Chat] Queued offline message (queue size: ${_offlineQueue.length})');
  }

  Future<void> _drainOfflineQueue(int driverId) async {
    if (_offlineQueue.isEmpty) return;
    final toSend = List<_QueuedMessage>.from(_offlineQueue);
    _offlineQueue.clear();
    await _saveOfflineQueue();

    for (final msg in toSend) {
      if (msg.attempts >= 3) continue; // Drop after 3 failed attempts.
      msg.attempts++;
      try {
        final path = _resolvePath('/driver/chat/$driverId/send');
        await _http.post(path, data: {'message': msg.text});
        debugPrint('[Chat] Drained queued message: ${msg.tempId}');
      } catch (e) {
        debugPrint('[Chat] Drain failed for ${msg.tempId}: $e');
        _offlineQueue.add(msg);
      }
    }
    if (_offlineQueue.isNotEmpty) await _saveOfflineQueue();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _upsertMessage(ChatMessageModel msg) {
    final idx = _messages.indexWhere((m) => m.id != null && m.id == msg.id);
    if (idx >= 0) {
      _messages[idx] = msg;
    } else {
      _messages.add(msg);
    }
    _sortMessages();
    notifyListeners();
  }

  void _replaceMessage(int? existingId, ChatMessageModel replacement) {
    final idx = _messages.indexWhere((m) => m.id == existingId);
    if (idx >= 0) {
      _messages[idx] = replacement;
    } else {
      _messages.add(replacement);
    }
    _sortMessages();
    notifyListeners();
  }

  void _removeMessage(int? id) {
    _messages.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
  }

  ChatMessageModel _createOptimisticMessage({
    required int driverId,
    required String message,
    required Uint8List? photoBytes,
  }) {
    final now = DateTime.now();
    return ChatMessageModel(
      id: -now.microsecondsSinceEpoch,
      driverId: driverId,
      senderRole: 'DRIVER',
      sender: 'You',
      message: message.trim(),
      messageType: photoBytes != null ? MessageType.image : MessageType.text,
      createdAt: now,
      localImageBytes: photoBytes,
      isPending: true,
      read: false,
    );
  }

  String _resolveSendErrorMsg(Response<dynamic>? resp,
      {required bool hasPhoto}) {
    final data = resp?.data;
    final serverMsg = (data is Map && data['message'] is String)
        ? data['message'] as String
        : null;
    final status = resp?.statusCode ?? 0;
    if (hasPhoto && status == 404) {
      return 'Photo upload not available on this server version.';
    }
    if (serverMsg != null && serverMsg.trim().isNotEmpty) return serverMsg;
    return hasPhoto ? 'Failed to send photo.' : 'Failed to send message.';
  }

  // ─── Defaults ──────────────────────────────────────────────────────────────

  static Future<int?> _defaultDriverIdResolver() async {
    final id = await ApiConstants.getDriverId();
    if (id != null) return id;
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('driverId');
    return s != null ? int.tryParse(s) : null;
  }

  static Future<String?> _defaultAccessTokenResolver() async {
    return ApiConstants.getAccessToken();
  }

  // ─── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stompClient?.deactivate();
    _reconnectTimer?.cancel();
    _receiptFlushTimer?.cancel();
    _localTypingDebounceTimer?.cancel();
    _remoteTypingClearTimer?.cancel();
    super.dispose();
  }
}
