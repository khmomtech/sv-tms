import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/auth_models.dart';
import '../services/local_storage.dart';

/// Auth service that handles login, logout, and token management
class AuthService with ChangeNotifier {
  final LocalStorage storage;
  final http.Client httpClient;
  bool _authenticated = false;
  UserInfo? _currentUser;

  bool get isAuthenticated => _authenticated;
  UserInfo? get currentUser => _currentUser;

  AuthService({required this.storage, http.Client? client})
      : httpClient = client ?? http.Client();

  /// Login with username and password
  Future<LoginResponse> login(String username, String password) async {
    try {
      final request = LoginRequest(
        username: username,
        password: password,
      );

      final response = await httpClient
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
            headers: {
              'Content-Type': ApiConstants.contentTypeJson,
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConstants.connectTimeout);

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(responseBody);

        // Save token and user info
        await storage.saveToken(loginResponse.token);
        if (loginResponse.refreshToken != null) {
          await storage.saveRefreshToken(loginResponse.refreshToken!);
        }
        await storage.saveUserInfo(loginResponse.user);

        _authenticated = true;
        _currentUser = loginResponse.user;
        notifyListeners();

        return loginResponse;
      } else {
        // Handle error response
        final errorMsg = responseBody['message'] as String? ??
            responseBody['error'] as String? ??
            'Login failed';
        final errorCode = responseBody['code'] as String? ?? 'LOGIN_FAILED';
        throw AuthException(errorCode, errorMsg);
      }
    } on http.ClientException catch (e) {
      throw AuthException('NETWORK_ERROR', 'Network error: ${e.message}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('UNKNOWN_ERROR', 'An unexpected error occurred: $e');
    }
  }

  /// Logout and clear stored credentials
  Future<void> logout() async {
    await storage.clearToken();
    await storage.clearRefreshToken();
    await storage.clearUserInfo();
    _authenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  /// Try to restore authentication from stored token
  Future<bool> tryRestore() async {
    try {
      final token = await storage.getToken();
      final userInfo = await storage.getUserInfo();

      if (token != null && userInfo != null) {
        _authenticated = true;
        _currentUser = userInfo;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error restoring auth: $e');
    }

    _authenticated = false;
    _currentUser = null;
    notifyListeners();
    return false;
  }

  /// Get current auth token
  Future<String?> getToken() async {
    return await storage.getToken();
  }

  /// Delete the currently authenticated account (if supported by backend)
  Future<void> deleteAccount() async {
    final token = await storage.getToken();
    if (token == null) {
      throw AuthException('UNAUTHENTICATED', 'User is not authenticated');
    }

    final response = await httpClient
        .delete(
          Uri.parse('${ApiConstants.baseUrl}/api/auth/delete-account'),
          headers: {
            'Content-Type': ApiConstants.contentTypeJson,
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(ApiConstants.receiveTimeout);

    if (response.statusCode == 200 || response.statusCode == 204) {
      // Complete local logout
      await logout();
      return;
    } else {
      try {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = map['message'] ?? map['error'] ?? 'Account deletion failed';
        throw AuthException('DELETE_FAILED', msg.toString());
      } catch (e) {
        throw AuthException('DELETE_FAILED', 'Account deletion failed');
      }
    }
  }

  /// Refresh access token using stored refresh token. Returns true if token refreshed.
  Future<bool> refreshAccessToken() async {
    final refresh = await storage.getRefreshToken();
    if (refresh == null) return false;

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshEndpoint}'),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          'Authorization': 'Bearer $refresh',
        },
      ).timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // backend may return either {"accessToken": "..."} or {"token": "..."}
        final access =
            body['accessToken'] as String? ?? body['token'] as String?;
        if (access != null) {
          await storage.saveToken(access);
          _authenticated = true;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('refresh token failed: $e');
    }
    return false;
  }

  /// Verify that the current access token maps to a valid user on the backend.
  /// Calls a lightweight authenticated endpoint and returns true when the token
  /// is valid. Attempts a single refresh+retry on 401.
  Future<bool> verifyToken() async {
    final token = await storage.getToken();
    if (token == null) {
      debugPrint('verifyToken: no token found in storage');
      return false;
    }

    Future<http.Response> doVerify(String bearer) {
      return httpClient.get(
        Uri.parse('${ApiConstants.baseUrl}/api/admin/user-permissions/me/effective'),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          'Authorization': 'Bearer $bearer',
        },
      ).timeout(ApiConstants.receiveTimeout);
    }

    try {
      http.Response resp = await doVerify(token);
      debugPrint('verifyToken: initial verify status=${resp.statusCode}');
      if (resp.statusCode == 200) return true;
      if (resp.statusCode == 401) {
        final refreshed = await refreshAccessToken();
        debugPrint('verifyToken: refresh attempted result=$refreshed');
        if (refreshed) {
          final newToken = await storage.getToken();
          if (newToken != null) {
            final retry = await doVerify(newToken);
            debugPrint('verifyToken: retry verify status=${retry.statusCode}');
            return retry.statusCode == 200;
          }
        }
      }
    } catch (e) {
      debugPrint('verifyToken error: $e');
    }
    return false;
  }

