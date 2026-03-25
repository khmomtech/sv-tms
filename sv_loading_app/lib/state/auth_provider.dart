import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../core/api/api_error.dart';
import '../core/auth/token_store.dart';
import '../core/auth/jwt_utils.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient api;
  final TokenStore tokenStore = TokenStore();
  static const _rolesCacheKey = 'auth_roles_cache';

  bool isLoading = false;
  String? error;
  Set<String> roles = {};

  AuthProvider(this.api) {
    _restoreRoles();
  }

  Future<void> _restoreRoles() async {
    final token = await tokenStore.getToken();
    if (token == null || token.isEmpty) {
      roles = {};
      notifyListeners();
      return;
    }
    final payload = decodeJwtPayload(token);
    roles = extractRoleClaims(payload);
    if (roles.isEmpty) {
      roles = await _restoreCachedRoles();
    }
    notifyListeners();
  }

  bool hasAnyRole(List<String> expectedRoles) {
    if (roles.isEmpty) {
      return false;
    }
    if (roles.contains('ROLE_ADMIN') ||
        roles.contains('ROLE_SUPERADMIN') ||
        roles.contains('ROLE_all_functions')) {
      return true;
    }
    return expectedRoles.any((role) {
      if (roles.contains(role)) return true;
      if (role.startsWith('ROLE_')) return roles.contains(role.substring(5));
      return roles.contains('ROLE_$role');
    });
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.dio.post(Endpoints.login, data: {
        'username': username,
        'password': password,
      });
      final body = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      final token = data['token'] ?? body['auth_token'] ?? body['token'];
      if (token == null) throw Exception('No token in response');
      final tokenString = token.toString();
      await tokenStore.saveToken(tokenString);
      roles = extractRoleClaims(decodeJwtPayload(tokenString));
      if (roles.isEmpty) {
        roles = _extractRolesFromLoginResponse(body, data);
      }
      await _cacheRoles(roles);
      return true;
    } on DioException catch (e) {
      final parsed = parseApiError(e);
      if (parsed.isNetworkError) {
        error =
            'Cannot connect to API host. Check API_BASE_URL/backend URL. Current: ${api.dio.options.baseUrl}';
      } else {
        error = parsed.message;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    await tokenStore.clear();
    await _cacheRoles(const {});
    roles = {};
    notifyListeners();
  }

  Set<String> _extractRolesFromLoginResponse(
    Map<String, dynamic> body,
    Map<String, dynamic> data,
  ) {
    final fromDataUser = _toRoleSet((data['user'] as Map?)?['roles']);
    if (fromDataUser.isNotEmpty) return fromDataUser;

    final fromData = _toRoleSet(data['roles']);
    if (fromData.isNotEmpty) return fromData;

    final fromBody = _toRoleSet(body['roles']);
    if (fromBody.isNotEmpty) return fromBody;

    final fromDataUserAuthorities =
        _toRoleSet((data['user'] as Map?)?['authorities']);
    if (fromDataUserAuthorities.isNotEmpty) return fromDataUserAuthorities;

    return {};
  }

  Set<String> _toRoleSet(dynamic raw) {
    final output = <String>{};
    if (raw is List) {
      for (final item in raw) {
        final normalized = _normalizeRole(item?.toString());
        if (normalized != null) output.add(normalized);
      }
      return output;
    }
    if (raw is String) {
      for (final item in raw.split(RegExp(r'[,\s]+'))) {
        final normalized = _normalizeRole(item);
        if (normalized != null) output.add(normalized);
      }
    }
    return output;
  }

  String? _normalizeRole(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('ROLE_')) return trimmed;
    return 'ROLE_$trimmed';
  }

  Future<void> _cacheRoles(Set<String> values) async {
    final sp = await SharedPreferences.getInstance();
    if (values.isEmpty) {
      await sp.remove(_rolesCacheKey);
      return;
    }
    await sp.setStringList(_rolesCacheKey, values.toList()..sort());
  }

  Future<Set<String>> _restoreCachedRoles() async {
    final sp = await SharedPreferences.getInstance();
    return (sp.getStringList(_rolesCacheKey) ?? const []).toSet();
  }
}
