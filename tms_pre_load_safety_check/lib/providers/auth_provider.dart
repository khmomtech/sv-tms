import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService);

  final AuthService _authService;

  bool initialized = false;
  bool loggedIn = false;
  bool loading = false;
  String? error;
  bool pinVerified = false;
  bool pinSet = false;
  String? username;
  String? userId;
  String? fullName;

  Future<void> init() async {
    if (initialized) return;
    loggedIn = await _authService.isLoggedIn();
    username = await _authService.getUsername();
    userId = await _authService.getUserId();
    fullName = await _authService.getFullName();
    pinSet = await _authService.isPinSet();
    pinVerified = !pinSet; // If no PIN set, consider unlocked
    initialized = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.login(username, password);
      loggedIn = true;
      this.username = await _authService.getUsername();
      userId = await _authService.getUserId();
      fullName = await _authService.getFullName();
      pinSet = await _authService.isPinSet();
      pinVerified = !pinSet;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    loggedIn = false;
    pinVerified = false;
    pinSet = false;
    notifyListeners();
  }

  AuthService get service => _authService;

  Future<void> unlockWithPin(String pin) async {
    final ok = await _authService.verifyPin(pin);
    if (!ok) {
      throw Exception('Invalid PIN');
    }
    pinVerified = true;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _authService.savePin(pin);
    pinSet = true;
    pinVerified = true;
    notifyListeners();
  }

  Future<void> clearPin() async {
    await _authService.clearPin();
    pinSet = false;
    pinVerified = true;
    notifyListeners();
  }
}
