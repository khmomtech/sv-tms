// lib/core/network/api_constants.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:tms_driver_app/core/config/app_config.dart' as EnvAppConfig;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/services/session_manager.dart';

/// 🌐 Centralized API configuration and dynamic base URL manager.
class ApiConstants {
  // Compile-time override via `--dart-define=API_BASE_URL=http://host:8080/api`
  // Useful for CI or quick local overrides without changing prefs.
  static const String _compileTimeApiBase =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  // ===========================================================================
  // 🔧 Base URLs (simplified for production)
  // ===========================================================================
  // Production API ingress (used when no override or compile-time override)
  static const String _defaultApiUrl = 'https://svtms.svtrucking.biz/api';
  static const String _defaultImageUrl = 'https://svtms.svtrucking.biz';

  // ===========================================================================
  // 🏃 Runtime values (restored on init)
  // ===========================================================================
  static String _baseUrl = _defaultApiUrl;
  static String _imageUrl = _defaultImageUrl;
  static bool _initialized = false;
  // When a compile-time override is applied we keep it pinned so subsequent
  // environment switches or saved prefs don't accidentally overwrite it.
  static bool _compileTimeOverrideActive = false;

  static String get baseUrl => _baseUrl; // e.g. https://host/api
  static String get baseApiUrl => _baseUrl; // alias
  static String get imageUrl => _imageUrl; // e.g. https://host

  // ===========================================================================
  // 🗝️ Pref Keys
  // ===========================================================================
  static const _kAccess = 'accessToken';
  static const _kRefresh = 'refreshToken';
  static const _kTrackingToken = 'trackingToken';
  static const _kTrackingSessionId = 'trackingSessionId';
  static const _kTrackingExpiresAtMs = 'trackingExpiresAtMs';
  static const _kUserJson = 'userJson';
  static const _kApiUrlOverride = 'apiUrl';
  // Versioned/expiring override support
  static const _kApiUrlOverrideTs = 'apiUrl_ts';
  static const Duration _overrideMaxAge = Duration(days: 7);
  // Small caching to avoid repeated secure-storage reads and log spam
  static String? _cachedAccessToken;
  static DateTime? _cachedAccessTs;
  static const Duration _tokenCacheTtl = Duration(seconds: 5);
  static Future<void> Function(String accessToken)? _tokenUpdateListener;

  // ===========================================================================
  // Init / helpers
  // ===========================================================================
  // When running unit tests we may want to avoid initializing platform
  // plugins such as `flutter_secure_storage`. Tests can set this flag
  // to true before calling `init()` to skip secure-storage setup.
  static bool skipSecureStorageForTests = false;

