import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/utils/version_utils.dart';
import 'package:tms_driver_app/core/constants/app_constants.dart';

/// Centralized settings provider
/// - Reads cached settings fast on startup
/// - Refreshes from API with TTL (and on demand)
/// - Persists changes locally + syncs to backend
class SettingsProvider with ChangeNotifier {
  static const String _compileTimeApiBase =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  // ---- Local cache keys / TTL ----
  static const _kCacheKey = 'app_settings_json';
  static const _kCacheTs = 'app_settings_last_fetch_ms';
  static const _kTtlMs = 45 * 60 * 1000; // 45 minutes
  static const _kFailureBackoffMs = 60 * 1000; // 1 minute

  // ---- Backing fields ----
  String _apiUrl = ApiConstants.baseUrl; // default from build config
  Locale _currentLocale = const Locale('km');
  bool _notificationsEnabled = true;
  bool _biometricQuickUnlock = false;
  int _dashboardRefreshSec = 20;
  String _mapType = 'normal';
  bool _darkModeEnabled = false;
  String _mapTileUrlTemplate = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Additional server-driven options (optional; extend as needed)
  int? _trackingIntervalMs;
  String? _wsUrl;
  String? _minSupportedAppVersion;
  int _lastFailureTsMs = 0;

  SettingsProvider() {
    _loadSettings(); // load cached ASAP, then refresh (if stale)
  }

