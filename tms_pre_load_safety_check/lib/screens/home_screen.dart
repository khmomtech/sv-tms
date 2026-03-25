import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/pending_queue_service.dart';
import '../services/safety_service.dart';
import '../services/stats_service.dart';
import '../widgets/primary_button.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _syncing = false;

  @override
  Widget build(BuildContext context) {
    final pendingQueue = context.watch<PendingQueueService>();
    final pendingCount = pendingQueue.getPending().length;

    return Scaffold(
      drawer: _buildDrawer(context, pendingCount),
      appBar: AppBar(
        title: Text('homeTitle'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'logout'.tr(),
            onPressed: () =>
                Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _heroCard(pendingCount),
            const SizedBox(height: 12),
            _safetySummary(pendingCount),
            const SizedBox(height: 12),
            _quickActions(context),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, int pendingCount) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'homeTitle'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'pendingOffline'
                        .tr(namedArgs: {'count': pendingCount.toString()}),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text('drawerHome'.tr()),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text('drawerScan'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text('drawerHistory'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text('drawerSettings'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('logout'.tr()),
              onTap: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard(int pendingCount) {
    final username = context.read<AuthProvider>().username ?? '';
    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              username.isNotEmpty
                  ? 'helloUser'.tr(namedArgs: {'user': username})
                  : 'homeHeroTitle'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'homeHeroSubtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'pendingOffline'
                      .tr(namedArgs: {'count': pendingCount.toString()}),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.orange.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _safetySummary(int pendingCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'safetySummaryToday'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statTile(
                            title: 'pendingLabel'.tr(),
                            value: '$pendingCount',
                            icon: Icons.cloud_off,
                            color: Colors.orange.shade100,
                            onTap: _syncing ? null : _syncPending,
                            actionLabel: _syncing ? 'syncing'.tr() : 'syncNow'.tr(),
                          ),
                        ),
                        if (!isNarrow) const SizedBox(width: 8),
                        if (!isNarrow)
                          Expanded(
                            child: _statTile(
                              title: 'scansToday'.tr(),
                              value: '${context.watch<StatsService>().today()['scanned']}',
                              icon: Icons.qr_code_2,
                              color: Colors.blue.shade50,
                            ),
                          ),
                      ],
                    ),
                    if (isNarrow) const SizedBox(height: 8),
                    if (isNarrow)
                      Row(
                        children: [
                          Expanded(
                            child: _statTile(
                              title: 'scansToday'.tr(),
                              value: '${context.watch<StatsService>().today()['scanned']}',
                              icon: Icons.qr_code_2,
                              color: Colors.blue.shade50,
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statTile(
                            title: 'safeCount'.tr(),
                            value: '${context.watch<StatsService>().today()['pass']}',
                            icon: Icons.check_circle_outline,
                            color: Colors.green.shade50,
                          ),
                        ),
                        if (!isNarrow) const SizedBox(width: 8),
                        if (!isNarrow)
                          Expanded(
                            child: _statTile(
                              title: 'unsafeCount'.tr(),
                              value: '${context.watch<StatsService>().today()['fail']}',
                              icon: Icons.error_outline,
                              color: Colors.red.shade50,
                            ),
                          ),
                      ],
                    ),
                    if (isNarrow) const SizedBox(height: 8),
                    if (isNarrow)
                      Row(
                        children: [
                          Expanded(
                            child: _statTile(
                              title: 'unsafeCount'.tr(),
                              value: '${context.watch<StatsService>().today()['fail']}',
                              icon: Icons.error_outline,
                              color: Colors.red.shade50,
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.black54),
                const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (actionLabel != null && onTap != null) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: onTap,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quickActions'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'scanId'.tr(),
              icon: Icons.qr_code_scanner,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncPending() async {
    setState(() {
      _syncing = true;
    });
    final pendingQueue = Provider.of<PendingQueueService>(context, listen: false);
    final safetyService = Provider.of<SafetyService>(context, listen: false);
    await pendingQueue.retryPending(safetyService);
    if (mounted) {
      setState(() {
        _syncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('retrySuccess'.tr())),
      );
    }
  }

}
