import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkConnectivityWarning extends StatefulWidget {
  const NetworkConnectivityWarning({super.key}); //  use super.key

  @override
  State<NetworkConnectivityWarning> createState() =>
      _NetworkConnectivityWarningState();
}

class _NetworkConnectivityWarningState
    extends State<NetworkConnectivityWarning> {
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription; //  Fix type

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _isConnected =
            results.isNotEmpty && results.first != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: const [
          Icon(Icons.wifi_off, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No Internet Connection',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
