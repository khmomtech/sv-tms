import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../state/auth_provider.dart';
import '../../state/connectivity_provider.dart';
import '../../state/g_management_context_provider.dart';
import '../../state/loading_provider.dart';
import '../../state/trip_provider.dart';
import '../../widgets/app_scaffold.dart';

import '../g_management/dispatch_monitoring_screen.dart';
import '../g_management/loading_management_screen.dart';
import '../g_management/pre_entry_safety_management_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _menuTile(
    BuildContext context,
    String labelKey,
    String subtitleKey,
    IconData icon,
    Widget screen, {
    bool enabled = true,
    String? disabledReasonKey,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled
          ? () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => screen))
          : null,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EAF3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xFFEAF2FF)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: enabled
                        ? const Color(0xFF0B63CE)
                        : const Color(0xFF9CA3AF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelKey.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? const Color(0xFF111827)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? subtitleKey.tr()
                          : '${'insufficient_permissions'.tr()} (${disabledReasonKey ?? '-'})',
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();
    final loading = context.watch<LoadingProvider>();
    final trip = context.watch<TripProvider>().currentTrip;
    final gContext = context.watch<GManagementContextProvider>();
    const canMonitor = true;
    const canSafety = true;
    const canLoading = true;

    return AppScaffold(
      titleKey: 'home',
      actions: [
        IconButton(
          tooltip: conn.isOnline ? 'online'.tr() : 'offline'.tr(),
          onPressed: () {},
          icon: Icon(conn.isOnline ? Icons.wifi : Icons.wifi_off),
        ),
        IconButton(
          tooltip: 'sync_now'.tr(),
          onPressed: conn.isOnline && !loading.isLoading
              ? () async {
                  await loading.syncOffline();
                  if (!context.mounted) return;
                  final result = loading.syncResult;
                  if (result == null) return;
                  final text = '${'sync_summary'.tr()}: '
                      '${result.succeeded}/${result.processed}, '
                      '${'failed'.tr()}: ${result.failed}'
                      '${result.firstError == null ? '' : ' (${result.firstError})'}';
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(text)));
                }
              : null,
          icon: const Icon(Icons.sync),
        ),
        IconButton(
          tooltip: 'logout'.tr(),
          onPressed: () async {
            await context.read<AuthProvider>().logout();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (r) => false,
            );
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 22),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B63CE), Color(0xFF2A86F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: conn.isOnline
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      conn.isOnline ? 'online'.tr() : 'offline'.tr(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'current_dispatch'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (gContext.activeDispatchId ?? trip?.dispatchId)?.toString() ??
                      '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 30,
                    letterSpacing: 0.8,
                  ),
                ),
                if (loading.lastMessage == 'offline') ...[
                  const SizedBox(height: 8),
                  Text(
                    'changes_saved_offline'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ]
              ],
            ),
          ),
          _sectionTitle('g_management'.tr()),
          _menuTile(
            context,
            'menu_dispatch_monitoring',
            'menu_dispatch_monitoring_subtitle',
            Icons.monitor,
            const DispatchMonitoringScreen(),
            enabled: canMonitor,
            disabledReasonKey: 'ROLE_DISPATCH_MONITOR',
          ),
          const SizedBox(height: 8),
          _menuTile(
            context,
            'pre_entry_safety_management',
            'menu_pre_entry_subtitle',
            Icons.verified_user,
            const PreEntrySafetyManagementScreen(),
            enabled: canSafety,
            disabledReasonKey: 'ROLE_SAFETY',
          ),
          const SizedBox(height: 8),
          _menuTile(
            context,
            'loading_management',
            'menu_loading_subtitle',
            Icons.local_shipping,
            const LoadingManagementScreen(),
            enabled: canLoading,
            disabledReasonKey: 'ROLE_LOADING',
          ),
        ],
      ),
    );
  }
}
