import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/services/location_service.dart';
import 'package:tms_driver_app/services/native_service_bridge.dart';
import 'package:tms_driver_app/services/session_manager.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();
  static WebSocketService get instance => _instance;

  StompClient? _client;
  StompUnsubscribe? _subscription;
  Timer? _healthCheckTimer;
  Timer? _reconnectTimer;
  Timer? _stabilityTimer;

  bool _manuallyDisconnected = false;
  bool _connecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  bool _authInvalid = false;
  int _consecutiveUnauthorizedErrors = 0;
  static const int _maxUnauthorizedRetries = 3;
  DateTime? _wsDegradedUntil;
  static const Duration _wsDegradedCooldown = Duration(minutes: 3);
  bool _intentionalDeactivate = false;
  int _connectionGeneration = 0;
  static const Duration _stableConnectionWindow = Duration(seconds: 20);

  final ValueNotifier<bool> connectionStatus = ValueNotifier(false);

  Function(Map<String, dynamic>)? onLocationReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String error)? onError;

  // ---- Auth / token rotation ----
  Future<String?> Function()? _tokenProvider; // set on connect
  String? _currentToken; // last token used for WS headers

  DateTime? _lastSentTime;
  static const String destination = '/app/location.update';

  String _getTopic(String driverId) => '/topic/driver-location/$driverId';

  Future<String?> _resolveTrackingAwareToken() async {
    final tracking = await ApiConstants.ensureFreshTrackingToken();
    if (tracking != null && tracking.isNotEmpty) return tracking;
    return await ApiConstants.ensureFreshAccessToken();
  }

  String? _cachedDriverId;
  Future<String?> _driverId() async {
    if (_cachedDriverId != null) return _cachedDriverId;
    final prefs = await SharedPreferences.getInstance();
    _cachedDriverId = prefs.getString('driverId');
    return _cachedDriverId;
  }

  bool get isConnected => _client?.connected ?? false;

  /// Establishes the WS connection.
  /// Provide a [tokenProvider] that returns a **fresh** access token on demand.
  Future<void> connect({
    required Future<String?> Function() tokenProvider,
  }) async {
    _tokenProvider = tokenProvider;
    _authInvalid = false;
    if (_connecting || isConnected) return;
    _manuallyDisconnected = false;
    await _initializeClient(freshAuth: true);
  }

  Future<void> _initializeClient({bool freshAuth = false}) async {
    _connecting = true;
    try {
      _reconnectTimer?.cancel();
      final generation = ++_connectionGeneration;

      // Always fetch a fresh token at connect-time
      final token = await (_tokenProvider?.call() ?? _resolveTrackingAwareToken());
      final rawToken = _normalizeToken(token);
      _currentToken = rawToken;
      if (rawToken == null || rawToken.isEmpty) {
        _authInvalid = false;
        onError?.call('No valid token available for WebSocket yet');
        debugPrint('[WS] Missing token at connect-time; delaying reconnect instead of forcing logout');
        _autoReconnect();
        return;
      }

      final wsBase = await ApiConstants
          .getDriverLocationWebSocketUrl(); // e.g. wss://host/ws
      // Include token in query for servers that don't read Authorization on WS upgrade.
      final encodedToken = Uri.encodeQueryComponent(rawToken);
      final url = '$wsBase?token=$encodedToken';

      if (kDebugMode) {
        debugPrint('[WS] Connecting → $url  (auth header: true)');
      }

      final client = StompClient(
        config: StompConfig(
          url: url,
          onConnect: (frame) {
            if (!_isCurrentGeneration(generation)) return;
            _onConnect(frame);
          },
          onStompError: (frame) {
            if (!_isCurrentGeneration(generation)) return;
            _handleStompError(frame);
          },
          onWebSocketError: (err) {
            if (!_isCurrentGeneration(generation)) return;
            _handleError(err);
          },
          onDisconnect: (_) {
            if (!_isCurrentGeneration(generation)) return;
            _onDisconnect();
          },
          onWebSocketDone: () {
            if (!_isCurrentGeneration(generation)) return;
            _onDisconnect();
          },
          // Do not enforce incoming heartbeats; some brokers do not emit them
          // consistently which causes unnecessary disconnect/reconnect loops.
          heartbeatIncoming: Duration.zero,
          heartbeatOutgoing: const Duration(seconds: 15),
          // Prefer Authorization header
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $rawToken',
          },
          // If your broker requires STOMP headers too, you can add:
          stompConnectHeaders: {
            'Authorization': 'Bearer $rawToken',
          },
        ),
      );

      _client = client;
      client.activate();
    } finally {
      _connecting = false;
    }
  }

  bool _isCurrentGeneration(int generation) =>
      generation == _connectionGeneration;

  void _onConnect(StompFrame frame) {
    debugPrint('[WS] Connected (v=${frame.headers['version'] ?? '—'})');
    connectionStatus.value = true;
    _consecutiveUnauthorizedErrors = 0;
    _reconnectTimer?.cancel();
    _stabilityTimer?.cancel();
    _stabilityTimer = Timer(_stableConnectionWindow, () {
      _reconnectAttempts = 0;
    });
    onConnected?.call();

    // Subscribe to driver-specific location updates
    _resubscribeDriverTopic();

    _startHealthCheckPing();
  }

  Future<void> _resubscribeDriverTopic() async {
    _subscription?.call();
    _subscription = null;

    final driverId = await _driverId();
    if (driverId != null && _client?.connected == true) {
      _subscription = _client?.subscribe(
        destination: _getTopic(driverId),
        callback: (frame) {
          if (frame.body == null) return;
          try {
            final data = jsonDecode(frame.body!);
            onLocationReceived?.call(data);
          } catch (e) {
            onError?.call('Failed to decode message: $e');
          }
        },
      );
      if (kDebugMode) {
        debugPrint('[WS] Subscribed → ${_getTopic(driverId)}');
      }
    }
  }

  void _handleStompError(StompFrame frame) {
    // Many brokers put auth errors in body or headers
    final body = frame.body ?? '';
    final msg = '[STOMP-ERR] code=${frame.headers['message'] ?? ''} body=$body';
    if (_looksUnauthorized(body) ||
        _looksUnauthorized(frame.headers.toString())) {
      _softReauth(reason: 'stomp_error');
      return;
    }
    _handleError(msg);
  }

  bool _looksUnauthorized(String s) {
    final t = s.toLowerCase();
    return t.contains('unauthorized') ||
        t.contains('401') ||
        t.contains('forbidden') ||
        t.contains('403') ||
        t.contains('invalid token') ||
        t.contains('token invalid') ||
        t.contains('revoked') ||
        t.contains('expired') ||
        t.contains('jwt') ||
        t.contains('signature');
  }

  void _handleError(Object error) {
    final msg = error.toString();
    final lower = msg.toLowerCase();
    debugPrint('[WS] Error: $msg');
    if (_looksUnauthorized(msg)) {
      onError?.call(msg);
      _consecutiveUnauthorizedErrors++;
      if (_consecutiveUnauthorizedErrors > _maxUnauthorizedRetries) {
        _activateDegradedMode('unauthorized');
        return;
      }
      // Try a soft reauth to rotate token before reconnecting
      _softReauth(reason: 'ws_error_unauthorized');
      return;
    }
    if (lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('bad gateway') ||
        lower.contains('gateway timeout') ||
        lower.contains('service unavailable') ||
        lower.contains('was not upgraded to websocket') ||
        lower.contains('sockjs')) {
      onError?.call('WebSocket temporarily unavailable');
      _activateDegradedMode('upstream_unavailable');
      return;
    }
    onError?.call(msg);
    _autoReconnect();
  }

  void _onDisconnect() {
    if (_intentionalDeactivate) {
      _intentionalDeactivate = false;
      return;
    }
    debugPrint('[WS] Disconnected');
    connectionStatus.value = false;
    _stabilityTimer?.cancel();
    onDisconnected?.call();
    _autoReconnect();
  }

  void _autoReconnect() {
    if (_manuallyDisconnected) return;
    if (_authInvalid) return;
    if (_reconnectTimer?.isActive == true) return;
    if (_wsDegradedUntil != null && DateTime.now().isBefore(_wsDegradedUntil!)) {
      final delay = _wsDegradedUntil!.difference(DateTime.now());
      final seconds = max(1, delay.inSeconds);
      debugPrint('[WS] WS_DEGRADED_REST_ACTIVE: reconnect paused ${seconds}s');
      _reconnectTimer = Timer(Duration(seconds: seconds), () {
        if (!_manuallyDisconnected) _initializeClient();
      });
      return;
    }

    _reconnectAttempts++;
    if (_reconnectAttempts > _maxReconnectAttempts) {
      onError?.call('Max reconnect attempts reached');
      return;
    }

    final delaySec = pow(2, _reconnectAttempts).toInt(); // 2,4,8,16,32
    debugPrint('[WS] Reconnecting in $delaySec s...');
    _reconnectTimer = Timer(Duration(seconds: delaySec), () {
      if (!_manuallyDisconnected) _initializeClient();
    });
  }

  /// Re-authenticate quickly by fetching a fresh token and reconnecting,
  /// without escalating the reconnect backoff.
  Future<void> _softReauth({String reason = 'token_refresh'}) async {
    if (_manuallyDisconnected) return;
    if (_connecting) return;

    debugPrint('[WS] Soft reauth requested ($reason)…');
    try {
      final newToken = await (_tokenProvider?.call() ?? _resolveTrackingAwareToken());
      final normalizedToken = _normalizeToken(newToken);
      if (normalizedToken == null || normalizedToken.isEmpty) {
        _authInvalid = true;
        onError?.call('No valid token on refresh; stopping WS');
        SessionManager.instance
            .markAuthInvalid(reason: 'stomp_soft_reauth_missing_token');
        try {
          _intentionalDeactivate = true;
          _client?.deactivate();
        } catch (_) {}
        return;
      }
      // If token actually changed, reconnect with new header
      if (normalizedToken != _currentToken) {
        _currentToken = normalizedToken;
        final wasConnected = isConnected;
        // Deactivate and activate with new headers
        try {
          _intentionalDeactivate = true;
          _client?.deactivate();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 200));
        await _initializeClient(); // this will pick up _currentToken in headers
        if (wasConnected) {
          // resub happens in _onConnect
        }
      } else {
        // Token same — just try a quick reconnect
        _intentionalDeactivate = true;
        _client?.deactivate();
        await Future.delayed(const Duration(milliseconds: 200));
        await _initializeClient();
      }
    } catch (e, st) {
      debugPrint('[WS] Soft reauth failed: $e');
      await Sentry.captureException(e, stackTrace: st);
      _autoReconnect();
    }
  }

  /// Public API to push a new token (e.g., after refresh) and re-auth on the fly.
  Future<void> updateAuthToken(String newToken) async {
    if (newToken.isEmpty) return;
    // If caller updates tokenProvider later, use the new fixed token instead
    _tokenProvider ??= () async => newToken;
    if (newToken != _currentToken) {
      _currentToken = newToken;
      await _softReauth(reason: 'external_update');
    }
  }

  // ---------------------- Unified Location Sender ----------------------

  /// Sends a location update over WS; if not connected or send fails,
  Future<void> sendLocationUpdate(
    LocationUpdate update, {
    required Future<String?> Function() tokenProvider,
  }) async {
    _tokenProvider ??= tokenProvider;

    // Soft kill-switch: allow disabling Flutter sending entirely (optional)
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('disableFlutterLocationSend') == true) {
        if (kDebugMode) debugPrint('[WS] Flutter sending disabled by prefs');
        return;
      }
    } catch (_) {}

    // Do not send from Flutter if native FGS is running
    try {
      final running = await NativeServiceBridge.isServiceRunning();
      if (running == true) {
        if (kDebugMode) {
          debugPrint('[WS] Native FGS active → skip Dart send');
        }
        return;
      }
    } catch (e) {
      // If the bridge call fails, we just continue as before.
      if (kDebugMode) debugPrint('[WS] isServiceRunning check failed: $e');
    }

    // Throttle
    final now = DateTime.now();
    final throttle = _lastSentTime == null ||
        now.difference(_lastSentTime!) >= const Duration(seconds: 15);
    if (!throttle) return;

    // WS first
    if (isConnected) {
      try {
        final payload = await _buildPayload(update);
        _client?.send(destination: destination, body: jsonEncode(payload));
        _lastSentTime = now;
        if (kDebugMode) debugPrint('[WS] Sent: $payload');
        return;
      } catch (e, st) {
        await Sentry.captureException(e, stackTrace: st);
        onError?.call('Failed to send via WebSocket (fallback to REST)');
      }
    }

    // REST fallback
    await _sendViaRest(update, tokenProvider);
  }

  Future<Map<String, dynamic>> _buildPayload(LocationUpdate u) async {
    // driverId as int (server expects a number)
    final idStr = await _driverId();
    final int? driverId = int.tryParse(idStr ?? '');

    double? finite(double? v) => (v != null && v.isFinite) ? v : null;

    final lat = u.position.latitude;
    final lng = u.position.longitude;

    // --- Speed: always send (server upsert uses COALESCE(VALUES(speed), speed)) ---
    final rawSpeed = finite(u.position.speed); // m/s
    // Clamp to reasonable m/s range [0..200] to avoid sensor spikes; default 0.0
    final double speedMps = (rawSpeed ?? 0.0).clamp(0.0, 200.0);

    // --- Heading: normalize into [0, 360) only if present ---
    final rawHeading = finite(u.position.heading);
    final double? headingDeg =
        (rawHeading != null) ? (((rawHeading % 360) + 360) % 360) : null;

    // --- Accuracy and source hint ---
    final accM = finite(u.position.accuracy); // meters
    final String? locationSource =
        (accM != null && accM <= 50) ? 'gps' : (accM != null ? 'fused' : null);

    final payload = <String, dynamic>{
      if (driverId != null) 'driverId': driverId,

      // Required coordinates
      'latitude': lat,
      'longitude': lng,

      // Telemetry
      'speed': speedMps, // always included (0.0 fallback)
      if (headingDeg != null) 'heading': headingDeg,
      if (accM != null) 'accuracyMeters': accM,
      if (u.batteryLevel != null && u.batteryLevel! >= 0)
        'batteryLevel': u.batteryLevel,

      // Client + transport metadata
      'source': 'FLUTTER_ANDROID', // keep consistent with native sender
      if (locationSource != null) 'locationSource': locationSource,

      // Timestamp (epoch ms expected by server under clientTime)
      'clientTime': u.timestamp.millisecondsSinceEpoch,
    };

    payload['pointId'] =
        '${driverId ?? 0}-${u.timestamp.millisecondsSinceEpoch}-${DateTime.now().microsecondsSinceEpoch}';
    final sessionId = await ApiConstants.getTrackingSessionId();
    if (sessionId != null && sessionId.isNotEmpty) {
      payload['sessionId'] = sessionId;
    }

    // Note: We intentionally do not add fields that aren't guaranteed to exist on
    // LocationUpdate (e.g., netType, version, dispatchId) to avoid compile errors.
    // If you later add those to LocationUpdate, you can include them here with:
    //   if (u.netType != null) payload['netType'] = u.netType;
    //   if (u.appVersionCode != null) payload['version'] = u.appVersionCode;
    //   if (u.dispatchId != null) payload['dispatchId'] = u.dispatchId;

    return payload;
  }

  Future<void> _sendViaRest(
    LocationUpdate update,
    Future<String?> Function() tokenProvider,
  ) async {
    int backoff = 1;
    bool retriedAfter401 = false;
    int attempts = 0;
    const int maxAttempts = 6;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final token = await tokenProvider();
        if (token == null || token.isEmpty) {
          // Missing auth should force logout and stop this send loop immediately.
          SessionManager.instance
              .markAuthInvalid(reason: 'rest_send_missing_token');
          return;
        }

        // NOTE: ApiConstants.updateLocation should resolve to: http(s)://host/api/driver/location
        //       (sample cURL posts to /api/driver/location)
        final uri = ApiConstants.updateLocation; // centralized URI
        final payload = await _buildPayload(update);

        if (kDebugMode) {
          debugPrint('[REST] POST $uri');
          debugPrint('[REST] Payload: ${jsonEncode(payload)}');
        }

        final resp = await http
            .post(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 15));

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          _lastSentTime = DateTime.now();
          if (kDebugMode) {
            debugPrint('[REST] Location sent (${resp.statusCode})');
          }
          return;
        } else {
          if (kDebugMode) {
            debugPrint('[REST] Non-2xx ${resp.statusCode} body=${resp.body}');
          }
        }

        if (resp.statusCode == 401 && !retriedAfter401) {
          if (kDebugMode) {
            debugPrint('[REST] 401 → refreshing token & retry once');
          }
          retriedAfter401 = true;
          // Attempt to re-auth WS too (best effort)
          _softReauth(reason: 'rest_401');
          continue; // loop will re-fetch token at top
        }

        if ((resp.statusCode == 401 || resp.statusCode == 403) &&
            retriedAfter401) {
          final bodyLower = resp.body.toLowerCase();
          final confirmedInvalid = bodyLower.contains('revoked') ||
              bodyLower.contains('invalid refresh') ||
              bodyLower.contains('invalid token') ||
              bodyLower.contains('token invalid') ||
              bodyLower.contains('stale_tracking_token') ||
              bodyLower.contains('not a refresh token');
          if (confirmedInvalid) {
            SessionManager.instance
                .markAuthInvalid(reason: 'rest_auth_failed_after_retry');
          } else {
            debugPrint(
              '[REST] Auth retry still failing, but session is not confirmed revoked; keeping driver signed in.',
            );
          }
          return;
        }

        throw 'HTTP ${resp.statusCode}: ${resp.body}';
      } catch (e, st) {
        // Backoff with small jitter
        final jitter = (Random().nextDouble() * 0.4) + 0.8; // 0.8x..1.2x
        final delay = Duration(seconds: (backoff * jitter).round());
        debugPrint('[REST] Error: $e → retry in ${delay.inSeconds}s');
        await Sentry.captureException(e, stackTrace: st);
        await Future.delayed(delay);
        backoff = min(backoff * 2, 32);
      }
    }

    debugPrint('[REST] Max retry attempts reached; aborting location send');
  }

  // ---------------------- Lifecycle ----------------------

  void disconnect() {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stabilityTimer?.cancel();
    _stabilityTimer = null;
    _wsDegradedUntil = null;
    _subscription?.call();
    _subscription = null;
    _intentionalDeactivate = true;
    _client?.deactivate();
    _client = null;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _consecutiveUnauthorizedErrors = 0;
    connectionStatus.value = false;
  }

  void dispose() {
    disconnect();
    connectionStatus.dispose();
  }

  void _startHealthCheckPing() {
    // Rely on STOMP heartbeatOutgoing instead of app-level ping frame.
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Subscribe to additional STOMP topics beyond the default driver location.
  /// Returns an unsubscribe function or null if not connected.
  StompUnsubscribe? subscribe(
    String destination,
    void Function(StompFrame) callback,
  ) {
    if (_client?.connected != true) {
      if (kDebugMode) {
        debugPrint('[WS] Cannot subscribe to $destination: not connected');
      }
      return null;
    }

    try {
      final unsub = _client?.subscribe(
        destination: destination,
        callback: callback,
      );
      if (kDebugMode) {
        debugPrint('[WS] Subscribed to additional topic: $destination');
      }
      return unsub;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WS] Subscribe error for $destination: $e');
      }
      return null;
    }
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

  void _activateDegradedMode(String reason) {
    _wsDegradedUntil = DateTime.now().add(_wsDegradedCooldown);
    final until = _wsDegradedUntil!.toIso8601String();
    onError?.call('WS_DEGRADED_REST_ACTIVE ($reason)');
    debugPrint(
        '[WS] WS_DEGRADED_REST_ACTIVE reason=$reason until=$until; REST/native tracking continues.');
    _consecutiveUnauthorizedErrors = 0;
    _reconnectAttempts = 0;
    _autoReconnect();
  }
}
