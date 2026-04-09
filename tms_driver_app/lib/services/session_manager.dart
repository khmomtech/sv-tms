import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/app_bootstrap_provider.dart';
import 'package:tms_driver_app/main.dart';
import 'package:tms_driver_app/providers/sign_in_provider.dart';
import 'package:tms_driver_app/providers/user_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

/// Global session manager to handle forced logout (e.g. token revoked / invalid).
class SessionManager extends ChangeNotifier {
  SessionManager._internal();
  static final SessionManager instance = SessionManager._internal();

  bool _authInvalid = false;
  DateTime? _authInvalidAt;
  String? _reason;
  bool _logoutInFlight = false;

  bool get authInvalid => _authInvalid;
  DateTime? get authInvalidAt => _authInvalidAt;
  String? get reason => _reason;

  /// Mark auth as invalid once; triggers forced logout flow.
  void markAuthInvalid({String? reason}) {
    if (_authInvalid) return; // only trigger once until user re-auths
    _authInvalid = true;
    _authInvalidAt = DateTime.now();
    _reason = reason;
    debugPrint('[SessionManager] Auth invalid detected (reason=${reason ?? 'unknown'}). Forcing logout.');
    notifyListeners();
    _forceLogout();
  }

  Future<void> _forceLogout() async {
    if (_logoutInFlight) return;
    _logoutInFlight = true;
    final ctx = navigatorKey.currentState?.overlay?.context;
    if (ctx == null) {
      debugPrint('[SessionManager] No context available for logout navigation.');
      _logoutInFlight = false;
      return;
    }
    try {
      final signIn = Provider.of<SignInProvider>(ctx, listen: false);
      final userProvider = Provider.of<UserProvider>(ctx, listen: false);
      final bootstrapProvider =
          Provider.of<AppBootstrapProvider>(ctx, listen: false);
      await signIn.forceSignOut(
        userProvider: userProvider,
        bootstrapProvider: bootstrapProvider,
      );
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.signin,
        (_) => false,
      );
    } catch (e) {
      debugPrint('[SessionManager] Forced logout error: $e');
    } finally {
      _logoutInFlight = false;
    }
  }

  /// Reset after successful login.
  void reset() {
    if (!_authInvalid) return;
    _authInvalid = false;
    _reason = null;
    _authInvalidAt = null;
    notifyListeners();
  }
}
