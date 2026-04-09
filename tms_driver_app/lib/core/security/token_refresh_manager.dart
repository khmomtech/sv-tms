// 📁 lib/core/security/token_refresh_manager.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

/// Enhanced JWT Token Refresh Manager
/// 
/// Provides:
/// - Automatic token refresh before expiry
/// - Retry logic with exponential backoff
/// - Token expiry detection and prevention
/// - Secure refresh token handling
class TokenRefreshManager {
  static final TokenRefreshManager _instance = TokenRefreshManager._internal();
  factory TokenRefreshManager() => _instance;
  TokenRefreshManager._internal();

  Timer? _refreshTimer;
  bool _isRefreshing = false;
  int _refreshRetryCount = 0;
  
  static const int _maxRetries = 3;
  static const int _refreshLeadTimeSeconds = 300; // 5 minutes before expiry
  static const Duration _minRefreshInterval = Duration(minutes: 1);
  
  DateTime? _lastRefreshAttempt;
  final _refreshCompleter = Completer<bool>();

  /// Start automatic token refresh monitoring
  Future<void> startAutoRefresh() async {
    debugPrint('[TokenRefresh] Starting automatic token refresh monitoring');
    
    // Cancel existing timer
    _refreshTimer?.cancel();
    
    // Schedule next refresh check
    await _scheduleNextRefresh();
  }

  /// Stop automatic token refresh
  void stopAutoRefresh() {
    debugPrint('⏹️ [TokenRefresh] Stopping automatic token refresh monitoring');
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Schedule next token refresh based on expiry time
  Future<void> _scheduleNextRefresh() async {
    try {
      final token = await ApiConstants.getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint('[TokenRefresh] No access token found, skipping refresh schedule');
        return;
      }

      // Get token expiry time
      final expiryTime = await _getTokenExpiryTime(token);
      if (expiryTime == null) {
        debugPrint('[TokenRefresh] Could not parse token expiry, scheduling default refresh');
        _scheduleRefreshTimer(const Duration(minutes: 10));
        return;
      }

      // Calculate time until refresh (5 minutes before expiry)
      final now = DateTime.now();
      final refreshTime = expiryTime.subtract(Duration(seconds: _refreshLeadTimeSeconds));
      final timeUntilRefresh = refreshTime.difference(now);

      if (timeUntilRefresh.isNegative) {
        debugPrint('[TokenRefresh] Token already expired or expiring soon, refreshing now');
        await refreshToken();
      } else {
        debugPrint('[TokenRefresh] Scheduling refresh in ${timeUntilRefresh.inMinutes} minutes');
        _scheduleRefreshTimer(timeUntilRefresh);
      }
    } catch (e) {
      debugPrint('[TokenRefresh] Error scheduling refresh: $e');
      // Fallback to default schedule
      _scheduleRefreshTimer(const Duration(minutes: 10));
    }
  }

  /// Schedule refresh timer
  void _scheduleRefreshTimer(Duration delay) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () async {
      await refreshToken();
      await _scheduleNextRefresh(); // Schedule next refresh after this one
    });
  }

  /// Parse token expiry time from JWT
  Future<DateTime?> _getTokenExpiryTime(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode JWT payload
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;

      // Get exp claim (seconds since epoch)
      final exp = json['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      
      return null;
    } catch (e) {
      debugPrint('[TokenRefresh] Error parsing token expiry: $e');
      return null;
    }
  }

  /// Manually refresh access token with retry logic
  Future<bool> refreshToken() async {
    // Prevent rapid refresh attempts
    if (_lastRefreshAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastRefreshAttempt!);
      if (timeSinceLastAttempt < _minRefreshInterval) {
        debugPrint('[TokenRefresh] Skipping refresh, too soon since last attempt');
        return false;
      }
    }

    // Prevent concurrent refresh attempts
    if (_isRefreshing) {
      debugPrint('[TokenRefresh] Refresh already in progress, waiting...');
      return await _refreshCompleter.future;
    }

    _isRefreshing = true;
    _lastRefreshAttempt = DateTime.now();

    try {
      debugPrint('[TokenRefresh] Attempting token refresh (attempt ${_refreshRetryCount + 1}/$_maxRetries)');

      final newToken = await ApiConstants.refreshAccessToken();
      
      if (newToken != null && newToken.isNotEmpty) {
        debugPrint('[TokenRefresh] Token refreshed successfully');
        _refreshRetryCount = 0;
        _isRefreshing = false;
        
        if (!_refreshCompleter.isCompleted) {
          _refreshCompleter.complete(true);
        }
        
        return true;
      } else {
        debugPrint('[TokenRefresh] Token refresh failed (empty response)');
        return await _retryRefresh();
      }
    } catch (e) {
      debugPrint('[TokenRefresh] Token refresh error: $e');
      return await _retryRefresh();
    }
  }

  /// Retry token refresh with exponential backoff
  Future<bool> _retryRefresh() async {
    _refreshRetryCount++;

    if (_refreshRetryCount >= _maxRetries) {
      debugPrint('[TokenRefresh] Max retry attempts reached, giving up');
      _refreshRetryCount = 0;
      _isRefreshing = false;
      
      if (!_refreshCompleter.isCompleted) {
        _refreshCompleter.complete(false);
      }
      
      return false;
    }

    // Exponential backoff: 2^retryCount seconds
    final backoffDelay = Duration(seconds: 1 << _refreshRetryCount);
    debugPrint('⏳ [TokenRefresh] Retrying in ${backoffDelay.inSeconds} seconds...');

    await Future.delayed(backoffDelay);
    return await refreshToken();
  }

  /// Check if token is about to expire
  Future<bool> isTokenExpiringSoon({int leadTimeSeconds = 300}) async {
    try {
      return await ApiConstants.isTokenExpired(leewaySeconds: leadTimeSeconds);
    } catch (e) {
      debugPrint('[TokenRefresh] Error checking token expiry: $e');
      return false;
    }
  }

  /// Force immediate token refresh
  Future<bool> forceRefresh() async {
    _lastRefreshAttempt = null; // Reset cooldown
    return await refreshToken();
  }
}
