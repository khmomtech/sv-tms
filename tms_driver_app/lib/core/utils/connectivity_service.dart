// 📁 lib/core/utils/connectivity_service.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'logger.dart';

/// Service to monitor network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  List<ConnectivityResult> _lastResult = [];

  /// Stream of connectivity status (true = connected, false = disconnected)
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _lastResult = result;
      _isConnected = _hasConnection(result);
      
      // Listen for connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
        onError: (error) {
          Logger.error('Connectivity stream error: $error', tag: 'ConnectivityService');
        },
      );

      Logger.info('Connectivity service initialized. Status: ${_isConnected ? "Connected" : "Disconnected"}');
    } catch (e) {
      Logger.error('Failed to initialize connectivity service: $e');
      _isConnected = true; // Assume connected if we can't check
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> result) {
    _lastResult = result;
    final wasConnected = _isConnected;
    _isConnected = _hasConnection(result);

    if (wasConnected != _isConnected) {
      Logger.info('Connectivity changed: ${_isConnected ? "Connected" : "Disconnected"}');
      _connectionStatusController.add(_isConnected);
    }
  }

  bool _hasConnection(List<ConnectivityResult> result) {
    // Consider connected if any of these are true
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet) ||
        result.contains(ConnectivityResult.vpn);
  }

  /// Get detailed connectivity info
  String getConnectionType() {
    if (_lastResult.isEmpty || _lastResult.contains(ConnectivityResult.none)) {
      return 'None';
    }
    
    final types = _lastResult.map((r) {
      switch (r) {
        case ConnectivityResult.mobile:
          return 'Mobile';
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.other:
          return 'Other';
        case ConnectivityResult.none:
          return 'None';
      }
    }).toList();

    return types.join(', ');
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
