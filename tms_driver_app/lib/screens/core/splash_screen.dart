import 'dart:async';
import 'package:flutter/material.dart';

import 'package:tms_driver_app/core/constants/app_constants.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/core/security/biometric_auth_service.dart';
// GDPR consent removed: app will no longer require an explicit consent screen at startup

// ⬇️ New service + thin UI checker
import 'package:tms_driver_app/services/version_service.dart';
import 'package:tms_driver_app/widgets/version_checker.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  // Instantiate once (or inject via your DI)
  late final VersionService _versionService =
      VersionService(apiBaseUrl: ApiConstants.baseUrl);
  
  final BiometricAuthService _biometricService = BiometricAuthService();
  // GDPRConsentService removed from startup flow

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutBack,
    );
    _animationController.forward();

    // Non-blocking navigation + background version check handled by VersionChecker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(_checkLoginStatusAndNavigate);
    });
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    try {
      await Future.delayed(
        Duration(milliseconds: AppConstants.splashDelayMs),
      );

      // GDPR consent check removed: continue to login/dashboard flow directly

      // Use the proper authentication check from ApiConstants
      final isLoggedIn = await ApiConstants.isLoggedIn();
      debugPrint('[Splash] isLoggedIn result: $isLoggedIn');
      
      final accessToken = await ApiConstants.getAccessToken(logMiss: false);
      debugPrint('[Splash] accessToken present: ${accessToken != null && accessToken.isNotEmpty}');

      if (!mounted) return;
      
      // Check biometric authentication if user is logged in
      if (isLoggedIn) {
        final biometricAuthenticated = await _authenticateWithBiometrics();
        if (!biometricAuthenticated) {
          // Biometric auth failed, redirect to login
          debugPrint('[Splash] Biometric auth failed, redirecting to login');
          Navigator.pushReplacementNamed(context, '/signin');
          return;
        }
      }
      
      final route = isLoggedIn ? '/dashboard' : '/signin';
      debugPrint('[Splash] Navigating to: $route');
      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      debugPrint('[Splash] Error checking login status: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }
  
  /// Authenticate with biometrics if enabled
  Future<bool> _authenticateWithBiometrics() async {
    try {
      final isBiometricEnabled = await _biometricService.isBiometricEnabled();
      
      if (!isBiometricEnabled) {
        debugPrint('[Splash] Biometric auth not enabled, skipping');
        return true; // Allow login without biometrics
      }
      
      final isDeviceSupported = await _biometricService.isDeviceSupported();
      if (!isDeviceSupported) {
        debugPrint('[Splash] Device does not support biometrics, skipping');
        return true; // Allow login without biometrics
      }
      
      debugPrint('[Splash] Authenticating with biometrics...');
      return await _biometricService.authenticateForAppLaunch();
    } catch (e) {
      debugPrint('[Splash] Biometric auth error: $e');
      return true; // Fail open - allow login on error
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌈 Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0050AC), Color(0xFF9354B9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔆 Animated logo & loader
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 110,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Smart Truck Driver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),

          // 🧠 Background version check (thin UI)
          // - checkOnResume: true → re-check when app returns to foreground
          // - showBannerForOptional: false → use dialog for optional updates
          //   (set true if you prefer a small banner instead)
          Positioned.fill(
            child: VersionChecker(
              service: _versionService,
              delay: const Duration(seconds: 2),
              checkOnResume: true,
              showBannerForOptional: false,
            ),
          ),
        ],
      ),
    );
  }
}
