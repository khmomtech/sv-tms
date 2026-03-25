import 'package:flutter/material.dart';
import '../../../core/compliance/gdpr_consent_service.dart';

/// Privacy Settings Screen
///
/// Allows users to:
/// - View current consent preferences
/// - Update individual consent settings
/// - Export personal data (GDPR Right to Data Portability)
/// - Delete account and data (GDPR Right to Erasure)
/// - View privacy policy and terms
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final GDPRConsentService _consentService = GDPRConsentService();

  Map<String, dynamic> _preferences = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    final prefs = await _consentService.getConsentPreferences();
    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(String type, bool value) async {
    await _consentService.updateConsentPreference(type, value);
    await _loadPreferences();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.toUpperCase()} consent updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _exportData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Personal Data'),
        content: const Text(
          'This will export all your personal data stored in the app. '
          'The data will be saved as a JSON file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final data = await _consentService.exportUserData();

      // TODO: Save to file or share
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported: ${data['preferences'].length} items'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account & Data'),
        content: const Text(
          'This will permanently delete all your data from the app. '
          'This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _consentService.deleteAllUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data deleted. Please restart the app.'),
            backgroundColor: Color(0xFF2563eb),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Consent Status
                ListTile(
                  leading: Icon(
                    _preferences['consentGiven'] == true
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: _preferences['consentGiven'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: const Text('Consent Status'),
                  subtitle: Text(
                    _preferences['consentGiven'] == true
                        ? 'Consent given on ${_preferences['consentTimestamp']}'
                        : 'No consent given',
                  ),
                  trailing: Text(
                    'v${_preferences['consentVersion']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const Divider(),

                // Consent Preferences
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Privacy Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                SwitchListTile(
                  value: _preferences['analytics'] ?? false,
                  onChanged: (v) => _updatePreference('analytics', v),
                  title: const Text('Analytics'),
                  subtitle: const Text('Help improve app performance'),
                  secondary: const Icon(Icons.analytics),
                ),

                SwitchListTile(
                  value: _preferences['marketing'] ?? false,
                  onChanged: (v) => _updatePreference('marketing', v),
                  title: const Text('Marketing'),
                  subtitle: const Text('Receive promotional offers'),
                  secondary: const Icon(Icons.mail),
                ),

                SwitchListTile(
                  value: _preferences['location'] ?? false,
                  onChanged: (v) => _updatePreference('location', v),
                  title: const Text('Location Services'),
                  subtitle: const Text('Enable real-time tracking'),
                  secondary: const Icon(Icons.location_on),
                ),

                SwitchListTile(
                  value: _preferences['dataProcessing'] ?? false,
                  onChanged: (v) => _updatePreference('dataProcessing', v),
                  title: const Text('Data Processing'),
                  subtitle: const Text('Business operations and billing'),
                  secondary: const Icon(Icons.storage),
                ),

                SwitchListTile(
                  value: _preferences['cookies'] ?? false,
                  onChanged: (v) => _updatePreference('cookies', v),
                  title: const Text('Cookies'),
                  subtitle: const Text('Local storage and preferences'),
                  secondary: const Icon(Icons.cookie),
                ),

                SwitchListTile(
                  value: _preferences['thirdParty'] ?? false,
                  onChanged: (v) => _updatePreference('thirdParty', v),
                  title: const Text('Third-Party Services'),
                  subtitle: const Text('Firebase, Maps, etc.'),
                  secondary: const Icon(Icons.share),
                ),

                const Divider(height: 32),

                // GDPR Rights
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Your Rights',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.download, color: Colors.blue),
                  title: const Text('Export My Data'),
                  subtitle: const Text('Download all your personal data'),
                  onTap: _exportData,
                ),

                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account'),
                  subtitle: const Text('Permanently delete all your data'),
                  onTap: _deleteAccount,
                ),

                const Divider(height: 32),

                // Legal Links
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Legal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.policy),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // TODO: Open privacy policy URL
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // TODO: Open terms URL
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
