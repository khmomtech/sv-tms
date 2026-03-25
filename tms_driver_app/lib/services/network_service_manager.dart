// lib/services/network_service_manager.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';

/// 🌐 Network Service Manager for enhanced connectivity monitoring and management
class NetworkServiceManager {
  static final NetworkServiceManager _instance = NetworkServiceManager._internal();
  factory NetworkServiceManager() => _instance;
  NetworkServiceManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  bool _isServerReachable = true;
  Timer? _periodicHealthCheck;

  final List<Function(bool isConnected)> _connectivityListeners = [];
  final List<Function(bool isReachable)> _serverHealthListeners = [];

  bool get isConnected => _isConnected;
  bool get isServerReachable => _isServerReachable;
  bool get isHealthy => _isConnected && _isServerReachable;

  /// Initialize network monitoring
  Future<void> initialize() async {
    debugPrint('🌐 Initializing Network Service Manager');

    // Check initial connectivity
    await _checkInitialConnectivity();

    // Start monitoring connectivity changes
    _startConnectivityMonitoring();

    // Start periodic server health checks
    _startPeriodicHealthChecks();

    debugPrint('Network Service Manager initialized');
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicHealthCheck?.cancel();
    _connectivityListeners.clear();
    _serverHealthListeners.clear();
  }

  /// Add connectivity change listener
  void addConnectivityListener(Function(bool isConnected) listener) {
    _connectivityListeners.add(listener);
  }

  /// Remove connectivity change listener
  void removeConnectivityListener(Function(bool isConnected) listener) {
    _connectivityListeners.remove(listener);
  }

  /// Add server health change listener
  void addServerHealthListener(Function(bool isReachable) listener) {
    _serverHealthListeners.add(listener);
  }

  /// Remove server health change listener
  void removeServerHealthListener(Function(bool isReachable) listener) {
    _serverHealthListeners.remove(listener);
  }

  /// Manually trigger connectivity check
  Future<bool> checkConnectivity() async {
    return await _checkNetworkConnectivity();
  }

  /// Manually trigger server health check
  Future<bool> checkServerHealth() async {
    return await _checkServerReachability();
  }

  /// Get network quality assessment
  Future<NetworkQuality> assessNetworkQuality() async {
    final stopwatch = Stopwatch()..start();

    try {
      final host = Uri.parse(ApiConstants.baseUrl).host;
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 2));

      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      if (result.isEmpty) {
        return NetworkQuality.poor;
      }

      if (latency < 200) {
        return NetworkQuality.excellent;
      } else if (latency < 500) {
        return NetworkQuality.good;
      } else if (latency < 1000) {
        return NetworkQuality.fair;
      } else {
        return NetworkQuality.poor;
      }
    } catch (e) {
      return NetworkQuality.poor;
    }
  }

  /// Get recommended timeout based on network quality
  Future<Duration> getRecommendedTimeout() async {
    final quality = await assessNetworkQuality();
    switch (quality) {
      case NetworkQuality.excellent:
        return const Duration(seconds: 15);
      case NetworkQuality.good:
        return const Duration(seconds: 20);
      case NetworkQuality.fair:
        return const Duration(seconds: 30);
      case NetworkQuality.poor:
        return const Duration(seconds: 45);
    }
  }

  // Private methods

  Future<void> _checkInitialConnectivity() async {
    _isConnected = await _checkNetworkConnectivity();
    _isServerReachable = await _checkServerReachability();

    debugPrint('🔍 Initial connectivity check:');
    debugPrint('  Network: ${_isConnected ? "Connected" : "Disconnected"}');
    debugPrint('  Server: ${_isServerReachable ? "Reachable" : "Unreachable"}');
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        debugPrint('🌐 Connectivity changed: $results');

        final wasConnected = _isConnected;
        _isConnected = await _checkNetworkConnectivity();

        if (wasConnected != _isConnected) {
          debugPrint('Network status changed: ${_isConnected ? "Connected" : "Disconnected"}');
          _notifyConnectivityListeners();

          // If we're now connected, check server health
          if (_isConnected) {
            _checkServerReachability().then((reachable) {
              if (_isServerReachable != reachable) {
                _isServerReachable = reachable;
                _notifyServerHealthListeners();
              }
            });
          } else {
            _isServerReachable = false;
            _notifyServerHealthListeners();
          }
        }
      },
    );
  }

  void _startPeriodicHealthChecks() {
    _periodicHealthCheck = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _performHealthCheck(),
    );
  }

  Future<void> _performHealthCheck() async {
    if (!_isConnected) return;

    final wasReachable = _isServerReachable;
    _isServerReachable = await _checkServerReachability();

    if (wasReachable != _isServerReachable) {
      debugPrint('🏥 Server health changed: ${_isServerReachable ? "Reachable" : "Unreachable"}');
      _notifyServerHealthListeners();
    }
  }

  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      return false;
    }
  }

  Future<bool> _checkServerReachability() async {
    try {
      final host = Uri.parse(ApiConstants.baseUrl).host;
      final result = await InternetAddress.lookup(host)
          .timeout(const Duration(seconds: 5));

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Server reachability check failed: $e');
      return false;
    }
  }

  void _notifyConnectivityListeners() {
    for (final listener in _connectivityListeners) {
      try {
        listener(_isConnected);
      } catch (e) {
        debugPrint('Error notifying connectivity listener: $e');
      }
    }
  }

  void _notifyServerHealthListeners() {
    for (final listener in _serverHealthListeners) {
      try {
        listener(_isServerReachable);
      } catch (e) {
        debugPrint('Error notifying server health listener: $e');
      }
    }
  }
}

/// Network quality assessment levels
enum NetworkQuality {
  excellent,
  good,
  fair,
  poor;

  String get description {
    switch (this) {
      case NetworkQuality.excellent:
        return 'Excellent';
      case NetworkQuality.good:
        return 'Good';
      case NetworkQuality.fair:
        return 'Fair';
      case NetworkQuality.poor:
        return 'Poor';
    }
  }
}

/// Network status information
class NetworkStatus {
  final bool isConnected;
  final bool isServerReachable;
  final NetworkQuality quality;
  final DateTime timestamp;

  const NetworkStatus({
    required this.isConnected,
    required this.isServerReachable,
    required this.quality,
    required this.timestamp,
  });

  bool get isHealthy => isConnected && isServerReachable;

  @override
  String toString() =>
      'NetworkStatus(connected: $isConnected, reachable: $isServerReachable, quality: ${quality.description})';
}