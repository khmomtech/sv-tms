// 📁 lib/services/location_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_config.dart';
import '../core/network/api_constants.dart';
import 'geofence_manager.dart';
import 'location_validator.dart';
import 'session_manager.dart';
import 'tracking_session_manager.dart';

/// Canonical location event payload
class LocationUpdate {
  final Position position;
  final int? batteryLevel;
  final DateTime timestamp;
  final bool isBatterySaver;
  final bool isReducedAccuracy;
  final bool isKeepAlive;

  LocationUpdate({
    required this.position,
    this.batteryLevel,
    DateTime? timestamp,
    this.isBatterySaver = false,
    this.isReducedAccuracy = false,
    this.isKeepAlive = false,
  }) : timestamp = (timestamp ?? DateTime.now().toUtc());

  double get lat => position.latitude;
  double get lng => position.longitude;

  Map<String, dynamic> toJson({
    required int driverId,
    required String driverName,
    required String vehiclePlate,
  }) {
    double? speedMps;
    double? speedKmh;
    if (position.speed.isFinite && position.speed >= 0) {
      speedMps = position.speed; // m/s (server canonical)
      speedKmh = (position.speed * 3.6).clamp(0, 180);
      if (speedKmh < 2.0) speedKmh = 0.0;
    }

    final map = <String, dynamic>{
      'driverId': driverId,
      'driverName': driverName,
      'vehiclePlate': vehiclePlate,
      'latitude': lat, // keep full precision
      'longitude': lng, // keep full precision
      'speed': speedMps, // m/s
      'clientSpeedKmh': speedKmh, // convenience for dashboards
      'accuracyMeters': position.accuracy.isFinite ? position.accuracy : null,
      'heading': position.heading.isFinite ? position.heading : null,
      'isMocked': position.isMocked,
      'batterySaver': isBatterySaver,
      'source': 'FLUTTER',
      'clientTime': timestamp.toIso8601String(),
      'timestampEpochMs': timestamp.millisecondsSinceEpoch,
      'keepAlive': isKeepAlive,
    };
    if (batteryLevel != null && batteryLevel! >= 0 && batteryLevel! <= 100) {
      map['batteryLevel'] = batteryLevel;
    }
    return map;
  }
}

