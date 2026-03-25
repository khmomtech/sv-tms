/// Authentication models for login request and response

class LoginRequest {
  final String username;
  final String password;
  final String? deviceId;

  LoginRequest({
    required this.username,
    required this.password,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }
}

class LoginResponse {
  final String code;
  final String message;
  final String token;
  final String? refreshToken;
  final UserInfo user;

  LoginResponse({
    required this.code,
    required this.message,
    required this.token,
    this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String? ?? '';
    final message = json['message'] as String? ?? '';
    final token =
        (json['token'] as String?) ?? (json['accessToken'] as String?) ?? '';
    final refreshToken = json['refreshToken'] as String?;
    final userJson = json['user'] as Map<String, dynamic>?;
    final user = userJson != null
        ? UserInfo.fromJson(userJson)
        : UserInfo(username: '', email: '', roles: [], permissions: []);

    return LoginResponse(
      code: code,
      message: message,
      token: token,
      refreshToken: refreshToken,
      user: user,
    );
  }
}

class UserInfo {
  final String username;
  final String email;
  final List<String> roles;
  final List<String> permissions;
  final int? customerId; // Customer ID for CUSTOMER role users

  UserInfo({
    required this.username,
    required this.email,
    required this.roles,
    required this.permissions,
    this.customerId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    final username = json['username'] as String? ?? '';
    final email = json['email'] as String? ?? '';
    final rolesList = json['roles'] as List<dynamic>? ?? <dynamic>[];
    final permissionsList =
        json['permissions'] as List<dynamic>? ?? <dynamic>[];
    final roles = rolesList
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final permissions = permissionsList
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    int? customerId;
    if (json['customerId'] is int) {
      customerId = json['customerId'] as int;
    } else if (json['customerId'] != null) {
      customerId = int.tryParse(json['customerId'].toString());
    }

    return UserInfo(
      username: username,
      email: email,
      roles: roles,
      permissions: permissions,
      customerId: customerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'roles': roles,
      'permissions': permissions,
      if (customerId != null) 'customerId': customerId,
    };
  }
}

class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  @override
  String toString() => message;
}
