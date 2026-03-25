import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/pending_queue_service.dart';
import '../services/safety_service.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _clearing = false;
  bool _syncing = false;
  String? _message;
  bool _pinSubmitting = false;
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _clearOffline() async {
    setState(() {
      _clearing = true;
      _message = null;
    });
    final pending = Provider.of<PendingQueueService>(context, listen: false);
    await pending.clearAll();
    if (mounted) {
      setState(() {
        _clearing = false;
        _message = 'offlineCacheCleared'.tr();
      });
    }
  }

  Future<void> _syncOffline() async {
    setState(() {
      _syncing = true;
      _message = null;
    });
    final pending = Provider.of<PendingQueueService>(context, listen: false);
    final safety = Provider.of<SafetyService>(context, listen: false);
    final synced = await pending.retryPending(safety);
    if (mounted) {
      setState(() {
        _syncing = false;
        _message = synced > 0
            ? 'syncedPending'.tr(namedArgs: {'count': synced.toString()})
            : 'noPending'.tr();
      });
    }
  }

  Future<void> _setLocale(Locale locale) async {
    await context.setLocale(locale);
    setState(() {
      _message = 'languageSet'.tr(namedArgs: {'lang': locale.languageCode});
    });
  }

  Future<void> _openPinDialog() async {
    final auth = context.read<AuthProvider>();
    _pinController.clear();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('pinManageTitle'.tr(),
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'pinCode'.tr(),
                  counterText: '',
                  helperText: 'pinHelper'.tr(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _pinSubmitting
                    ? null
                    : () async {
                        if (_pinController.text.length < 4) {
                          setState(() => _message = 'pinTooShort'.tr());
                          return;
                        }
                        setState(() => _pinSubmitting = true);
                        await auth.setPin(_pinController.text);
                        if (mounted) {
                          setState(() {
                            _pinSubmitting = false;
                            _message = 'pinSaved'.tr();
                          });
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                child: Text(_pinSubmitting ? 'saving'.tr() : 'pinSave'.tr()),
              ),
              TextButton(
                onPressed: _pinSubmitting
                    ? null
                    : () async {
                        setState(() => _pinSubmitting = true);
                        await auth.clearPin();
                        if (mounted) {
                          setState(() {
                            _pinSubmitting = false;
                            _message = 'pinRemoved'.tr();
                          });
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                child: Text('pinRemove'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        context.watch<PendingQueueService>().getPending().length;
    return Scaffold(
      appBar: AppBar(
        title: Text('settingsTitle'.tr()),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('apiEndpoint'.tr()),
            subtitle: Text(apiBaseUrl),
            leading: const Icon(Icons.cloud_done_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            subtitle: Text(context.locale.languageCode),
            trailing: Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _setLocale(const Locale('en')),
                  child: const Text('EN'),
                ),
                OutlinedButton(
                  onPressed: () => _setLocale(const Locale('km')),
                  child: const Text('KM'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.offline_pin),
            title: Text('offlineQueue'.tr()),
            subtitle: Text('pendingOffline'
                .tr(namedArgs: {'count': pendingCount.toString()})),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _syncing ? null : _syncOffline,
                    icon: _syncing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: Text(_syncing ? 'syncing'.tr() : 'syncNow'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearing ? null : _clearOffline,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(_clearing ? 'clearing'.tr() : 'clear'.tr()),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('about'.tr()),
            subtitle: Text('aboutSubtitle'.tr()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: Text('pinManageTitle'.tr()),
            subtitle: Text('pinManageSubtitle'.tr()),
            trailing: TextButton(
              onPressed: _pinSubmitting ? null : _openPinDialog,
              child: Text('manage'.tr()),
            ),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _message!,
                style: const TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}
