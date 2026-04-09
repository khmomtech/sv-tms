// 📁 lib/features/settings/screens/biometric_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:tms_driver_app/core/security/biometric_auth_service.dart';

class BiometricSettingsScreen extends StatefulWidget {
  const BiometricSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BiometricSettingsScreen> createState() => _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  
  bool _isDeviceSupported = false;
  bool _isBiometricEnabled = false;
  bool _isLoading = true;
  List<BiometricType> _availableBiometrics = [];
  String _biometricTypeName = '';

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    setState(() => _isLoading = true);

    try {
      final isSupported = await _biometricService.isDeviceSupported();
      final isEnabled = await _biometricService.isBiometricEnabled();
      final availableBiometrics = await _biometricService.getAvailableBiometrics();
      final typeName = await _biometricService.getBiometricTypeName();

      if (mounted) {
        setState(() {
          _isDeviceSupported = isSupported;
          _isBiometricEnabled = isEnabled;
          _availableBiometrics = availableBiometrics;
          _biometricTypeName = typeName;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[BiometricSettings] Error checking status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      // Authenticate before enabling
      final authenticated = await _biometricService.authenticate(
        reason: 'Verify your identity to enable biometric authentication',
      );

      if (!authenticated) {
        _showSnackBar('Authentication failed. Biometric login not enabled.');
        return;
      }

      // Enable biometric
      await _biometricService.enableBiometric();
      _showSnackBar('$_biometricTypeName authentication enabled successfully!');
    } else {
      // Disable biometric
      await _biometricService.disableBiometric();
      _showSnackBar('$_biometricTypeName authentication disabled.');
    }

    // Refresh status
    await _checkBiometricStatus();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Authentication'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!_isDeviceSupported) {
      return _buildUnsupportedView();
    }

    if (_availableBiometrics.isEmpty) {
      return _buildNoBiometricsView();
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildBiometricCard(),
        const SizedBox(height: 24),
        _buildSecurityInfo(),
        const SizedBox(height: 24),
        _buildAvailableBiometrics(),
      ],
    );
  }

  Widget _buildBiometricCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getBiometricIcon(),
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _biometricTypeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isBiometricEnabled
                            ? 'Enabled - Quick and secure login'
                            : 'Disabled - Use password to login',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isBiometricEnabled,
                  onChanged: _toggleBiometric,
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'Security Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.check_circle_outline,
              'Your biometric data stays on your device',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.lock_outline,
              'We never store your fingerprint or face data',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.shield_outlined,
              'Biometric authentication adds an extra layer of security',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableBiometrics() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Biometric Methods',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._availableBiometrics.map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      _getIconForBiometricType(type),
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getNameForBiometricType(type),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phonelink_lock_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Biometric Authentication Not Supported',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your device does not support biometric authentication.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBiometricsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No Biometrics Enrolled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please set up fingerprint or face recognition in your device settings first.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Open device settings (platform-specific)
                _showSnackBar('Please open your device Settings app');
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return Icons.remove_red_eye;
    }
    return Icons.lock;
  }

  IconData _getIconForBiometricType(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.remove_red_eye;
      case BiometricType.strong:
        return Icons.security;
      case BiometricType.weak:
        return Icons.shield;
    }
  }

  String _getNameForBiometricType(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }
}