  static Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    // Initialize secure storage (no-op but keeps intent clear)
    if (!skipSecureStorageForTests) {
      _secure = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        mOptions:
            MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
        wOptions: WindowsOptions(),
        lOptions: LinuxOptions(),
        webOptions: WebOptions(),
      );
    } else {
      _secure = null;
    }

    // Base from default (use debug env config when not in release)
    final defaultApi = kReleaseMode
        ? _defaultApiUrl
        : _normalizeApiUrl(EnvAppConfig.AppConfig.apiBaseUrl);
    _baseUrl = _devAdjustBaseForAndroidEmulatorIfNeeded(defaultApi);
    _imageUrl = _stripApiSuffix(_baseUrl);

    // Respect a compile-time override when provided via `--dart-define`.
    // This is handy for CI or for quickly pointing the app at a remote/local
    // backend without changing saved preferences.
    if (_compileTimeApiBase.isNotEmpty) {
      final normalized = _normalizeApiUrl(_compileTimeApiBase);
      if (!_isBadApiUrl(normalized)) {
        _baseUrl = _devAdjustBaseForAndroidEmulatorIfNeeded(normalized);
        _imageUrl = _stripApiSuffix(_baseUrl);
        _compileTimeOverrideActive = true;
        // Clear any saved overrides when compile-time override is active
        await _clearOverride(prefs);
        debugPrint('[Api]Using compile-time API_BASE_URL override: $_baseUrl');
      }
    }

    // Apply override if present, sane, and not stale
    final savedApiUrlRaw = prefs.getString(_kApiUrlOverride);
    final savedTs = prefs.getInt(_kApiUrlOverrideTs);
    final hasTs = savedTs != null && savedTs > 0;
    final isStale = hasTs
        ? DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(savedTs)) >
            _overrideMaxAge
        : false;

    if (savedApiUrlRaw != null && savedApiUrlRaw.isNotEmpty) {
      final savedApiUrl = _normalizeApiUrl(savedApiUrlRaw);

      if (_isBadApiUrl(savedApiUrl) || isStale) {
        debugPrint(
            '[Api] Override invalid${isStale ? ' (stale)' : ''}: "$savedApiUrlRaw" -> clearing');
        await _clearOverride(prefs);
      } else if (_sameHostPort(savedApiUrl, _baseUrl)) {
        // If override points to the same host/port as env base, drop it to avoid shadowing future env changes
        debugPrint(
            '[Api] ℹ️ Override matches env base host/port -> clearing override');
        await _clearOverride(prefs);
      } else {
        // Quick reachability check for overridden URL
        final isReachable = await _quickHealthCheck(savedApiUrl);
        if (!isReachable) {
          debugPrint(
              '[Api] Override unreachable: "$savedApiUrl" -> trying default');
          // Try default before clearing
          final defaultReachable = await _quickHealthCheck(_defaultApiUrl);
          if (defaultReachable) {
            debugPrint('[Api] Default URL reachable -> clearing override');
            await _clearOverride(prefs);
          } else {
            debugPrint(
                '[Api] Both URLs unreachable -> keeping override (offline?)');
            _baseUrl = _devAdjustBaseForAndroidEmulatorIfNeeded(savedApiUrl);
            _imageUrl = _stripApiSuffix(_baseUrl);
          }
        } else {
          _baseUrl = _devAdjustBaseForAndroidEmulatorIfNeeded(savedApiUrl);
          _imageUrl = _stripApiSuffix(_baseUrl);
          debugPrint(
              '[Api] 🔁 Using overridden baseUrl: $_baseUrl | imageUrl: $_imageUrl');
        }
      }
    } else {
      debugPrint('[Api] Restored baseUrl: $_baseUrl | imageUrl: $_imageUrl');
    }

    _initialized = true;
  }

  static void setTokenUpdateListener(
      Future<void> Function(String accessToken)? listener) {
    _tokenUpdateListener = listener;
  }

  static Future<void> ensureInitialized() async {
    if (!_initialized) await init();
  }

  static bool _isBadApiUrl(String? apiUrl) {
    if (apiUrl == null || apiUrl.isEmpty) return true;
    if (apiUrl.contains(':0')) return true;
    try {
      final u = Uri.parse(apiUrl);
      if (u.host.isEmpty) return true;
      return false;
    } catch (_) {
      return true;
    }
  }

  static String _stripApiSuffix(String url) =>
      url.endsWith('/api') ? url.substring(0, url.length - 4) : url;

  static String _normalizeApiUrl(String url) {
    if (url.isEmpty) return url;
    // Trim whitespace
    url = url.trim();
    // Remove trailing slash to make suffix logic consistent
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    // Ensure it ends with /api
    if (!url.endsWith('/api')) url = '$url/api';
    return url;
  }

  /// In dev, if the base points at localhost and we're on Android emulator,
  /// rewrite host to 10.0.2.2 so the emulator can reach the host machine.
  static String _devAdjustBaseForAndroidEmulatorIfNeeded(String url) {
    try {
      if (!Platform.isAndroid) return url;
      final u = Uri.parse(url);
      final host = u.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        final port = (u.hasPort && u.port != 0) ? ':${u.port}' : '';
        final scheme = u.scheme;
        final path = u.path;
        final rebuilt = '$scheme://10.0.2.2$port$path';
        return rebuilt;
      }
      return url;
    } catch (_) {
      return url;
    }
  }

  static bool _sameHostPort(String a, String b) {
    try {
      final ua = Uri.parse(a);
      final ub = Uri.parse(b);
      final pa = (ua.hasPort && ua.port != 0)
          ? ua.port
          : (ua.scheme == 'https' ? 443 : 80);
      final pb = (ub.hasPort && ub.port != 0)
          ? ub.port
          : (ub.scheme == 'https' ? 443 : 80);
      return ua.host == ub.host && pa == pb;
    } catch (_) {
      return false;
    }
  }

  /// Quick reachability check with 3-second timeout.
  /// We accept any HTTP response status from known endpoints because we only
  /// need to know that the host is reachable (not necessarily authorized).
  static Future<bool> _quickHealthCheck(String apiUrl) async {
    final normalizedApi = _normalizeApiUrl(apiUrl);
    final baseUrl = _stripApiSuffix(normalizedApi);
    final candidates = <Uri>[
      Uri.parse('$baseUrl/actuator/health'),
      Uri.parse('$normalizedApi/auth/health'),
      Uri.parse('$normalizedApi/public/app-version/latest'),
    ];

    for (final uri in candidates) {
      try {
        final response =
            await http.get(uri).timeout(const Duration(seconds: 3));
        if (response.statusCode >= 100 && response.statusCode < 500) {
          return true;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    debugPrint('[Api] Reachability check failed for $apiUrl');
    return false;
  }

  static Future<void> _writeOverride(
      SharedPreferences prefs, String apiUrl) async {
    final normalized = _normalizeApiUrl(apiUrl);
    await prefs.setString(_kApiUrlOverride, normalized);
    await prefs.setInt(
        _kApiUrlOverrideTs, DateTime.now().millisecondsSinceEpoch);
    _baseUrl = _devAdjustBaseForAndroidEmulatorIfNeeded(normalized);
    _imageUrl = _stripApiSuffix(_baseUrl);
    debugPrint('[Api] Override set -> baseUrl=$_baseUrl | imageUrl=$_imageUrl');
  }

  static Future<void> _clearOverride(SharedPreferences prefs) async {
    await prefs.remove(_kApiUrlOverride);
    await prefs.remove(_kApiUrlOverrideTs);
    // If a compile-time override is active, keep its value rather than
    // reverting to an env default.
    if (_compileTimeOverrideActive && _compileTimeApiBase.isNotEmpty) {
      final normalized = _normalizeApiUrl(_compileTimeApiBase);
      _baseUrl = _devAdjustBaseForAndroidEmulatorIfNeeded(normalized);
      _imageUrl = _stripApiSuffix(_baseUrl);
      debugPrint(
          '[Api]Override cleared but compile-time override preserved -> baseUrl=$_baseUrl | imageUrl=$_imageUrl');
      return;
    }

    _baseUrl = _defaultApiUrl;
    _imageUrl = _defaultImageUrl;
    debugPrint(
        '[Api]Override cleared -> baseUrl=$_baseUrl | imageUrl=$_imageUrl');
  }

  /// Programmatic override (e.g., from a hidden settings screen)
  static Future<void> setBaseUrlOverride(String apiUrl) async {
    await ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await _writeOverride(prefs, apiUrl);
  }

  /// Remove override and revert to the environment base
  static Future<void> clearBaseUrlOverride() async {
    await ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await _clearOverride(prefs);
  }

  // ===========================================================================
  // Token & User management
  // ===========================================================================
  // Use secure storage for sensitive values (tokens + user JSON)
  static FlutterSecureStorage? _secure;

  static Future<String?> getAccessToken({bool logMiss = true}) async {
    await ensureInitialized();
    // Return cached token if fresh
    final now = DateTime.now();
    if (_cachedAccessToken != null &&
        _cachedAccessTs != null &&
        now.difference(_cachedAccessTs!) <= _tokenCacheTtl) {
      return _cachedAccessToken;
    }

    var t = await _secure?.read(key: _kAccess);
    if (t == null || t.isEmpty) {
      // Fallback to SharedPreferences for development (iOS simulator issues)
      final prefs = await SharedPreferences.getInstance();
      t = prefs.getString(_kAccess);
      // Debug logging only on cache miss
      if (logMiss) {
        debugPrint(
            '[ApiConstants] getAccessToken: SP fallback, token=${t != null ? "present" : "null"}');
      }
    }

    if (t != null && t.isNotEmpty) {
      _cachedAccessToken = t;
      _cachedAccessTs = now;
    }
    return (t == null || t.isEmpty) ? null : t;
  }

  static Future<String?> getRefreshToken() async {
    await ensureInitialized();
    var t = await _secure?.read(key: _kRefresh);
    if (t == null || t.isEmpty) {
      // Fallback to SharedPreferences for development (iOS simulator issues)
      final prefs = await SharedPreferences.getInstance();
      t = prefs.getString(_kRefresh);
    }
    return (t == null || t.isEmpty) ? null : t;
  }

  static Future<String?> getTrackingToken() async {
    await ensureInitialized();
    var t = await _secure?.read(key: _kTrackingToken);
    if (t == null || t.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      t = prefs.getString(_kTrackingToken);
    }
    return (t == null || t.isEmpty) ? null : t;
  }

  static Future<String?> getTrackingSessionId() async {
    await ensureInitialized();
    var t = await _secure?.read(key: _kTrackingSessionId);
    if (t == null || t.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      t = prefs.getString(_kTrackingSessionId);
    }
    return (t == null || t.isEmpty) ? null : t;
  }

  static Future<int?> getTrackingExpiresAtMs() async {
    await ensureInitialized();
    var raw = await _secure?.read(key: _kTrackingExpiresAtMs);
    if (raw == null || raw.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kTrackingExpiresAtMs);
    }
    return int.tryParse(raw);
  }

  static Future<void> saveTrackingSession({
    required String trackingToken,
    required String sessionId,
    required int expiresAtMs,
  }) async {
    await _secure?.write(key: _kTrackingToken, value: trackingToken);
    await _secure?.write(key: _kTrackingSessionId, value: sessionId);
    await _secure?.write(key: _kTrackingExpiresAtMs, value: '$expiresAtMs');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTrackingToken, trackingToken);
    await prefs.setString(_kTrackingSessionId, sessionId);
    await prefs.setInt(_kTrackingExpiresAtMs, expiresAtMs);
  }

  static Future<void> clearTrackingSession() async {
    await ensureInitialized();
    await _secure?.delete(key: _kTrackingToken);
    await _secure?.delete(key: _kTrackingSessionId);
    await _secure?.delete(key: _kTrackingExpiresAtMs);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTrackingToken);
    await prefs.remove(_kTrackingSessionId);
    await prefs.remove(_kTrackingExpiresAtMs);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    debugPrint(
        '[ApiConstants] saveTokens called with accessToken length: ${accessToken.length}, refreshToken length: ${refreshToken.length}');
    await _secure?.write(key: _kAccess, value: accessToken);
    await _secure?.write(key: _kRefresh, value: refreshToken);

    // Fallback to SharedPreferences for development (iOS simulator issues)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, accessToken);
    await prefs.setString(_kRefresh, refreshToken);
    debugPrint(
        '[ApiConstants] saveTokens: saved to both secure storage and SharedPreferences');

    final listener = _tokenUpdateListener;
    if (listener != null) {
      try {
        await listener(accessToken);
      } catch (e, st) {
        debugPrint('[ApiConstants] tokenUpdateListener failed: $e\n$st');
      }
    }
  }

  static Future<void> clearTokens() async {
    _lastRefreshSuccessAt = null;
    _refreshBlockedUntil = null;
    await _secure?.delete(key: _kAccess);
    await _secure?.delete(key: _kRefresh);
    await _secure?.delete(key: _kTrackingToken);
    await _secure?.delete(key: _kTrackingSessionId);
    await _secure?.delete(key: _kTrackingExpiresAtMs);

    // Fallback to SharedPreferences for development (iOS simulator issues)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kTrackingToken);
    await prefs.remove(_kTrackingSessionId);
    await prefs.remove(_kTrackingExpiresAtMs);
  }

  /// Persist the full login response (flexible server shapes).
  static Future<void> persistLoginResponse(Map<String, dynamic> data) async {
    debugPrint(
        '[Auth] persistLoginResponse called with data keys: ${data.keys.toList()}');
    final token = (data['token'] ?? data['accessToken'] ?? data['access_token'])
        as String?;
    final refresh = (data['refreshToken'] ?? data['refresh_token']) as String?;
    final user = data['user'];

    debugPrint(
        '[Auth] Extracted token: ${token != null ? "present (${token.length} chars)" : "null"}');
    debugPrint(
        '[Auth] Extracted refresh: ${refresh != null ? "present (${refresh.length} chars)" : "null"}');
    debugPrint('[Auth] Extracted user: ${user != null ? "present" : "null"}');

    if (token == null || token.isEmpty) {
      throw StateError('Login response missing "token".');
    }
    if (refresh == null || refresh.isEmpty) {
      debugPrint(
          '[Auth] ℹ️ No refresh token in response; refresh flow may be disabled on server.');
    }

    await saveTokens(accessToken: token, refreshToken: refresh ?? '');
    _refreshBlockedUntil = null;

    if (user != null) {
      final userJson = jsonEncode(user);
      await _secure?.write(key: _kUserJson, value: userJson);

      // Fallback to SharedPreferences for development (iOS simulator issues)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserJson, userJson);
    }
    debugPrint(
        '[Auth] Login data persisted (token + user). Token length: ${token.length}, Refresh present: ${refresh != null && refresh.isNotEmpty}');
  }

  static Future<Map<String, dynamic>?> getUser() async {
    var raw = await _secure?.read(key: _kUserJson);
    if (raw == null || raw.isEmpty) {
      // Fallback to SharedPreferences for development (iOS simulator issues)
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_kUserJson);
    }
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ---- Single-read helpers (no repeated getUser calls) ----
  static Future<int?> getDriverId() async {
    final u = await getUser();
    final id = u?['driverId'];
    if (id is int) return id;
    return int.tryParse('$id');
  }

  static Future<String?> getUsername() async =>
      (await getUser())?['username'] as String?;
  static Future<String?> getZone() async =>
      (await getUser())?['zone'] as String?;
  static Future<String?> getVehicleType() async =>
      (await getUser())?['vehicleType'] as String?;
  static Future<String?> getStatus() async =>
      (await getUser())?['status'] as String?;
  static Future<List<String>> getRoles() async {
    final u = await getUser();
    final r = u?['roles'];
    if (r is List) return r.map((e) => '$e').toList();
    return const [];
  }

  static Future<void> clearUser() async {
    await _secure?.delete(key: _kUserJson);

    // Fallback to SharedPreferences for development (iOS simulator issues)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserJson);
  }

  static Future<bool> isLoggedIn() async {
    await ensureInitialized();
    final token = await getAccessToken(logMiss: false);
    final result = token?.isNotEmpty == true;
    debugPrint(
        '[ApiConstants] isLoggedIn: token exists=${token != null}, isNotEmpty=$result');
    return result;
  }

  /// Checks access token expiry via 'exp' (seconds since epoch) with leeway.
  static Future<bool> isTokenExpired({int leewaySeconds = 60}) async {
    final token = await getAccessToken(logMiss: false);
    if (token == null || token.isEmpty) return true;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded =
          json.decode(utf8.decode(base64Url.decode(normalized))) as Map;
      final exp = (decoded['exp'] is int)
          ? decoded['exp'] as int
          : int.tryParse('${decoded['exp']}');
      if (exp == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= (exp - leewaySeconds);
    } catch (e, st) {
      debugPrint('[Auth] Token decode error: $e\n$st');
      return true;
    }
  }

  /// Ensures you have a fresh access token; returns null if refresh failed.
  static Future<String?> ensureFreshAccessToken() async {
    final accessToken = await getAccessToken(logMiss: false);
    if (accessToken == null || accessToken.isEmpty) {
      // Logged-out state: do not attempt refresh to avoid noisy logs.
      return null;
    }
    if (await isTokenExpired()) {
      return await refreshAccessToken();
    }
    return accessToken;
  }

  static Future<String?> ensureFreshTrackingToken() async {
    await ensureInitialized();
    final current = await getTrackingToken();
    if (current == null || current.isEmpty) return null;

    final expMs = await getTrackingExpiresAtMs();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final closeToExpiry = expMs != null
        ? nowMs >= (expMs - 5 * 60 * 1000)
        : await _isJwtExpired(current, leewaySeconds: 60);
    if (!closeToExpiry) return current;
    return await refreshTrackingToken();
  }

  // ===========================================================================
  //  🔁 Token refresh (supports header + JSON-body fallback)
  // ===========================================================================
  static const String _refreshTokenPath = '/auth/refresh';
  static const String _trackingRefreshPath = '/driver/tracking/session/refresh';
  static Future<String?>? _refreshInFlight;
  static DateTime? _lastRefreshSuccessAt;
  static DateTime? _refreshBlockedUntil;
  static const Duration _refreshSuccessCooldown = Duration(seconds: 20);
  static const Duration _refreshBlockDuration = Duration(minutes: 2);

  static Future<String?> refreshAccessToken() async {
    final now = DateTime.now();
    if (_refreshBlockedUntil != null && now.isBefore(_refreshBlockedUntil!)) {
      return null;
    }

    if (_lastRefreshSuccessAt != null &&
        now.difference(_lastRefreshSuccessAt!) < _refreshSuccessCooldown) {
      return await getAccessToken(logMiss: false);
    }

    if (_refreshInFlight != null) {
      return _refreshInFlight;
    }

    final completer = Completer<String?>();
    _refreshInFlight = completer.future;
    await ensureInitialized();
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        final accessToken = await getAccessToken(logMiss: false);
        // Logged-out state: both tokens absent -> stay quiet and return null.
        if (accessToken == null || accessToken.isEmpty) {
          completer.complete(null);
          return null;
        }
        // Corrupted session: access exists but no refresh -> force re-auth.
        debugPrint('[Auth] Refresh token missing while access token exists.');
        SessionManager.instance.markAuthInvalid(
          reason: 'refresh_token_missing_with_access_present',
        );
        completer.complete(null);
        return null;
      }

      final uri = Uri.parse('$_baseUrl$_refreshTokenPath');

      // Single attempt: Authorization header with refresh token (backend contract)
      final res = await http.post(
        uri,
        headers: {...defaultHeaders, 'Authorization': 'Bearer $refreshToken'},
      ).timeout(const Duration(seconds: 12));
      if (_is2xx(res.statusCode)) {
        final token = await _persistRefreshResponse(res.body);
        _lastRefreshSuccessAt = DateTime.now();
        _refreshBlockedUntil = null;
        completer.complete(token);
        return token;
      }

      debugPrint('[Auth] Refresh failed: ${res.statusCode} ${res.body}');
      // If backend indicates revoked/invalid, clear tokens and trigger forced logout.
      if (res.statusCode == 401 ||
          res.statusCode == 403 ||
          res.body.contains('invalid') ||
          res.body.contains('revoked')) {
        await clearTokens();
        _refreshBlockedUntil = DateTime.now().add(_refreshBlockDuration);
        // Also clear user to avoid stale state
        await clearUser();
        // Notify session manager to navigate to login
        SessionManager.instance.markAuthInvalid(
          reason: 'refresh_token_invalid_or_revoked',
        );
      }
      completer.complete(null);
      return null;
    } catch (e, st) {
      debugPrint('[Auth] Refresh exception: $e\n$st');
      completer.complete(null);
      return null;
    } finally {
      _refreshInFlight = null;
    }
  }

  static Future<String?> refreshTrackingToken() async {
    await ensureInitialized();
    final current = await getTrackingToken();
    if (current == null || current.isEmpty) return null;
    try {
      final uri = Uri.parse('$_baseUrl$_trackingRefreshPath');
      final res = await http.post(
        uri,
        headers: {...defaultHeaders, 'Authorization': 'Bearer $current'},
      ).timeout(const Duration(seconds: 12));
      if (!_is2xx(res.statusCode)) {
        debugPrint('[Tracking] refresh failed: ${res.statusCode} ${res.body}');
        return null;
      }
      final raw = json.decode(res.body);
      Map<String, dynamic> payload;
      if (raw is Map<String, dynamic>) {
        if (raw['data'] is Map<String, dynamic>) {
          payload = raw['data'] as Map<String, dynamic>;
        } else {
          payload = raw;
        }
      } else {
        return null;
      }
      final token =
          (payload['trackingToken'] ?? payload['tracking_token']) as String?;
      final sessionId =
          (payload['sessionId'] ?? payload['session_id']) as String?;
      final expiresAt = payload['expiresAtEpochMs'] ?? payload['expiresAt'];
      final expiresAtMs =
          expiresAt is int ? expiresAt : int.tryParse('$expiresAt');
      if (token == null ||
          token.isEmpty ||
          sessionId == null ||
          sessionId.isEmpty ||
          expiresAtMs == null) {
        return null;
      }
      await saveTrackingSession(
        trackingToken: token,
        sessionId: sessionId,
        expiresAtMs: expiresAtMs,
      );
      return token;
    } catch (e) {
      debugPrint('[Tracking] refresh exception: $e');
      return null;
    }
  }

  static Future<bool> _isJwtExpired(String token,
      {int leewaySeconds = 60}) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded =
          json.decode(utf8.decode(base64Url.decode(normalized))) as Map;
      final exp = (decoded['exp'] is int)
          ? decoded['exp'] as int
          : int.tryParse('${decoded['exp']}');
      if (exp == null) return true;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= (exp - leewaySeconds);
    } catch (_) {
      return true;
    }
  }

  static bool _is2xx(int c) => c >= 200 && c < 300;

  static Future<String?> _persistRefreshResponse(String body) async {
    final jsonData = json.decode(body) as Map<String, dynamic>;
    final payload = (jsonData['data'] is Map<String, dynamic>)
        ? jsonData['data'] as Map<String, dynamic>
        : jsonData;

    // Pattern A: same as login
    if (jsonData.containsKey('token') || jsonData.containsKey('access_token')) {
      await persistLoginResponse(jsonData);
      final newToken = await getAccessToken();
      debugPrint('[Auth] Access token refreshed.');
      return newToken;
    }

    // Pattern B: classic keys
    final newAccessToken = (payload['token'] ??
        payload['access_token'] ??
        payload['accessToken']) as String?;
    final newRefreshToken =
        (payload['refresh_token'] ?? payload['refreshToken']) as String?;

    if (newAccessToken != null && newAccessToken.isNotEmpty) {
      await _secure?.write(key: _kAccess, value: newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _secure?.write(key: _kRefresh, value: newRefreshToken);
      }

      // Fallback to SharedPreferences for development (iOS simulator issues)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAccess, newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await prefs.setString(_kRefresh, newRefreshToken);
      }

      debugPrint('[Auth] Access token refreshed (fallback).');
      return newAccessToken;
    } else {
      debugPrint('[Auth] Missing access token in refresh response.');
      return null;
    }
  }

  // ===========================================================================
  //  🧾 HTTP headers
  // ===========================================================================
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> getHeaders() async {
    await ensureInitialized();
    final token = await ensureFreshAccessToken();
    if (token != null && token.isNotEmpty) {
      return {...defaultHeaders, 'Authorization': 'Bearer $token'};
    }
    return Map.from(defaultHeaders);
  }

  // ===========================================================================
  // 🌐 REST endpoints (adjust paths to your backend)
  // ===========================================================================
  static const String _loginPath = '/auth/driver/login';
  static const String _deliveriesPath = '/driver/deliveries';
  static const String _updateLocationPath = '/driver/location/update';

  // 🚛 Driver endpoints map
  static const Map<String, String> driverEndpoints = {
    'profile': '/driver/profile',
    'assigned-vehicles': '/driver/assigned-vehicles',
    'current-assignment': '/driver/current-assignment',
    'assign-vehicle': '/driver/assign-vehicle',
    'update-location': '/driver/location/update',
    'go-online': '/driver/go-online',
    'go-offline': '/driver/go-offline',
  };

  // 📦 Dispatch endpoints map
  static const Map<String, String> dispatchEndpoints = {
    'list': '/driver/dispatches',
    'accept': '/driver/dispatches/{id}/accept',
    'reject': '/driver/dispatches/{id}/reject',
    'status-update': '/driver/dispatches/{id}/status',
    'start': '/driver/dispatches/{id}',
    'arrive': '/driver/dispatches/{id}',
    'complete': '/driver/dispatches/{id}',
    // Legacy alias kept for compatibility with older repository methods.
    'upload-proof': '/driver/dispatches/{id}/unload',
    'unload': '/driver/dispatches/{id}/unload',
    // New finance endpoints (driver-facing)
    'odometer': '/driver/dispatches/{id}/odometer',
    'fuel-request': '/driver/dispatches/{id}/fuel-request',
    'cod-settlement': '/driver/dispatches/{id}/cod-settlement',
    'breakdown': '/driver/dispatches/{id}/breakdown',
  };

  // 🔔 Notification endpoints map
  static const Map<String, String> notificationEndpoints = {
    'list': '/notifications',
    'unread-count': '/notifications/unread-count',
    'mark-read': '/notifications/{id}/read',
    'mark-all-read': '/notifications/read-all',
    'delete': '/notifications/{id}',
    'delete-all': '/notifications',
  };

  static Uri get login => Uri.parse('$_baseUrl$_loginPath');
  static Uri get deliveries => Uri.parse('$_baseUrl$_deliveriesPath');
  static Uri get updateLocation => Uri.parse('$_baseUrl$_updateLocationPath');

  static const String _updateLocationBatchPath =
      '/driver/location/update/batch';
  static Uri get updateLocationBatch =>
      Uri.parse('$_baseUrl$_updateLocationBatchPath');
  static Uri endpoint(String path) => Uri.parse('$_baseUrl$path');

  // ===========================================================================
  //  WebSocket URLs (native + SockJS)
  // ===========================================================================
  static String _buildWsBaseFromApi(String apiUrl) {
    if (apiUrl.isEmpty) return 'wss://svtms.svtrucking.biz'; // safe fallback
    final uri = Uri.parse(apiUrl);
    final scheme = (uri.scheme == 'https') ? 'wss' : 'ws';
    final host = uri.host;
    final port =
        (uri.hasPort && uri.port != 0 && uri.port != 80 && uri.port != 443)
            ? ':${uri.port}'
            : '';
    return '$scheme://$host$port';
  }

  static Future<String> getSockJsWebSocketUrl() async {
    await ensureInitialized();
    final wsBase = _buildWsBaseFromApi(_baseUrl);
    final url = '$wsBase/ws-sockjs';
    debugPrint('[WS] SockJS URL: $url');
    return url;
  }

  static Future<String> getNativeWebSocketUrl() async {
    await ensureInitialized();
    final wsBase = _buildWsBaseFromApi(_baseUrl);
    // Use native Spring STOMP endpoint directly (no SockJS suffix here).
    // Backend exposes '/ws' for native and '/ws-sockjs' for SockJS.
    final url = '$wsBase/ws';
    debugPrint('[WS] Native WS base: $url');
    return url;
  }

  /// Native WS URL with token
  static Future<String> getNativeWebSocketUrlWithToken(String token) async {
    final base = await getNativeWebSocketUrl();
    final cleaned = token.startsWith('Bearer ') ? token.substring(7) : token;
    final encoded = Uri.encodeQueryComponent(cleaned.trim());
    final url = '$base?token=$encoded';
    debugPrint('[WS] Native WS w/ token: $url');
    return url;
  }

  /// Driver location WebSocket URL
  static Future<String> getDriverLocationWebSocketUrl() async {
    await ensureInitialized();
    final wsBase = _buildWsBaseFromApi(_baseUrl);
    // Backend exposes native STOMP endpoint at '/ws'. Prefer that.
    final url = '$wsBase/ws';
    debugPrint('[WS] Driver Location WS URL (native /ws): $url');
    return url;
  }

  /// Driver location WS URL including token query parameter
  static Future<String> getDriverLocationWebSocketUrlWithToken(
      String token) async {
    final base = await getDriverLocationWebSocketUrl();
    final sep = base.contains('?') ? '&' : '?';
    final cleaned = token.startsWith('Bearer ') ? token.substring(7) : token;
    final encoded = Uri.encodeQueryComponent(cleaned.trim());
    final url = '$base${sep}token=$encoded';
    debugPrint(
        '[WS] Driver Location WS URL (token masked): ${url.replaceAll(RegExp(r'token=[^&]+'), 'token=***')}');
    return url;
  }

  // ===========================================================================
  // 🖼  Utilities
  // ===========================================================================
  /// Normalizes image URLs by replacing localhost:8080 with actual API base URL.
  /// This handles backend responses that hardcode localhost for images.
  static String image(String relativePath) {
    if (relativePath.isEmpty) return '';
    final raw = relativePath.trim();
    if (raw.isEmpty) return '';

    // If it's a relative path, build absolute URL
    if (!raw.startsWith('http')) {
      final cleaned = _normalizeImagePath(
        raw.startsWith('/') ? raw.substring(1) : raw,
      );
      return '$imageUrl/$cleaned';
    }

    // Replace hardcoded localhost:8080 with actual API base URL
    // Backend may return: http://localhost:8080/uploads/...
    // We need: http://192.168.1.2:8080/uploads/...
    var normalized = raw;
    if (normalized.contains('localhost:8080')) {
      // Extract the image path part (e.g., /uploads/profiles/...)
      final match = RegExp(r'http[s]?://localhost:8080(/.*)');
      final pathMatch = match.firstMatch(normalized);
      if (pathMatch != null) {
        final imagePath = _normalizeImagePath(pathMatch.group(1) ?? '');
        normalized = '$imageUrl$imagePath';
      }
    }

    return _normalizeImagePath(normalized, allowProtocol: true);
  }

  static String _normalizeImagePath(
    String path, {
    bool allowProtocol = false,
  }) {
    var normalized = path.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) return normalized;

    if (allowProtocol && normalized.contains('://')) {
      final split = normalized.split('://');
      if (split.length == 2) {
        final scheme = split.first;
        var rest = split.last;
        rest = rest.replaceAll(RegExp(r'/+'), '/');
        rest = rest.replaceFirst(
            RegExp(r'^(localhost|127\.0\.0\.1):8080'),
            Uri.parse(imageUrl).host +
                (Uri.parse(imageUrl).hasPort
                    ? ':${Uri.parse(imageUrl).port}'
                    : ''));
        normalized = '$scheme://$rest';
      }
    } else {
      normalized = normalized.replaceAll(RegExp(r'/+'), '/');
    }

    normalized = normalized.replaceAll(RegExp(r'(/uploads/)+'), '/uploads/');
    return normalized;
  }
}