  /// Change password for currently authenticated user
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    // Ensure we have a token (try refresh if missing) before attempting password change
    String? token = await storage.getToken();
    if (token == null) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        throw AuthException('UNAUTHENTICATED', 'Session invalid or expired');
      }
      token = await storage.getToken();
    }

    final body = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
    Future<http.Response> doRequest(String bearer) {
      return httpClient
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.changePasswordEndpoint}'),
            headers: {
              'Content-Type': ApiConstants.contentTypeJson,
              'Authorization': 'Bearer $bearer',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.receiveTimeout);
    }

    // token should be present here
    http.Response response = await doRequest(token!);

    // If unauthorized, try refresh once and retry
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newToken = await storage.getToken();
        if (newToken != null) {
          response = await doRequest(newToken);
        }
      }
    }

    if (response.statusCode == 200) {
      return;
    }

    // Log for debugging (non-sensitive)
    try {
      debugPrint('changePassword failed: status=${response.statusCode} body=${response.body}');
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = map['message'] ?? map['error'] ?? 'Password change failed';
      throw AuthException('CHANGE_PASSWORD_FAILED', msg.toString());
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('CHANGE_PASSWORD_FAILED', 'Password change failed');
    }
  }

  /// Attempt to register a user. Note: backend requires ADMIN privileges so this may return 403.
  Future<void> register(String username, String email, String password,
      {List<String>? roles}) async {
    final payload = {
      'username': username,
      'email': email,
      'password': password,
      'roles': roles ?? []
    };

    final response = await httpClient
        .post(
          Uri.parse('${ApiConstants.baseUrl}/api/auth/register'),
          headers: {'Content-Type': ApiConstants.contentTypeJson},
          body: jsonEncode(payload),
        )
        .timeout(ApiConstants.receiveTimeout);

    if (response.statusCode == 200) return;
    if (response.statusCode == 403) {
      throw AuthException(
          'FORBIDDEN', 'Registration is restricted. Please contact admin.');
    }
    try {
      final map = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = map['message'] ?? map['error'] ?? 'Registration failed';
      throw AuthException('REGISTER_FAILED', msg.toString());
    } catch (e) {
      throw AuthException('REGISTER_FAILED', 'Registration failed');
    }
  }

  /// Request password reset — backend doesn't expose public endpoint; show guidance instead
  Future<void> requestPasswordReset(String email) async {
    // Try to call backend endpoint if it's implemented. If the backend doesn't
    // implement this endpoint (404/403/etc), fall back to a local no-op so the
    // UI can continue to show guidance to contact admin.
    try {
      final response = await httpClient
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.passwordResetEndpoint}'),
            headers: {'Content-Type': ApiConstants.contentTypeJson},
            body: jsonEncode({'email': email}),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      // If endpoint not implemented or forbidden, treat as handled locally
      if (response.statusCode == 404 ||
          response.statusCode == 403 ||
          response.statusCode == 501) {
        return;
      }
      // For other error codes, attempt to parse message and throw
      try {
        final map = jsonDecode(response.body) as Map<String, dynamic>;
        final msg = map['message'] ?? map['error'] ?? 'Password reset failed';
        throw AuthException('PASSWORD_RESET_FAILED', msg.toString());
      } catch (e) {
        throw AuthException('PASSWORD_RESET_FAILED', 'Password reset failed');
      }
    } catch (e) {
      // Network problems or timeouts - fall back to local guidance rather than
      // failing the UI hard.
      if (e is AuthException) rethrow;
      return;
    }
  }

  /// Get profile from stored user info
  UserInfo? getProfile() {
    return _currentUser;
  }

  /// Update profile locally (server-side profile update requires admin in this backend)
  Future<void> updateProfile({String? username, String? email}) async {
    // Server update is restricted (admin endpoints); update stored user locally
    if (_currentUser == null) {
      throw AuthException('UNAUTHENTICATED', 'Not logged in');
    }
    final updated = UserInfo(
      username: username ?? _currentUser!.username,
      email: email ?? _currentUser!.email,
      roles: _currentUser!.roles,
      permissions: _currentUser!.permissions,
    );
    _currentUser = updated;
    await storage.saveUserInfo(updated);
    notifyListeners();
  }
}
