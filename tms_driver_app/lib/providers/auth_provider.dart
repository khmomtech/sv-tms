// lib/features/auth/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/network/api_response.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';

class AuthProvider with ChangeNotifier {
  final DioClient _client = DioClient();

  bool _isChanging = false;
  String? _lastMessage;
  String? _lastError;

  bool get isChanging => _isChanging;
  String? get lastMessage => _lastMessage;
  String? get lastError => _lastError;

  /// Change password API call (auto-refresh handled by DioClient interceptor)
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    BuildContext? context,
    bool usePatch = true, // flip to false if your backend wants POST instead
  }) async {
    if (_isChanging) return false; // avoid double submits
    _isChanging = true;
    _lastMessage = null;
    _lastError = null;
    notifyListeners();

    try {
      final payload = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      final path = ApiConstants.endpoint('/auth/change-password').path;

      // Parse the body as Map<String, dynamic> so we can read "message"
      final ApiResponse<Map<String, dynamic>> response = usePatch
          ? await _client.patch<Map<String, dynamic>>(
              path,
              data: payload,
              parser: (raw) =>
                  (raw as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
            )
          : await _client.post<Map<String, dynamic>>(
              path,
              data: payload,
              parser: (raw) =>
                  (raw as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
            );

      final serverMsg = response.data?['message'] as String?;
      final msg = serverMsg ?? response.message ?? 'ប្តូរពាក្យសម្ងាត់បានជោគជ័យ';

      if (response.success) {
        _lastMessage = msg;
        debugPrint('Password changed successfully.');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
        return true;
      } else {
        final failMsg =
            response.message ?? serverMsg ?? 'បញ្ហាក្នុងការប្តូរពាក្យសម្ងាត់';
        _lastError = failMsg;
        debugPrint('Password change failed: $failMsg');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failMsg)));
        }
        return false;
      }
    } catch (e) {
      _lastError = 'Exception: $e';
      debugPrint('Exception during password change: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('មានបញ្ហាក្នុងការប្តូរពាក្យសម្ងាត់')),
        );
      }
      return false;
    } finally {
      _isChanging = false;
      notifyListeners();
    }
  }
}
