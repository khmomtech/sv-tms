import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;

  // Back-compat identifiers
  String? _userId; // may hold driverId or username depending on caller
  String? _username; // display name / login

  // Extended profile from login payload
  String? _displayName;
  String? _email;
  String? _driverId; // canonical driver id as string
  String? _zone; // e.g., PHNOM_PENH
  String? _vehicleType; // e.g., TRUCK
  String? _status; // e.g., ONLINE

  List<String> _roles = [];

  // ---- Getters ----
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  String? get userId => _userId;
  String? get username => _username;

  String? get displayName => _displayName;
  String? get email => _email;
  String? get driverId => _driverId;
  String? get zone => _zone;
  String? get vehicleType => _vehicleType;
  String? get status => _status;

  List<String> get roles => List.unmodifiable(_roles);

  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.isNotEmpty && _userId != null;

  // ---- Keys ----
  static const _kAccessToken = 'accessToken';
  static const _kRefreshToken = 'refreshToken';

  static const _kUserId = 'userId';
  static const _kUsername = 'username';
  static const _kDisplayName = 'displayName';
  static const _kEmail = 'email';
  static const _kDriverId = 'driverId';
  static const _kZone = 'driverZone';
  static const _kVehicle = 'vehicleType';
  static const _kStatus = 'driverStatus';

  static const _kRoles = 'roles';

  // ---- Public API ----

  /// Handles user login and saves user data persistently
  Future<void> login(
    String userId,
    String username,
    String accessToken,
    List<String> roles, {
    String? displayName,
    String? email,
    String? driverId,
    String? zone,
    String? vehicleType,
    String? status,
    String? refreshToken,
  }) async {
    _userId = userId;
    _username = username;
    _displayName = _normalizeDisplayName(displayName) ?? username;
    _email = email;
    _driverId = driverId;
    _zone = zone;
    _vehicleType = vehicleType;
    _status = status;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _roles = roles.isNotEmpty ? roles : ['ROLE_USER'];

    await _saveToPreferences();
    notifyListeners();
  }

  /// Convenience: set all fields directly from the login response payload
  /// Example payload shape:
  /// {
  ///   token, refreshToken,
  ///   user: { username, email, roles[], driverId, zone, vehicleType, status }
  /// }
  Future<void> loginFromPayload({
    required String accessToken,
    String? refreshToken,
    required Map<String, dynamic> user,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    // Canonical fields
    _username = user['username']?.toString();
    _displayName = _normalizeDisplayName(
      user['displayName']?.toString() ??
          user['name']?.toString() ??
          _joinNameParts(user['firstName'], user['lastName']),
    ) ??
        _username;
    _email = user['email']?.toString();
    _driverId = user['driverId']?.toString();
    _zone = user['zone']?.toString();
    _vehicleType = user['vehicleType']?.toString();
    _status = user['status']?.toString();
    _roles = (user['roles'] as List? ?? []).map((e) => e.toString()).toList();

    // Back-compat userId: prefer driverId if present, else username
    _userId = _driverId ?? _username;

    await _saveToPreferences();
    notifyListeners();
  }

  /// Logs out and clears stored user data (only related keys, not entire prefs)
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;

    _userId = null;
    _username = null;

    _displayName = null;
    _email = null;
    _driverId = null;
    _zone = null;
    _vehicleType = null;
    _status = null;

    _roles = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);

    await prefs.remove(_kUserId);
    await prefs.remove(_kUsername);
    await prefs.remove(_kDisplayName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kDriverId);
    await prefs.remove(_kZone);
    await prefs.remove(_kVehicle);
    await prefs.remove(_kStatus);

    await prefs.remove(_kRoles);

    notifyListeners();
  }

  /// Loads user data from local storage when the app starts
  Future<void> loadUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _accessToken = prefs.getString(_kAccessToken);
    _refreshToken = prefs.getString(_kRefreshToken);

    _userId = prefs.getString(_kUserId);
    _username = prefs.getString(_kUsername);

    _displayName = prefs.getString(_kDisplayName);
    _email = prefs.getString(_kEmail);
    _driverId = prefs.getString(_kDriverId);
    _zone = prefs.getString(_kZone);
    _vehicleType = prefs.getString(_kVehicle);
    _status = prefs.getString(_kStatus);

    // Preferred: stored as List<String>
    _roles = prefs.getStringList(_kRoles) ?? [];

    // Fallback: old data stored as single string
    if (_roles.isEmpty) {
      final rolesString = prefs.getString(_kRoles);
      if (rolesString != null && rolesString.isNotEmpty) {
        _roles = rolesString.split(',').map((e) => e.trim()).toList();
      }
    }

    notifyListeners();
  }

  /// Check if the user has a specific role
  bool hasRole(String role) => _roles.contains(role);

  // ---- Internal ----
  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      await prefs.setString(_kAccessToken, _accessToken!);
    }
    if (_refreshToken != null && _refreshToken!.isNotEmpty) {
      await prefs.setString(_kRefreshToken, _refreshToken!);
    }

    if (_userId != null && _userId!.isNotEmpty) {
      await prefs.setString(_kUserId, _userId!);
    }
    if (_username != null && _username!.isNotEmpty) {
      await prefs.setString(_kUsername, _username!);
    }
    if (_displayName != null && _displayName!.isNotEmpty) {
      await prefs.setString(_kDisplayName, _displayName!);
    }

    if (_email != null && _email!.isNotEmpty) {
      await prefs.setString(_kEmail, _email!);
    }
    if (_driverId != null && _driverId!.isNotEmpty) {
      await prefs.setString(_kDriverId, _driverId!);
    }
    if (_zone != null && _zone!.isNotEmpty) {
      await prefs.setString(_kZone, _zone!);
    }
    if (_vehicleType != null && _vehicleType!.isNotEmpty) {
      await prefs.setString(_kVehicle, _vehicleType!);
    }
    if (_status != null && _status!.isNotEmpty) {
      await prefs.setString(_kStatus, _status!);
    }

    if (_roles.isNotEmpty) {
      await prefs.setStringList(_kRoles, _roles);
    }
  }

  String? _normalizeDisplayName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _joinNameParts(dynamic firstName, dynamic lastName) {
    final first = firstName?.toString().trim() ?? '';
    final last = lastName?.toString().trim() ?? '';
    final fullName = '$first $last'.trim();
    return fullName.isEmpty ? null : fullName;
  }
}