/// Production-grade, in-app location sender (WebSocket + HTTP fallback)
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ValueNotifier<bool> trackingStatus = ValueNotifier(false);
  final ValueNotifier<bool> online = ValueNotifier(false);
  bool _isTracking = false;

  Position? _lastPos;
  DateTime? _lastQueuedAt;
  DateTime? _lastRawSampleAt;

  // Broadcast controller; recreated on each start() and closed on stop()
  StreamController<LocationUpdate>? _updatesCtrl;
  Stream<LocationUpdate> get updates =>
      (_updatesCtrl ??= StreamController<LocationUpdate>.broadcast()).stream;

  final Battery _battery = Battery();
  int? _lastBattery;
  bool _batterySaverHint = false;
  StreamSubscription<BatteryState>? _batteryStateSub;
  BatteryState _currentBatteryState = BatteryState.full;

  StreamSubscription<Position>? _posSub;
  StreamSubscription<ServiceStatus>? _svcStatusSub;

  // Enhanced features
  final LocationValidator _validator = LocationValidator();
  final GeofenceManager geofenceManager = GeofenceManager();
  int _spoofAlertCount = 0;
  static const int _maxSpoofAlerts = 3;

  Timer? _watchdog;
  Timer? _keepAlive;

  // Config
  LocationAccuracy _accuracy = LocationAccuracy.bestForNavigation;
  int _distanceFilter = 10; // meters (hard minimum for emits)
  final Duration _minEmitInterval = const Duration(
      seconds: 8); // hard minimum (see _onPosition: moving cadence is 6s)
  final Duration _maxIdleReport = const Duration(seconds: 60);
  int _warmupDrops = 2; // drop first 2 fixes to allow GPS to converge
  final Duration _maxSampleAge =
      const Duration(seconds: 5); // drop samples older than 5s

  // WS (lightweight best-effort pipe; HTTP used as fallback)
  WebSocket? _ws;
  bool _wsConnected = false;
  Timer? _wsPing;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _connecting = false;
  bool _authInvalid = false;

  // Injected identity providers
  Future<int> Function()? _getDriverId;
  Future<String> Function()? _getDriverName;
  Future<String> Function()? _getVehiclePlate;

  static int _seq = 0;
  static const String _queueStorageKey = 'pending_location_queue_v1';

  // Injectable HTTP client for easier testing; if null we use package-level helpers.
  http.Client? _httpClient;

  /// Inject a custom `http.Client` for tests or alternative transports.
  void setHttpClient(http.Client client) => _httpClient = client;

  void configure({
    Future<int> Function()? getDriverId,
    Future<String> Function()? getDriverName,
    Future<String> Function()? getVehiclePlate,
  }) {
    _getDriverId = getDriverId;
    _getDriverName = getDriverName;
    _getVehiclePlate = getVehiclePlate;
  }

  /// Public API: send a single `LocationUpdate` immediately (WS preferred,
  /// HTTP fallback). Useful for programmatic sends and tests.
  Future<bool> sendUpdate(LocationUpdate u) async => await _send(u);

  /// Public API: enqueue for durable delivery (persisted on disk).
  Future<void> queueUpdate(LocationUpdate u) async => await _enqueueAsync(u);

  // Public API
  Future<void> start({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilterMeters = 10,
  }) async {
    if (_isTracking) return;

    _accuracy = accuracy;
    _distanceFilter = math.max(0, distanceFilterMeters);

    // Recreate a fresh broadcast controller each start()
    _updatesCtrl?.close();
    _updatesCtrl = StreamController<LocationUpdate>.broadcast();

    // Monitor battery state for adaptive tracking
    _batteryStateSub = _battery.onBatteryStateChanged.listen((state) {
      _currentBatteryState = state;
      _adjustTrackingForBattery();
    });

    if (!await _checkPerms()) {
      debugPrint('[LocationService] permissions/services not ready');
      return;
    }

    await _restoreQueueFromDisk();
    unawaited(_flush());

    _svcStatusSub ??=
        Geolocator.getServiceStatusStream().listen(_onServiceStatus);

    await _startStream();
    _startWatchdog();
    _startKeepAlive();
    // Disable in-app raw WebSocket sender: STOMP client handles WS.
    // HTTP fallback remains active below when WS is unavailable.
    debugPrint('[LocationService] WS disabled (using REST fallback/STOMP)');

    _isTracking = true;
    trackingStatus.value = true;
    debugPrint(
        '[LocationService] Started (accuracy=$_accuracy, distanceFilter=$_distanceFilter m)');
  }

  Future<void> stop() async {
    await _stopStream();
    _stopWatchdog();
    _stopKeepAlive();
    await _closeWs();
    await _persistQueueNow();

    // Close stream to avoid leaks; consumers should re-subscribe after next start()
    await _updatesCtrl?.close();
    _updatesCtrl = null;

    // Cancel battery monitoring
    await _batteryStateSub?.cancel();
    _batteryStateSub = null;

    _isTracking = false;
    trackingStatus.value = false;
    debugPrint('[LocationService] 🛑 Stopped');
  }

  Future<void> dispose() async {
    await stop();
    await _svcStatusSub?.cancel();
    trackingStatus.dispose();
    online.dispose();
  }

  // Internals
  Future<bool> _checkPerms() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> _startStream() async {
    await _posSub?.cancel();

    final LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: _distanceFilter,
        intervalDuration: const Duration(seconds: 5),
      );
    } else if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: _distanceFilter,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      );
    }

    _posSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition, onError: (_) => _scheduleRestart());

    try {
      _lastPos = await Geolocator.getLastKnownPosition();
    } catch (_) {}
  }

  Future<void> _stopStream() async {
    await _posSub?.cancel();
    _posSub = null;
  }

  void _onServiceStatus(ServiceStatus s) {
    if (s == ServiceStatus.enabled && !_isTracking) {
      unawaited(
          start(accuracy: _accuracy, distanceFilterMeters: _distanceFilter));
    } else if (s == ServiceStatus.disabled && _isTracking) {
      unawaited(stop());
    }
  }

  Future<void> _onPosition(Position pos) async {
    _markRawSampleSeen();

    // Warm-up: ignore the first couple of fixes so GPS can converge
    if (_warmupDrops > 0) {
      _warmupDrops--;
      return;
    }

    // Refresh battery level best-effort
    try {
      final lvl = await _battery.batteryLevel;
      if (lvl >= 0 && lvl <= 100) _lastBattery = lvl;
    } catch (_) {/* keep last */}

    // --- Enhanced spoofing detection ---
    final spoofReason = _validator.validateLocation(pos);
    if (spoofReason != null) {
      _spoofAlertCount++;

      if (_spoofAlertCount >= _maxSpoofAlerts) {
        // Alert backend and user
        _sendSpoofAlert(pos, spoofReason);

        // Optionally: Stop tracking or mark session as suspicious
        if (_spoofAlertCount >= 10) {
          debugPrint(
            '[LocationService] Too many spoofing attempts, stopping tracking',
          );
          stop();
          return;
        }
      }

      debugPrint(
          '[LocationService] Suspicious location detected: $spoofReason');
      return; // Drop this location
    }

    // Reset counter on valid location
    _spoofAlertCount = 0;

    // --- Quality gates (mirror native behavior) ---
    // 1) Ignore mocked locations entirely (already checked by validator)
    if (pos.isMocked) return;
    // 2) Require finite and reasonably precise accuracy (≤30 m)
    if (!pos.accuracy.isFinite || pos.accuracy > 30) return;
    // 3) Stale check using provider timestamp (prefer Position.timestamp)
    final DateTime sampleTimeUtc = (pos.timestamp).toUtc();
    final Duration sampleAge = DateTime.now().toUtc().difference(sampleTimeUtc);
    if (sampleAge > _maxSampleAge) return; // drop stale samples (>5s old)

    // Adaptive cadence: faster when moving, slower when idle
    final bool movingFast = pos.speed.isFinite && pos.speed >= 2.78; // ~10 km/h
    final Duration adaptiveInterval = movingFast
        ? const Duration(seconds: 6) // native CLIENT_MIN_TIME_MS ≈ 6s
        : const Duration(seconds: 20);
    final Duration minInterval =
        _maxDuration(_minEmitInterval, adaptiveInterval);

    // Distance filter: honor stream setting but adapt when idle
    final int adaptiveDistanceM =
        movingFast ? 12 : 30; // mirror native ~12m when moving
    final int thresholdM = math.max(_distanceFilter, adaptiveDistanceM);

    if (_lastQueuedAt != null &&
        sampleTimeUtc.difference(_lastQueuedAt!) < minInterval) {
      return;
    }
    if (_lastPos != null && _haversine(_lastPos!, pos) < thresholdM) return;

    // Check geofences (events are broadcast via geofenceManager.events ValueNotifier)
    geofenceManager.checkPosition(pos);

    // Passed gates → emit + enqueue
    _lastQueuedAt = sampleTimeUtc;
    _lastPos = pos;

    final update = LocationUpdate(
      position: pos,
      batteryLevel: _lastBattery,
      timestamp: sampleTimeUtc,
      isBatterySaver: _batterySaverHint,
      // coarse ≥100 m indicates reduced-precision mode (iOS Approximate, etc.)
      isReducedAccuracy: pos.accuracy.isFinite && pos.accuracy >= 100,
      isKeepAlive: false,
    );

    if (!(_updatesCtrl?.isClosed ?? true)) {
      _updatesCtrl!.add(update);
    }
    _enqueue(update);
  }

  // Distance calc
  double _haversine(Position a, Position b) {
    const R = 6371000.0;
    final dLat = _deg(b.latitude - a.latitude);
    final dLon = _deg(b.longitude - a.longitude);
    final d = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg(a.latitude)) *
            math.cos(_deg(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(d), math.sqrt(1 - d));
  }

  double _deg(double d) => d * math.pi / 180;
  Duration _maxDuration(Duration a, Duration b) => a >= b ? a : b;

  // Watchdog
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 45), (_) {
      final now = DateTime.now().toUtc();
      final rawSince =
          _lastRawSampleAt != null ? now.difference(_lastRawSampleAt!) : null;
      if (_lastQueuedAt == null) {
        if (rawSince != null && rawSince <= const Duration(seconds: 45)) {
          debugPrint(
            '[LocationService] GPS is producing samples, but none passed validation. Restarting stream.',
          );
        }
        _scheduleRestart();
      } else {
        final since = now.difference(_lastQueuedAt!);
        if (since > const Duration(seconds: 90)) _scheduleRestart();
      }
    });
  }

  void _markRawSampleSeen() => _lastRawSampleAt = DateTime.now().toUtc();

  void _stopWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  // KeepAlive
  void _startKeepAlive() {
    _keepAlive?.cancel();
    _keepAlive = Timer.periodic(_maxIdleReport, (_) {
      if (_lastPos == null) return;
      final now = DateTime.now().toUtc();
      if (_lastQueuedAt == null ||
          now.difference(_lastQueuedAt!) >= _maxIdleReport) {
        final ka = LocationUpdate(
          position: _lastPos!,
          batteryLevel: _lastBattery,
          timestamp: now,
          isBatterySaver: _batterySaverHint,
          isKeepAlive: true,
        );
        if (!(_updatesCtrl?.isClosed ?? true)) {
          _updatesCtrl!.add(ka);
        }
        _enqueue(ka);
      }
    });
  }

  void _stopKeepAlive() {
    _keepAlive?.cancel();
    _keepAlive = null;
  }

  void _scheduleRestart() {
    if (!_isTracking) return;
    Future.delayed(const Duration(seconds: 5), () async {
      if (_isTracking) {
        await _stopStream();
        await _startStream();
      }
    });
  }

  String _maskToken(String s) {
    if (s.isEmpty) return s;
    final i = s.indexOf('token=');
    if (i == -1) return s;
    final start = i + 6;
    final end = s.indexOf('&', start);
    return end == -1
        ? s.replaceRange(start, s.length, '***')
        : s.replaceRange(start, end, '***');
  }

  // Prefer centralized builder from ApiConstants to avoid drift.

  Future<bool> _hasConnectivity() async {
    try {
      final base = ApiConstants.baseUrl;
      if (base.isEmpty) return false;
      final uri = Uri.parse(base);
      final host = uri.host.isNotEmpty ? uri.host : base;
      final res = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 2));
      return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Sender
  Future<void> _initWs() async {
    if (_connecting) return;
    if (_authInvalid) return;
    _connecting = true;

    final token = await _requireTrackingToken();
    final base = ApiConstants.baseUrl;

    if (base.isEmpty) {
      _wsConnected = false;
      _connecting = false;
      _scheduleReconnect();
      return;
    }

    if (token.isEmpty) {
      // If we cannot obtain a fresh token right now, stay degraded and retry later.
      _wsConnected = false;
      online.value = false;
      _connecting = false;
      _authInvalid = false;
      debugPrint('[WS] Missing token for location socket; scheduling reconnect instead of forcing logout');
      _scheduleReconnect();
      return;
    }

    try {
      if (!await _hasConnectivity()) {
        _wsConnected = false;
        _connecting = false;
        _scheduleReconnect();
        return;
      }

      final wsUrl =
          await ApiConstants.getDriverLocationWebSocketUrlWithToken(token);
      debugPrint('[WS] Connecting → ${_maskToken(wsUrl)}');

      _ws = await WebSocket.connect(
        wsUrl,
        headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
      );

      _wsConnected = true;
      online.value = true;
      _reconnectAttempt = 0;

      _wsPing?.cancel();
      _wsPing = Timer.periodic(const Duration(seconds: 20), (_) {
        try {
          _ws?.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      });

      _ws!.listen(
        (_) {},
        onDone: () {
          _wsConnected = false;
          online.value = false;
          _connecting = false;
          if (!_authInvalid) _scheduleReconnect();
        },
        onError: (_) {
          _wsConnected = false;
          online.value = false;
          _connecting = false;
          if (!_authInvalid) _scheduleReconnect();
        },
      );

      unawaited(_flush());
    } catch (_) {
      _wsConnected = false;
      online.value = false;
      _connecting = false;
      if (!_authInvalid) _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (!_isTracking) return;
    final pow = _reconnectAttempt.clamp(0, 6);
    final baseMs = 500 * (1 << pow); // 0.5s..32s
    final jitterMs = 100 + (DateTime.now().millisecond % 300);
    final delay = Duration(milliseconds: baseMs + jitterMs);
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, _initWs);
  }

  void _enqueue(LocationUpdate u) {
    unawaited(_enqueueAsync(u));
  }

  Future<void> _enqueueAsync(LocationUpdate u) async {
    final payload = await _buildPayloadForSend(u);
    if (_queue.length >= _queueCap) {
      final keepAliveIndex =
          _queue.indexWhere((entry) => entry['keepAlive'] == true);
      if (keepAliveIndex >= 0) {
        _queue.removeAt(keepAliveIndex);
      } else {
        _queue.removeAt(0);
      }
      debugPrint(
        '[LocationService] Queue full ($_queueCap). Dropped oldest buffered point before enqueue.',
      );
    }
    _queue.add(payload);
    _scheduleQueuePersist();
    unawaited(_flush());
  }

  Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      while (_queue.isNotEmpty) {
        // If we have many pending items, send a batch for efficiency
        if (_queue.length >= 10) {
          final take = _queue.length.clamp(10, 100);
          final slice = List<Map<String, dynamic>>.from(_queue.take(take));
          final ok = await _sendBatchPayload(slice);
          if (ok) {
            _queue.removeRange(0, take);
            _scheduleQueuePersist();
            _retryStep = 0;
            continue; // keep flushing remaining
          } else {
            _retryStep = (_retryStep + 1).clamp(0, 5);
            final delay = Duration(seconds: 2 << _retryStep);
            Future.delayed(delay, _flush);
            break;
          }
        }

        // Otherwise, send one by one
        final ok = await _sendPayload(_queue.first);
        if (ok) {
          _queue.removeAt(0);
          _scheduleQueuePersist();
          _retryStep = 0;
        } else {
          _retryStep = (_retryStep + 1).clamp(0, 5);
          final delay = Duration(seconds: 2 << _retryStep);
          Future.delayed(delay, _flush);
          break;
        }
      }
    } finally {
      _flushing = false;
    }
  }

  Future<bool> _send(LocationUpdate u) async {
    final payload = await _buildPayloadForSend(u);
    return _sendPayload(payload);
  }

  Future<bool> _sendPayload(Map<String, dynamic> payloadMap) async {
    final token = await _requireTrackingToken();
    final baseUrl = ApiConstants.baseUrl;
    if (token.isEmpty || baseUrl.isEmpty) return false;
    final payload = jsonEncode(payloadMap);

    if (_wsConnected && _ws != null) {
      try {
        _ws!.add(payload);
        return true;
      } catch (_) {/* fall through to HTTP */}
    }

    if (!await _hasConnectivity()) return false;
    try {
      if (_httpClient != null) {
        final res = await _httpClient!.post(
          Uri.parse('$baseUrl/driver/location'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.acceptHeader: 'application/json',
          },
          body: payload,
        );
        if (res.statusCode == 403) {
          debugPrint('[LocationService] 403 on location update — clearing stale tracking session');
          await ApiConstants.clearTrackingSession();
        }
        return res.statusCode == 200 || res.statusCode == 201;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/driver/location'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
        body: payload,
      );
      if (res.statusCode == 403) {
        debugPrint('[LocationService] 403 on location update — clearing stale tracking session');
        await ApiConstants.clearTrackingSession();
      }
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _sendBatchPayload(List<Map<String, dynamic>> batch) async {
    final token = await _requireTrackingToken();
    final baseUrl = ApiConstants.baseUrl;
    if (token.isEmpty || baseUrl.isEmpty) return false;

    if (_wsConnected && _ws != null) {
      try {
        for (final m in batch) {
          _ws!.add(jsonEncode(m));
        }
        return true;
      } catch (_) {/* fall through to HTTP */}
    }

    if (!await _hasConnectivity()) return false;
    try {
      if (_httpClient != null) {
        final res = await _httpClient!.post(
          Uri.parse('$baseUrl/driver/location/batch'),
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.acceptHeader: 'application/json',
          },
          body: jsonEncode(batch),
        );
        if (res.statusCode == 404 || res.statusCode == 405) {
          return _sendBatchIndividually(batch);
        }
        if (res.statusCode == 403) {
          debugPrint('[LocationService] 403 on batch update — clearing stale tracking session');
          await ApiConstants.clearTrackingSession();
        }
        return res.statusCode >= 200 && res.statusCode < 300;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/driver/location/batch'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
        body: jsonEncode(batch),
      );
      if (res.statusCode == 404 || res.statusCode == 405) {
        return _sendBatchIndividually(batch);
      }
      if (res.statusCode == 403) {
        debugPrint('[LocationService] 403 on batch update — clearing stale tracking session');
        await ApiConstants.clearTrackingSession();
      }
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return _sendBatchIndividually(batch);
    }
  }

  Future<bool> _sendBatchIndividually(List<Map<String, dynamic>> batch) async {
    for (final payload in batch) {
      final ok = await _sendPayload(payload);
      if (!ok) return false;
    }
    return true;
  }

  Future<void> _closeWs() async {
    _wsPing?.cancel();
    _wsPing = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    _connecting = false;
    try {
      await _ws?.close();
    } catch (_) {}
    _ws = null;
    _wsConnected = false;
    online.value = false;
  }

  final List<Map<String, dynamic>> _queue = [];
  Timer? _persistQueueDebounce;
  final int _queueCap = AppConfig.maxBufferedLocationUpdates;
  bool _flushing = false;
  int _retryStep = 0;

  Future<Map<String, dynamic>> _buildPayloadForSend(LocationUpdate u) async {
    final driverId = await _resolveDriverId();
    final driverName = await _resolveDriverName();
    final vehiclePlate = await _resolveVehiclePlate();

    final payloadMap = u.toJson(
      driverId: driverId,
      driverName: driverName,
      vehiclePlate: vehiclePlate,
    );

    payloadMap['seq'] = ++_seq;
    payloadMap['pointId'] = _generatePointId(driverId, _seq);
    final sessionId = await ApiConstants.getTrackingSessionId();
    if (sessionId != null && sessionId.isNotEmpty) {
      payloadMap['sessionId'] = sessionId;
    }
    return payloadMap;
  }

  Future<String> _requireTrackingToken() async {
    var token = await ApiConstants.ensureFreshTrackingToken();
    if (token != null && token.isNotEmpty) {
      return token;
    }

    final sessionReady =
        await TrackingSessionManager.instance.ensureTrackingSession();
    if (!sessionReady) {
      debugPrint(
        '[LocationService] Missing tracking session; refusing to send location payload.',
      );
      return '';
    }

    token = await ApiConstants.ensureFreshTrackingToken();
    if (token != null && token.isNotEmpty) {
      return token;
    }

    debugPrint(
      '[LocationService] Tracking session start succeeded without usable tracking token.',
    );
    return '';
  }

  String _generatePointId(int driverId, int seq) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = math.Random().nextInt(1 << 20);
    return '$driverId-$ts-$seq-$rnd';
  }

  Future<int> _resolveDriverId() async {
    if (_getDriverId != null) {
      final id = await _getDriverId!.call();
      if (id > 0) return id;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('driverId');
      return int.tryParse(raw ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<String> _resolveDriverName() async {
    if (_getDriverName != null) {
      final name = await _getDriverName!.call();
      if (name.trim().isNotEmpty) return name.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString('driverName') ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  Future<String> _resolveVehiclePlate() async {
    if (_getVehiclePlate != null) {
      final plate = await _getVehiclePlate!.call();
      if (plate.trim().isNotEmpty) return plate.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString('vehiclePlate') ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  void _scheduleQueuePersist() {
    _persistQueueDebounce?.cancel();
    _persistQueueDebounce = Timer(
      const Duration(seconds: 1),
      () => unawaited(_persistQueueNow()),
    );
  }

  Future<void> _persistQueueNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_queue.isEmpty) {
        await prefs.remove(_queueStorageKey);
        return;
      }
      await prefs.setString(_queueStorageKey, jsonEncode(_queue));
    } catch (e) {
      debugPrint('[LocationService] Failed to persist queue: $e');
    }
  }

  Future<void> _restoreQueueFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueStorageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      _queue.clear();
      for (final entry in decoded) {
        if (entry is Map) {
          _queue.add(Map<String, dynamic>.from(entry));
        }
      }
      if (_queue.length > _queueCap) {
        _queue.removeRange(0, _queue.length - _queueCap);
      }
      if (_queue.isNotEmpty) {
        debugPrint(
            '[LocationService] Restored ${_queue.length} pending location update(s)');
      }
    } catch (e) {
      debugPrint('[LocationService] Failed to restore queue: $e');
    }
  }

  // --- Enhanced Battery Optimization ---
  void _adjustTrackingForBattery() async {
    final level = _lastBattery ?? 100;
    final isCharging = _currentBatteryState == BatteryState.charging;

    // Don't throttle if charging
    if (isCharging) {
      _accuracy = LocationAccuracy.bestForNavigation;
      _batterySaverHint = false;
      return;
    }

    // Aggressive power saving when battery low
    if (level <= 15) {
      debugPrint(
        '[LocationService] Battery critical ($level%) - reducing location accuracy',
      );
      _accuracy = LocationAccuracy.low;
      _batterySaverHint = true;
      _distanceFilter = 50; // Only update every 50m

      // Restart location stream with new settings
      await _restartLocationStream();
    } else if (level <= 30) {
      debugPrint(
        '[LocationService] Battery low ($level%) - using balanced accuracy',
      );
      _accuracy = LocationAccuracy.medium;
      _batterySaverHint = true;
      _distanceFilter = 25;

      await _restartLocationStream();
    } else {
      // Normal operation
      _accuracy = LocationAccuracy.bestForNavigation;
      _batterySaverHint = false;
      _distanceFilter = 10;
    }
  }

  Future<void> _restartLocationStream() async {
    if (!_isTracking) return;

    await _posSub?.cancel();

    final settings = LocationSettings(
      accuracy: _accuracy,
      distanceFilter: _distanceFilter,
    );

    _posSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition, onError: _onError);
  }

  /// Handle location stream errors
  void _onError(Object error) {
    debugPrint('Location stream error: $error');
    _scheduleRestart();
  }

  // --- Spoofing Alert to Backend ---
  Future<void> _sendSpoofAlert(Position pos, String reason) async {
    final driverId = await _getDriverId?.call();
    if (driverId == null) return;

    try {
      final token = await ApiConstants.getAccessToken();
      if (token == null || token.isEmpty) return;

      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/driver/location/spoofing-alert'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
        body: jsonEncode({
          'driverId': driverId,
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'timestamp': pos.timestamp.toIso8601String(),
          'reason': reason,
          'isMocked': pos.isMocked,
          'accuracy': pos.accuracy,
          'speed': pos.speed,
          'heading': pos.heading,
        }),
      );
      debugPrint('[LocationService] Spoofing alert sent to backend');
    } catch (e) {
      debugPrint('[LocationService] Failed to send spoof alert: $e');
    }
  }
}

void unawaited(Future<dynamic> future) {
  future.catchError((e, st) {
    debugPrint('Unawaited error: $e');
    return null;
  });
}