  // --- helpers to compose URLs without double /api and stray slashes ---
  String _normalizeBase(String base) {
    if (base.isEmpty) return ApiConstants.baseUrl;
    var b = base.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);
    return b;
  }

  Uri _endpoint(String base, String path) {
    final b = _normalizeBase(base);
    return b.endsWith('/api')
        ? Uri.parse('$b/$path')
        : Uri.parse('$b/api/$path');
  }

  // ---- Public getters ----
  String get apiUrl => _apiUrl;
  Locale get currentLocale => _currentLocale;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get biometricQuickUnlock => _biometricQuickUnlock;
  int get dashboardRefreshSec => _dashboardRefreshSec;
  String get mapType => _mapType;
  bool get darkModeEnabled => _darkModeEnabled;
  String get mapTileUrlTemplate => _mapTileUrlTemplate;
  int? get trackingIntervalMs => _trackingIntervalMs;
  String? get wsUrl => _wsUrl;
  String? get minSupportedAppVersion => _minSupportedAppVersion;
  bool get isUpdateRequired {
    if (_minSupportedAppVersion == null || _minSupportedAppVersion!.isEmpty) {
      return false;
    }
    // In a real app, you'd get the version from package_info_plus.
    // For this case, we use the hardcoded constant.
    return VersionUtils.isVersionLessThan(
      AppConstants.appVersion,
      _minSupportedAppVersion!,
    );
  }


  // =========================
  // Mutations (user actions)
  // =========================

  /// Update API base URL
  Future<void> updateApiUrl(String newUrl) async {
    final uri = Uri.tryParse(newUrl);
    final isValid = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (uri.host.isNotEmpty);
    if (!isValid) {
      debugPrint(' Invalid API URL: $newUrl');
      return;
    }

    // Persist centrally via ApiConstants (writes timestamped override)
    await ApiConstants.setBaseUrlOverride(newUrl);

    // Mirror locally for UI display and interop with existing reads
    _apiUrl = ApiConstants.baseUrl;
    await _saveToPrefs('apiUrl', _apiUrl);
    // Re-sync current settings to the *new* API endpoint
    await _syncSettingToApi('apiUrl', _apiUrl);
    notifyListeners();

    // Trigger a fresh pull from the new base
    await refreshFromServer(force: true);
  }

  /// Clear API override and revert to environment default
  Future<void> clearApiUrlOverride() async {
    await ApiConstants.clearBaseUrlOverride();
    _apiUrl = ApiConstants.baseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('apiUrl');
    } catch (_) {}
    notifyListeners();
    await refreshFromServer(force: true);
  }

  /// Change current locale
  Future<void> setLocale(Locale locale) async {
    const supported = [Locale('en'), Locale('km')];
    if (!supported.contains(locale)) return;

    _currentLocale = locale;
    await _saveToPrefs('localeCode', locale.languageCode);
    await _syncSettingToApi('locale', locale.languageCode);
    notifyListeners();
  }

  /// Toggle push notifications
  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _saveBoolToPrefs('notificationsEnabled', value);
    await _syncSettingToApi('notificationsEnabled', value.toString());
    notifyListeners();
  }

  Future<void> setBiometricQuickUnlock(bool value) async {
    _biometricQuickUnlock = value;
    await _saveBoolToPrefs('biometricQuickUnlock', value);
    await _syncSettingToApi('biometricQuickUnlock', value.toString());
    notifyListeners();
  }

  Future<void> setDashboardRefreshSec(int value) async {
    final normalized = value.clamp(10, 300);
    _dashboardRefreshSec = normalized;
    await _saveIntToPrefs('dashboardRefreshSec', normalized);
    await _syncSettingToApi('dashboardRefreshSec', '$normalized');
    notifyListeners();
  }

  Future<void> setMapType(String value) async {
    const allowed = {'normal', 'satellite', 'terrain', 'hybrid'};
    if (!allowed.contains(value)) return;
    _mapType = value;
    await _saveToPrefs('mapType', value);
    await _syncSettingToApi('mapType', value);
    notifyListeners();
  }

  Future<void> setThemeDarkMode(bool enabled) async {
    _darkModeEnabled = enabled;
    await _saveBoolToPrefs('darkModeEnabled', enabled);
    await _syncSettingToApi('themeMode', enabled ? 'dark' : 'light');
    notifyListeners();
  }

  // =========================
  // Boot / Cache / Refresh
  // =========================

  /// Load user settings from local cache first; kick off background refresh if stale.
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Primitive local fields
      _apiUrl = prefs.getString('apiUrl') ?? _apiUrl;
      final localeCode = prefs.getString('localeCode');
      final notif = prefs.getBool('notificationsEnabled');
      final biometric = prefs.getBool('biometricQuickUnlock');
      final refreshSec = prefs.getInt('dashboardRefreshSec');
      final mapType = prefs.getString('mapType');
      final darkModeEnabled = prefs.getBool('darkModeEnabled');
      if (localeCode != null && localeCode.isNotEmpty) {
        _currentLocale = Locale(localeCode);
      }
      _notificationsEnabled = notif ?? true;
      _biometricQuickUnlock = biometric ?? false;
      _dashboardRefreshSec = (refreshSec ?? 20).clamp(10, 300);
      _mapType = (mapType == null || mapType.isEmpty) ? 'normal' : mapType;
      _darkModeEnabled = darkModeEnabled ?? false;

      // Structured server-driven cache (we store as array of {key,value})
      final raw = prefs.getString(_kCacheKey);
      if (raw != null) {
        _applyServerCacheJsonSafe(raw);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    } finally {
      notifyListeners();
      // background refresh if stale
      refreshFromServer();
    }
  }

  /// Actively refresh from server if cached is stale or force = true.
  Future<bool> refreshFromServer({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_kCacheTs) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (!force && (now - last) < _kTtlMs) return true; // not stale yet
      if (!force && (now - _lastFailureTsMs) < _kFailureBackoffMs) {
        return false; // recent failure, back off noisy retries
      }

      final token = await ApiConstants.getAccessToken();
      if (token == null || token.isEmpty) return false; // not logged in; skip

      final fallbackBase = ApiConstants.baseUrl;
      final candidates = <String>[];
      if (_apiUrl.isNotEmpty) candidates.add(_apiUrl);
      if (!candidates.contains(fallbackBase)) candidates.add(fallbackBase);

      http.Response? resp;
      String? selectedBase;
      Object? lastError;
      for (final base in candidates) {
        final uri = _endpoint(base, 'user-settings');
        try {
          final attempt = await http
              .get(
                uri,
                headers: {
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(const Duration(seconds: 8));

          if (attempt.statusCode >= 200 && attempt.statusCode < 300) {
            resp = attempt;
            selectedBase = base;
            break;
          }
          if (attempt.statusCode == 401 || attempt.statusCode == 403) {
            resp = attempt;
            selectedBase = base;
            break;
          }
          lastError = 'HTTP ${attempt.statusCode}';
        } catch (e) {
          lastError = e;
        }
      }

      if (resp == null) {
        _lastFailureTsMs = now;
        debugPrint('Settings refresh error: $lastError');
        return false;
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Shape can be:
        //   { success, message, data: [ {key,value}, ... ] }
        // or   [ {key,value}, ... ]
        List<dynamic>? items;
        try {
          final root = jsonDecode(resp.body);
          if (root is Map && root['data'] is List) {
            items = root['data'] as List;
          } else if (root is List) {
            items = root;
          }
        } catch (e) {
          debugPrint('Failed to parse server response: $e');
        }

        if (items != null) {
          _applyKeyValueList(items);
          if (selectedBase != null && selectedBase.isNotEmpty) {
            _apiUrl = selectedBase;
            await _saveToPrefs('apiUrl', _apiUrl);
          }
          // cache the normalized array for fast boot
          await prefs.setString(_kCacheKey, jsonEncode(items));
          await prefs.setInt(_kCacheTs, now);
          _lastFailureTsMs = 0;
          notifyListeners();
          return true;
        } else {
          debugPrint('Unexpected settings shape: ${resp.body}');
          _lastFailureTsMs = now;
          return false;
        }
      } else {
        debugPrint('Settings refresh failed: ${resp.statusCode} ${resp.body}');
        _lastFailureTsMs = now;
        return false;
      }
    } catch (e) {
      debugPrint('Settings refresh error: $e');
      _lastFailureTsMs = DateTime.now().millisecondsSinceEpoch;
      return false;
    }
  }

  /// Apply cached JSON (we store array of {key,value})
  void _applyServerCacheJsonSafe(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        _applyKeyValueList(decoded);
      } else if (decoded is Map && decoded['data'] is List) {
        _applyKeyValueList(decoded['data']);
      }
    } catch (e) {
      debugPrint('Failed to parse cached settings: $e');
    }
  }

  /// Applies a list of `{key, value}` to known settings.
  void _applyKeyValueList(List<dynamic> items) {
    for (final it in items) {
      if (it is! Map) continue;
      final key = it['key']?.toString();
      final value = it['value']?.toString();
      if (key == null || value == null) continue;
      _applyKnownSetting(key, value);
    }
    // After server-driven fields are updated, persist them for native consumers.
    _persistServerDrivenSettings();
  }

  /// Map server keys to local fields. Extend this as your API grows.
  void _applyKnownSetting(String key, String value) {
    switch (key) {
      case 'baseApi':
      case 'apiUrl':
        // Keep compile-time API override pinned in dev/test runs.
        if (_compileTimeApiBase.isEmpty && value.isNotEmpty) {
          _apiUrl = value;
        }
        break;
      case 'wsUrl':
        _wsUrl = value;
        break;
      case 'trackingIntervalMs':
        final n = int.tryParse(value);
        if (n != null && n > 0) _trackingIntervalMs = n;
        break;
      case 'minSupportedAppVersion':
        _minSupportedAppVersion = value;
        break;
      case 'defaultLocale':
      case 'locale':
        if (value == 'km' || value == 'en') _currentLocale = Locale(value);
        break;
      case 'notificationsEnabled':
        _notificationsEnabled = (value.toLowerCase() == 'true' || value == '1');
        break;
      case 'biometricQuickUnlock':
        _biometricQuickUnlock = (value.toLowerCase() == 'true' || value == '1');
        break;
      case 'dashboardRefreshSec':
        final sec = int.tryParse(value);
        if (sec != null && sec >= 10 && sec <= 300) {
          _dashboardRefreshSec = sec;
        }
        break;
      case 'mapType':
        if (const {'normal', 'satellite', 'terrain', 'hybrid'}.contains(value)) {
          _mapType = value;
        }
        break;
      case 'themeMode':
        _darkModeEnabled = value.toLowerCase() == 'dark';
        break;
      case 'mapTileUrlTemplate':
        if (value.isNotEmpty) _mapTileUrlTemplate = value;
        break;
      // ignore unknown keys
    }
  }

  Future<void> _persistServerDrivenSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_apiUrl.isNotEmpty) {
        await prefs.setString('apiUrl', _apiUrl);
      }
      if (_wsUrl != null && _wsUrl!.isNotEmpty) {
        await prefs.setString('wsUrl', _wsUrl!);
      }
      if (_trackingIntervalMs != null && _trackingIntervalMs! > 0) {
        final sec = (_trackingIntervalMs! / 1000).round();
        await prefs.setInt('locationIntervalSec', sec.clamp(5, 86400));
      }
      await prefs.setBool('biometricQuickUnlock', _biometricQuickUnlock);
      await prefs.setInt('dashboardRefreshSec', _dashboardRefreshSec);
      await prefs.setString('mapType', _mapType);
      await prefs.setBool('darkModeEnabled', _darkModeEnabled);
    } catch (e) {
      debugPrint('Failed to persist server-driven settings: $e');
    }
  }

  // =========================
  // Persistence helpers
  // =========================

  Future<void> _saveToPrefs(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Failed to save $key: $e');
    }
  }

  Future<void> _saveBoolToPrefs(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Failed to save $key: $e');
    }
  }

  Future<void> _saveIntToPrefs(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (e) {
      debugPrint('Failed to save $key: $e');
    }
  }

  // =========================
  // API sync for single key
  // =========================

  Future<void> _syncSettingToApi(String key, String value) async {
    try {
      final token = await ApiConstants.getAccessToken();
      if (token == null || token.isEmpty) return;

      final base = _apiUrl.isNotEmpty ? _apiUrl : ApiConstants.baseUrl;
      final response = await http.post(
        _endpoint(base, 'user-settings/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'key': key, 'value': value}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Sync failed [$key]: ${response.body}');
      }
    } catch (e) {
      debugPrint(' API sync error [$key]: $e');
    }
  }
}
