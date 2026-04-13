import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/themes/custom_colors.dart';

import '../../providers/sign_in_provider.dart';
import '../../providers/app_bootstrap_provider.dart';
import '../../routes/app_routes.dart';
import '../core/device_approval_pending_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  static const String reviewerUsername =
      String.fromEnvironment('REVIEWER_USERNAME', defaultValue: 'drivertest');
  static const String reviewerPassword =
      String.fromEnvironment('REVIEWER_PASSWORD', defaultValue: '123456');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _deviceId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _loadDeviceId();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadRememberedCredentials() async {
    final signInProvider = Provider.of<SignInProvider>(context, listen: false);
    final creds = await signInProvider.loadSavedCredentials();
    if (!mounted) return;
    setState(() {
      _usernameController.text = creds['username'] ?? '';
      _passwordController.text = creds['password'] ?? '';
      _rememberMe = (creds['username']?.isNotEmpty == true &&
          creds['password']?.isNotEmpty == true);
    });
  }

  Future<void> _loadDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      _deviceId = iosInfo.identifierForVendor;
    }
  }

  void _fillReviewerCredentials() {
    setState(() {
      _usernameController.text = reviewerUsername;
      _passwordController.text = reviewerPassword;
      _rememberMe = false;
    });
  }

  Future<void> _handleReviewerLogin() async {
    _fillReviewerCredentials();
    await _handleSignIn();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    final signInProvider = Provider.of<SignInProvider>(context, listen: false);

    final success = await signInProvider.signIn(
      context,
      _usernameController.text.trim(),
      _passwordController.text.trim(),
      deviceId: _deviceId,
      rememberMe: _rememberMe,
    );

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue,
          content: Text(signInProvider.errorMessage),
        ),
      );
    }
  }

  Future<void> _showApiUrlSettings() async {
    await ApiConstants.ensureInitialized();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final controller = TextEditingController(text: ApiConstants.baseUrl);
    bool saving = false;
    String? savedUrl;

    await showDialog<String?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.dns_outlined),
                SizedBox(width: 8),
                Text('Server URL'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Base URL',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'http://host:8080/api',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!mounted) return;
                        setDialogState(() => saving = true);
                        await ApiConstants.clearBaseUrlOverride();
                        await ApiConstants.ensureInitialized();
                        if (!mounted) return;
                        controller.text = ApiConstants.baseUrl;
                        setDialogState(() => saving = false);
                      },
                child: const Text('Reset'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final url = controller.text.trim();
                        if (url.isEmpty) return;
                        if (!mounted) return;
                        setDialogState(() => saving = true);
                        await ApiConstants.setBaseUrlOverride(url);
                        savedUrl = url;
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(url);
                      },
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    if (!mounted || savedUrl == null) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Server URL updated: $savedUrl'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signInProvider = Provider.of<SignInProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [CustomColors.primary, CustomColors.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white54),
                  tooltip: 'Server settings',
                  onPressed: _showApiUrlSettings,
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/logo.png', height: 100),
                            const SizedBox(height: 20),
                            Text(
                              'signin.welcome'.tr(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'signin.subtitle'.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            _buildSignInForm(signInProvider),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(SignInProvider signInProvider) {
    final bootstrapProvider =
        Provider.of<AppBootstrapProvider>(context, listen: true);
    final showReviewLogin = bootstrapProvider.policy<bool>(
      'auth.review_login_button_enabled',
      false,
    );

    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (showReviewLogin) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _handleReviewerLogin,
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text(
                  'App Review Login',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Review build target: ${ApiConstants.baseUrl}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _usernameController,
            decoration: _buildInputDecoration(
              label: 'signin.username'.tr(),
              icon: Icons.person_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'signin.error_username_required'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _buildInputDecoration(
              label: 'signin.password'.tr(),
              icon: Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'signin.error_password_required'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildRememberMe(),
          const SizedBox(height: 24),
          if (signInProvider.isLoading)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          else
            _buildSignInButton(signInProvider),
          const SizedBox(height: 16),
          _buildPublicClarificationAndRegister(),
          const SizedBox(height: 8),
          if (signInProvider.showRequestApproval)
            _buildDeviceApprovalSection(signInProvider),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
    );
  }

  Widget _buildRememberMe() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) => setState(() => _rememberMe = value ?? false),
          checkColor: CustomColors.primary,
          activeColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
        ),
        Text(
          'signin.remember_me'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSignInButton(SignInProvider signInProvider) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: CustomColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onPressed: signInProvider.isLoading ? null : _handleSignIn,
        child: Text(
          'signin.title'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Public clarification text and register button required for App Store review
  Widget _buildPublicClarificationAndRegister() {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.register);
            },
            child: Text('signin.create_account'.tr(),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceApprovalSection(SignInProvider signInProvider) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              signInProvider.requestApprovalMessage ??
                  'signin.error_device_not_approved'.tr(),
              style: const TextStyle(
                  color: CustomColors.primary, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await signInProvider.requestDeviceApproval(
                  _usernameController.text.trim(),
                  _passwordController.text.trim(),
                );
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeviceApprovalPendingScreen(),
                  ),
                );
              },
              child: Text('signin.request_approval'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationPermissionGate extends StatelessWidget {
  final Future<void> Function() onContinue;
  const LocationPermissionGate({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('permission.location_title'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on,
                size: 72, color: CustomColors.primary),
            const SizedBox(height: 12),
            Text(
              'permission.location_reason'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'permission.location_request'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await onContinue();
                },
                child: Text('permission.allow_location'.tr()),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await openAppSettings();
              },
              child: Text('permission.open_settings'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
