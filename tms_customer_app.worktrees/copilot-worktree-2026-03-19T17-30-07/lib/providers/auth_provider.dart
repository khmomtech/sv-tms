import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/auth_models.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;

  bool get isAuthenticated => authService.isAuthenticated;
  UserInfo? get currentUser => authService.currentUser;

  AuthProvider({required this.authService}) {
    // Listen to auth service changes
    authService.addListener(_onAuthServiceChanged);
  }

  void _onAuthServiceChanged() {
    notifyListeners();
  }

  /// Login with username (email) and password
  Future<LoginResponse> login(String username, String password) async {
    return await authService.login(username, password);
  }

  /// Logout and clear stored credentials
  Future<void> logout() async {
    await authService.logout();
  }

  /// Register a new user (may be restricted on server)
  Future<void> register(String username, String email, String password,
      {List<String>? roles}) async {
    return await authService.register(username, email, password, roles: roles);
  }

  /// Change password for current user
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    return await authService.changePassword(currentPassword, newPassword);
  }

  /// Request password reset (UI-only guidance when backend endpoint missing)
  Future<void> requestPasswordReset(String email) async {
    return await authService.requestPasswordReset(email);
  }

  /// Get profile
  UserInfo? getProfile() {
    return authService.getProfile();
  }

  /// Update profile locally (server update requires admin)
  Future<void> updateProfile({String? username, String? email}) async {
    return await authService.updateProfile(username: username, email: email);
  }

  /// Try to restore authentication from stored token
  Future<bool> tryRestore() async {
    return await authService.tryRestore();
  }

  /// Get current auth token
  Future<String?> getToken() async {
    return await authService.getToken();
  }

  /// Attempt to refresh the access token using stored refresh token
  Future<bool> refreshAccessToken() async {
    return await authService.refreshAccessToken();
  }

  /// Verify current access token maps to a valid user on the backend
  Future<bool> verifyToken() async {
    return await authService.verifyToken();
  }

  /// Delete the currently authenticated account (if supported by backend)
  Future<void> deleteAccount() async {
    return await authService.deleteAccount();
  }

  @override
  void dispose() {
    authService.removeListener(_onAuthServiceChanged);
    super.dispose();
  }
}
