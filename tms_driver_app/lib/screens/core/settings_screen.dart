import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/accessibility/haptic_helper.dart';
import 'package:tms_driver_app/core/constants/app_constants.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/providers/settings_provider.dart';
import 'package:tms_driver_app/providers/theme_provider.dart';
import 'package:tms_driver_app/providers/user_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings.title')),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          Semantics(
            label: tr('common.refresh'),
            hint: 'Double tap to refresh settings',
            button: true,
            child: IconButton(
              tooltip: tr('common.refresh'),
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await HapticHelper.refresh();
                final ok = await settingsProvider.refreshFromServer(force: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? tr('common.refreshed') : tr('error.data_load_failed'),
                      ),
                    ),
                  );
                }
              },
            ),
          )
        ],
      ),
      body: ListView(
        children: [
          _buildUpdateBanner(context, settingsProvider),
          const SizedBox(height: 16),
          _buildSectionHeader(tr('settings.account_section')),
          Semantics(
            label: '${tr('settings.account_info')} button',
            hint: 'Double tap to view account information',
            button: true,
            child: _buildSettingItem(
              icon: Icons.person,
              title: tr('settings.account_info'),
              onTap: () {
                HapticHelper.navigation();
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
          ),
          Semantics(
            label: '${tr('settings.change_password')} button',
            hint: 'Double tap to change your password',
            button: true,
            child: _buildSettingItem(
              icon: Icons.lock,
              title: tr('settings.change_password'),
              onTap: () {
                HapticHelper.navigation();
                Navigator.pushNamed(context, AppRoutes.changePassword);
              },
            ),
          ),
          const Divider(),
          _buildSectionHeader(tr('settings.app_section')),

          // Language selector
          _buildSettingItem(
            icon: Icons.language,
            title: tr('settings.language'),
            trailing: DropdownButton<Locale>(
              value: settingsProvider.currentLocale,
              items: const [
                DropdownMenuItem(
                  value: Locale('km'),
                  child: Text('ភាសាខ្មែរ'),
                ),
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text('English'),
                ),
              ],
              onChanged: (locale) async {
                if (locale != null) {
                  await settingsProvider.setLocale(locale);
                  if (context.mounted) await context.setLocale(locale);
                }
              },
            ),
            onTap: () {},
          ),

          // Notifications toggle
          Semantics(
            label: '${tr('settings.notifications')} toggle',
            hint: settingsProvider.notificationsEnabled 
              ? 'Notifications enabled. Double tap to disable' 
              : 'Notifications disabled. Double tap to enable',
            toggled: settingsProvider.notificationsEnabled,
            child: _buildSettingItem(
              icon: Icons.notifications,
              title: tr('settings.notifications'),
              trailing: Switch(
                value: settingsProvider.notificationsEnabled,
                onChanged: (val) {
                  HapticHelper.toggle();
                  settingsProvider.toggleNotifications(val);
                },
              ),
              onTap: () {
                HapticHelper.toggle();
                settingsProvider.toggleNotifications(
                    !settingsProvider.notificationsEnabled);
              },
            ),
          ),

          // Dark mode toggle
          Semantics(
            label: '${tr('settings.dark_mode')} toggle',
            hint: themeProvider.isDarkTheme 
              ? 'Dark mode enabled. Double tap to switch to light mode' 
              : 'Light mode enabled. Double tap to switch to dark mode',
            toggled: themeProvider.isDarkTheme,
            child: _buildSettingItem(
              icon: Icons.dark_mode,
              title: tr('settings.dark_mode'),
              trailing: Switch(
                value: themeProvider.isDarkTheme,
                onChanged: (val) {
                  HapticHelper.toggle();
                  themeProvider.toggleTheme(val);
                  settingsProvider.setThemeDarkMode(val);
                },
              ),
              onTap: () {
                HapticHelper.toggle();
                final next = !themeProvider.isDarkTheme;
                themeProvider.toggleTheme(next);
                settingsProvider.setThemeDarkMode(next);
              },
            ),
          ),

          _buildSettingItem(
            icon: Icons.timer_outlined,
            title: 'Auto Refresh Interval',
            trailing: DropdownButton<int>(
              value: settingsProvider.dashboardRefreshSec,
              items: const [10, 20, 30, 60, 120]
                  .map((sec) => DropdownMenuItem<int>(
                        value: sec,
                        child: Text('${sec}s'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                settingsProvider.setDashboardRefreshSec(value);
              },
            ),
            onTap: () {},
          ),

          _buildSettingItem(
            icon: Icons.map_outlined,
            title: 'Map Type',
            trailing: DropdownButton<String>(
              value: settingsProvider.mapType,
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'satellite', child: Text('Satellite')),
                DropdownMenuItem(value: 'terrain', child: Text('Terrain')),
                DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
              ],
              onChanged: (value) {
                if (value == null) return;
                settingsProvider.setMapType(value);
              },
            ),
            onTap: () {},
          ),

          _buildSettingItem(
            icon: Icons.fingerprint,
            title: 'Biometric Quick Unlock',
            trailing: Switch(
              value: settingsProvider.biometricQuickUnlock,
              onChanged: (value) {
                HapticHelper.toggle();
                settingsProvider.setBiometricQuickUnlock(value);
              },
            ),
            onTap: () {
              HapticHelper.navigation();
              Navigator.pushNamed(context, AppRoutes.biometricSettings);
            },
          ),

          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Settings',
            onTap: () {
              HapticHelper.navigation();
              Navigator.pushNamed(context, AppRoutes.privacySettings);
            },
          ),

          // API base URL editor + server-driven display
          _buildSettingItem(
            icon: Icons.link,
            title: tr('settings.api_base'),
            trailing: const Icon(Icons.edit),
            onTap: () => _editApiUrl(context, settingsProvider),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kvRow('API', settingsProvider.apiUrl),
                if (settingsProvider.wsUrl != null)
                  _kvRow('WS', settingsProvider.wsUrl!),
                if (settingsProvider.trackingIntervalMs != null)
                  _kvRow('Tracking Interval',
                      '${settingsProvider.trackingIntervalMs} ms'),
              ],
            ),
          ),

          _buildSettingItem(
            icon: Icons.info_outline,
            title: '${tr('about.title')} • ${AppConstants.appVersion}',
            onTap: () => Navigator.pushNamed(context, AppRoutes.about),
          ),

          const Divider(),

          // Logout
          Semantics(
            label: '${tr('settings.logout')} button',
            hint: 'Double tap to log out of your account',
            button: true,
            child: _buildSettingItem(
              icon: Icons.logout,
              title: tr('settings.logout'),
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: () async {
                HapticHelper.buttonPress();
                if (!context.mounted) return;
                final userProvider = context.read<UserProvider>();
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(tr('settings.logout')),
                    content: Text(tr('settings.logout_confirm')),
                    actions: [
                      TextButton(
                        onPressed: () {
                          HapticHelper.dismiss();
                          Navigator.pop(ctx);
                        },
                        child: Text(tr('common.cancel')),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          HapticHelper.authentication();
                          Navigator.pop(ctx);
                          await userProvider.logout();
                          await ApiConstants.clearTokens();
                          await ApiConstants.clearUser();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.signin,
                            (_) => false,
                          );
                        },
                        child: Text(tr('settings.logout')),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildUpdateBanner(BuildContext context, SettingsProvider settingsProvider) {
    if (!settingsProvider.isUpdateRequired) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.orange.shade800,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'A new version of the app is required. Please update to continue using all features.',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade800,
            ),
            onPressed: () async {
              final url =
                  Uri.parse('http://localhost:4200/settings/driver-app/version');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Could not open update page.')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  static Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$k: $v',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Future<void> _editApiUrl(BuildContext context, SettingsProvider settings) async {
    final controller = TextEditingController(text: settings.apiUrl);
    final formKey = GlobalKey<FormState>();

    String? validator(String? value) {
      final txt = value?.trim() ?? '';
      final uri = Uri.tryParse(txt);
      final valid = uri != null && uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
      if (!valid) return tr('errors.invalid_url');
      return null;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(tr('settings.edit_api')),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: tr('settings.api_base'),
                hintText: 'https://api.example.com',
              ),
              validator: validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('common.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(tr('common.save')),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      final newUrl = controller.text.trim();
      await settings.updateApiUrl(newUrl);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('settings.api_updated'))),
        );
      }
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color iconColor = Colors.black,
    Color titleColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}
