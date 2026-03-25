// ignore_for_file: deprecated_member_use, prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/local_storage.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Locale? _locale;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricEnabled = false;
  late LocalStorage _storage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = context.locale;
    _storage = Provider.of<LocalStorage>(context, listen: false);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final b = await _storage.getBool('biometric_enabled');
    if (b != null && mounted) setState(() => _biometricEnabled = b);
  }

  Future<void> _toggleBiometric() async {
    final messenger = ScaffoldMessenger.of(context);
    final canCheck = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    if (!canCheck) {
      messenger.showSnackBar(const SnackBar(content: Text('Biometric not available on this device')));
      return;
    }
    if (!_biometricEnabled) {
      bool didAuth = false;
      try {
        didAuth = await _localAuth.authenticate(localizedReason: 'Authenticate to enable biometric');
      } catch (_) {
        didAuth = false;
      }
      if (didAuth) {
        await _storage.saveBool('biometric_enabled', true);
        if (!mounted) return;
        setState(() => _biometricEnabled = true);
        messenger.showSnackBar(const SnackBar(content: Text('Biometric enabled')));
      }
    } else {
      await _storage.saveBool('biometric_enabled', false);
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      messenger.showSnackBar(const SnackBar(content: Text('Biometric disabled')));
    }
  }

  Future<void> _openRating() async {
    final messenger = ScaffoldMessenger.of(context);
    final Uri uri = Platform.isAndroid
        ? Uri.parse('https://play.google.com/store/search?q=SV-TMS&c=apps')
        : Uri.parse('https://apps.apple.com/search?term=SV-TMS');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        messenger.showSnackBar(const SnackBar(content: Text('Could not open store')));
      }
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not open store')));
    }
  }

  // locale updates handled by _showLanguagePicker to avoid using BuildContext across awaits

  Widget _buildCard({required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _tile({required Widget leading, required String title, String? subtitle, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ]
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withAlpha(153)),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final easy = EasyLocalization.of(context);
    final current = _locale?.languageCode ?? 'en';
    final languages = [const Locale('en'), const Locale('km')];
    final picked = await showModalBottomSheet<Locale>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((loc) {
            final code = loc.languageCode;
            final isSelected = code == current;
            final display = code == 'km' ? 'ភាសាខ្មែរ' : 'English';
            return ListTile(
              title: Text(display, style: TextStyle(fontSize: 18)),
              trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
              onTap: () => Navigator.pop(ctx, loc),
            );
          }).toList(),
        ),
      ),
    );
    if (picked != null) {
      // persist and apply immediately
      await _storage.saveString('locale', picked.languageCode);
      await easy?.setLocale(picked);
      if (!mounted) return;
      setState(() => _locale = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        title: Text('Setting', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: InkResponse(
            onTap: () => Navigator.pop(context),
            radius: 22,
            highlightShape: BoxShape.circle,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)]),
              child: Icon(Icons.arrow_back_ios_new, size: 18, color: theme.colorScheme.primary),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Top group
          _buildCard(
            children: [
              _tile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.translate, color: Colors.pink)),
                title: 'Language',
                subtitle: _locale?.languageCode == 'km' ? 'ភាសាខ្មែរ' : 'English',
                onTap: _showLanguagePicker,
              ),
              Divider(height: 1, color: theme.colorScheme.onSurface.withAlpha(15)),
              _tile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.info_outline, color: Colors.purple)),
                title: 'About Us',
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
              Divider(height: 1, color: theme.colorScheme.onSurface.withAlpha(15)),
              _tile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.reviews, color: Colors.deepOrange)),
                title: 'Rating Review',
                onTap: _openRating,
              ),
            ],
          ),

          // Security header
          const SizedBox(height: 12),
          Text('Security', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          // Security group
          _buildCard(
            children: [
              _tile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.fingerprint, color: Colors.pink)),
                title: 'Enable Biometric',
                subtitle: _biometricEnabled ? 'Enabled' : 'Disabled',
                onTap: _toggleBiometric,
              ),
              Divider(height: 1, color: theme.colorScheme.onSurface.withAlpha(15)),
              _tile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.vpn_key, color: Colors.green)),
                title: 'Change Password',
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final auth = context.read<AuthProvider>();
                  // Ensure token exists (try refresh if missing) before showing change password
                  String? token = await auth.getToken();
                  if (token == null) {
                    final refreshed = await auth.refreshAccessToken();
                    if (!refreshed) {
                      messenger.showSnackBar(const SnackBar(content: Text('Session expired, please log in again')));
                      await auth.logout();
                      if (!mounted) return;
                      navigator.pushNamedAndRemoveUntil('/login', (r) => false);
                      return;
                    }
                  }
                  navigator.pushNamed('/change-password');
                },
              ),
              Divider(height: 1, color: theme.colorScheme.onSurface.withAlpha(15)),
              _tile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lock, color: Colors.deepPurple)),
                title: 'Change Pin',
                onTap: () => Navigator.pushNamed(context, '/change-pin'),
              ),
              Divider(height: 1, color: theme.colorScheme.onSurface.withAlpha(15)),
              _tile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.lock_open, color: Colors.orange)),
                title: 'Forgot your pin code?',
                onTap: () => Navigator.pushNamed(context, '/forgot-pin'),
              ),
              Divider(height: 1, color: theme.colorScheme.onSurface.withAlpha(15)),
              _tile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.person_remove, color: Colors.red)),
                title: 'Permanently Delete Account',
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final auth = context.read<AuthProvider>();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm'),
                      content: const Text('Are you sure you want to permanently delete your account?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await auth.deleteAccount();
                      if (!mounted) return;
                      messenger.showSnackBar(const SnackBar(content: Text('Account deleted')));
                      navigator.pushNamedAndRemoveUntil('/login', (r) => false);
                    } catch (_) {
                      messenger.showSnackBar(const SnackBar(content: Text('Failed to delete account')));
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Logout button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final navigator = Navigator.of(context);
                await auth.logout();
                if (!mounted) return;
                navigator.pushNamedAndRemoveUntil('/login', (r) => false);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: theme.colorScheme.primary,
              ),
              child: Text('Log out', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
