import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

class NativeServiceBridge {
  /// Must match MainActivity.kt method channel
  static const MethodChannel _ch = MethodChannel('sv/native_service');

  static bool _hookInstalled = false;

  static void _ensureLifecycleHookInstalled() {
    if (_hookInstalled) return;
    WidgetsBinding.instance.addObserver(_LifecycleHook());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startServiceOnce();
    });
    _hookInstalled = true;
  }

  // Reentrancy guards (Dart side)
  static bool _starting = false;
  static bool _started = false;
  static DateTime? _lastStartAt;
  static const _debounce = Duration(seconds: 1);

  // Legacy WS derivation removed; use ApiConstants.getDriverLocationWebSocketUrlWithToken

  /// Start native location service (Android foreground service / iOS native background tracker).
  /// Optionally pass `token`, `driverId`, or a prebuilt `wsUrl`.
  static Future<bool> startNativeLocationService({
    String? token,
    String? driverId,
    String? wsUrl,
  }) async {
    _ensureLifecycleHookInstalled();
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    // Debounce “double taps” from multiple call sites
    final now = DateTime.now();
    if (_lastStartAt != null && now.difference(_lastStartAt!) < _debounce) {
      _log('[Bridge] startNativeLocationService debounced');
      return _started;
    }
    _lastStartAt = now;

    try {
      final prefs = await SharedPreferences.getInstance();
      final tk = token ?? await ApiConstants.getAccessToken();
      final trackingToken = await ApiConstants.getTrackingToken();
      final trackingSessionId = await ApiConstants.getTrackingSessionId();
      final refreshToken = await ApiConstants.getRefreshToken();
      final id = driverId ?? prefs.getString('driverId');

      if ((tk == null || tk.isEmpty) || (id == null || id.isEmpty)) {
        _log('[Bridge] Missing token/driverId → skip start.');
        return false;
      }

      // Resolve base API from settings or constants
      final baseFromPrefs = (prefs.getString('apiUrl') ?? '').trim();
      final resolvedBaseApi =
          baseFromPrefs.isNotEmpty ? baseFromPrefs : ApiConstants.baseUrl;

      // Resolve WS URL (prefer centralized builder with token)
      // Precedence: explicit wsUrl arg → prefs wsUrl → centralized default
      final wsAuthToken = (trackingToken != null && trackingToken.isNotEmpty)
          ? trackingToken
          : tk;
      final wsAuthTokenSafe = wsAuthToken.trim();

      String url;
      final wsFromPrefs = (prefs.getString('wsUrl') ?? '').trim();
      if (wsUrl != null && wsUrl.isNotEmpty) {
        final sanitized = _sanitizeWsUrl(wsUrl);
        if (sanitized.isNotEmpty) {
          url = _withFreshWsToken(sanitized, wsAuthTokenSafe);
        } else {
          url = await ApiConstants.getDriverLocationWebSocketUrlWithToken(
              wsAuthTokenSafe);
        }
      } else if (wsFromPrefs.isNotEmpty) {
        final sanitized = _sanitizeWsUrl(wsFromPrefs);
        if (sanitized.isNotEmpty) {
          url = _withFreshWsToken(sanitized, wsAuthTokenSafe);
        } else {
          url = await ApiConstants.getDriverLocationWebSocketUrlWithToken(
              wsAuthTokenSafe);
        }
      } else {
        url = await ApiConstants.getDriverLocationWebSocketUrlWithToken(
            wsAuthTokenSafe);
      }

      // Optional extras for native diagnostics/payload enrichment
      final driverName = prefs.getString('driverName');
      final vehiclePlate = prefs.getString('vehiclePlate');

      // Optional interval override (seconds) if present in prefs
      final intervalSec = prefs.getInt('locationIntervalSec');

      // Avoid reentry across isolates
      if (_starting) {
        _log('[Bridge] Already starting; skip.');
        return true;
      }
      _starting = true;

      bool wasRunning = false;
      try {
        wasRunning = await isServiceRunning();
      } catch (_) {}

      final args = <String, dynamic>{
        'token': tk,
        'trackingToken': trackingToken,
        'trackingSessionId': trackingSessionId,
        'refreshToken': refreshToken,
        'driverId': id,
        'wsUrl': url,
        'baseApiUrl': resolvedBaseApi,
        'driverName': driverName,
        'vehiclePlate': vehiclePlate,
      };
      if (intervalSec != null && intervalSec > 0) {
        args['locationIntervalSec'] = intervalSec;
      }

      final ok = await _invokeWithTimeout<bool>(
          () => _ch.invokeMethod<bool>('startService', args));

      _log(
          '[Bridge] startService${wasRunning ? " refresh" : ""} (driverId=$id, base=$resolvedBaseApi, ws=${_maskWs(url)}) → ${ok == true ? "OK" : "NOK"}');

      // If native returned false, sanity check once
      if (ok != true) {
        final running = await isServiceRunning();
        if (!running) {
          _log('[Bridge] Not running after start → retry once');
          final retry = await _invokeWithTimeout<bool>(
              () => _ch.invokeMethod<bool>('startService', args));
          _started = retry == true || await isServiceRunning();
          return _started;
        }
      }

      _started = ok == true || await isServiceRunning();
      return _started;
    } on MissingPluginException catch (e) {
      _log('[Bridge] MissingPlugin (is native updated?): $e');
      return false;
    } on PlatformException catch (e) {
      _log('[Bridge] PlatformException start: ${e.code} ${e.message}');
      return false;
    } on TimeoutException {
      _log('[Bridge] start timed out');
      return false;
    } catch (e) {
      _log('[Bridge] start failed: $e');
      return false;
    } finally {
      _starting = false;
    }
  }

  /// Idempotent “start once”
  static Future<bool> startServiceOnce({
    String? token,
    String? driverId,
    String? wsUrl,
  }) async {
    _ensureLifecycleHookInstalled();
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (_started || _starting) {
      _log('[Bridge] startServiceOnce → already started/starting; skip');
      return true;
    }
    return startNativeLocationService(
        token: token, driverId: driverId, wsUrl: wsUrl);
  }

  /// Stop native service
  static Future<bool> stopNativeLocationService() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final ok = await _invokeWithTimeout<bool>(
          () => _ch.invokeMethod<bool>('stopService'));
      _log('[Bridge] stopService → ${ok == true ? "OK" : "NOK"}');
      if (ok == true) _started = false;
      return ok ?? false;
    } on MissingPluginException catch (e) {
      _log('[Bridge] MissingPlugin stop: $e');
      return false;
    } on PlatformException catch (e) {
      _log('[Bridge] PlatformException stop: ${e.code} ${e.message}');
      return false;
    } on TimeoutException {
      _log('[Bridge] stop timed out');
      return false;
    } catch (e) {
      _log('[Bridge] stop failed: $e');
      return false;
    }
  }

  /// Ask native if service is running
  static Future<bool> isServiceRunning() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final ok = await _invokeWithTimeout<bool>(
          () => _ch.invokeMethod<bool>('isServiceRunning'));
      return ok ?? false;
    } catch (e) {
      _log('[Bridge] isServiceRunning failed: $e');
      return false;
    }
  }

  /// Notify native service that the token changed (prefer instead of full restart).
  /// Pairs with LocationService’s ACTION_TOKEN_UPDATED dynamic receiver.
  /// Implement in MainActivity.kt:
  ///   methodChannel.setMethodCallHandler { call, result ->
  ///     if (call.method == "notifyTokenUpdated") {
  ///       val i = Intent("com.svtrucking.svdriverapp.ACTION_TOKEN_UPDATED")
  ///       context.sendBroadcast(i)
  ///       result.success(true)
  ///     }
  ///   }
  static Future<bool> notifyTokenUpdated({
    required String token,
    String? trackingToken,
    String? trackingSessionId,
    String? refreshToken,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    final normalized = token.trim();
    if (normalized.isEmpty) {
      _log('[Bridge] notifyTokenUpdated skipped: empty token');
      return false;
    }
    try {
      final ok = await _invokeWithTimeout<bool>(
          () => _ch.invokeMethod<bool>('notifyTokenUpdated', {
                'token': normalized,
                if (trackingToken != null && trackingToken.trim().isNotEmpty)
                  'trackingToken': trackingToken.trim(),
                if (trackingSessionId != null &&
                    trackingSessionId.trim().isNotEmpty)
                  'trackingSessionId': trackingSessionId.trim(),
                if (refreshToken != null && refreshToken.trim().isNotEmpty)
                  'refreshToken': refreshToken.trim(),
              }));
      _log('[Bridge] notifyTokenUpdated → ${ok == true ? "OK" : "NOK"}');
      return ok ?? false;
    } on MissingPluginException {
      // Fallback: attempt a soft restart of service to refresh WS
      _log(
          '[Bridge] notifyTokenUpdated not implemented; soft restart service instead');
      final prefs = await SharedPreferences.getInstance();
      return startNativeLocationService(
        token: normalized,
        driverId: prefs.getString('driverId'),
      );
    } catch (e) {
      _log('[Bridge] notifyTokenUpdated failed: $e');
      return false;
    }
  }

  // ---- Legacy shims (optional while migrating old callers) ----
  static const MethodChannel _legacy = MethodChannel('native_location_service');

  static Future<void> startNativeLocationServiceLegacy(
      {required String token}) async {
    await startNativeLocationService(token: token);
    try {
      final ws =
          await ApiConstants.getDriverLocationWebSocketUrlWithToken(token);
      await _legacy.invokeMethod('startLocationService', {'url': ws});
      _log('[Bridge] (legacy) startLocationService sent');
    } catch (_) {}
  }

  static Future<void> stopNativeLocationServiceLegacy() async {
    await stopNativeLocationService();
    _started = false;
    try {
      await _legacy.invokeMethod('stopLocationService');
      _log('[Bridge] (legacy) stopLocationService sent');
    } catch (_) {}
  }

  // ---- helpers ----
  static Future<T?> _invokeWithTimeout<T>(Future<T?> Function() call) {
    // Some OEMs can stall a MethodChannel call. Keep it snappy.
    return call().timeout(const Duration(seconds: 6));
  }

  static void _log(String msg) {
    // ignore: avoid_print
    print(msg);
  }

  static String _maskWs(String url) {
    final i = url.indexOf('token=');
    if (i < 0) return url;
    final head = url.substring(0, i + 6);
    final tail = url.substring(i + 6);
    if (tail.length <= 9) return '$head***';
    // Keep only last 6 for diagnostics
    return '$head***${tail.substring(tail.length - 6)}';
  }

  static String _withFreshWsToken(String rawUrl, String token) {
    final uri = Uri.parse(rawUrl);
    final nextParams = Map<String, String>.from(uri.queryParameters)
      ..remove('token')
      ..['token'] = token;
    return uri.replace(queryParameters: nextParams).toString();
  }

  static String _sanitizeWsUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    final candidate =
        trimmed.contains('://') ? trimmed : 'https://$trimmed';
    try {
      final uri = Uri.parse(candidate);
      if (uri.host.isEmpty || uri.port == 0) return '';

      final scheme = uri.scheme == 'https'
          ? 'wss'
          : uri.scheme == 'http'
              ? 'ws'
              : uri.scheme;
      if (!(scheme == 'ws' || scheme == 'wss')) return '';

      var path = uri.path.trim();
      if (path.isEmpty || path == '/') {
        path = '/ws';
      } else if (!path.endsWith('/ws') && path != '/ws') {
        path = '$path/ws';
      }

      return uri
          .replace(
            scheme: scheme,
            path: path,
            fragment: '',
          )
          .toString();
    } catch (_) {
      return '';
    }
  }
}

/// Private lifecycle observer to restart native service on resume.
class _LifecycleHook extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NativeServiceBridge.startServiceOnce();
    }
  }
}
