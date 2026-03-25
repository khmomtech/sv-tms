import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/app_bootstrap_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/providers/user_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

class DriverDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  const DriverDrawer({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final bootstrap = context.watch<AppBootstrapProvider>();
    final driver = context.watch<DriverProvider>();
    final user = context.watch<UserProvider>();

    final showTrips =
        bootstrap.isScreenVisible('trips.visible', fallback: true);
    final showProfile =
        bootstrap.isScreenVisible('profile.visible', fallback: true);
    final showSettings =
        bootstrap.isScreenVisible('settings.visible', fallback: true);
    final showDriverId =
        bootstrap.isScreenVisible('driver_id.visible', fallback: true);
    final showNotifications =
        bootstrap.isFeatureEnabled('notifications.enabled', fallback: true);
    final showIncidentReport =
        bootstrap.isFeatureEnabled('incident_report.enabled', fallback: true);
    final showSafetyCheck =
        bootstrap.isFeatureEnabled('safety_check.enabled', fallback: true);
    final showLocationTracking =
        bootstrap.isFeatureEnabled('location_tracking.enabled', fallback: true);

    final profile = driver.driverProfile;
    final driverName = (profile?['name'] ??
            profile?['displayName'] ??
            profile?['username'] ??
            user.displayName ??
            user.username ??
            tr('drawer.menu_title'))
        .toString();
    final driverPicUrl = profile?['profilePictureUrl']?.toString();
    final driverId = driver.driverId ?? user.driverId ?? user.userId ?? '';

    final itemIds = bootstrap.policyStringList(
      'nav.drawer.items',
      fallback: const <String>[
        'home',
        'my_vehicle',
        'my_id_card',
        'notifications',
        'profile',
        'report_issue_list',
        'incident_report',
        'incident_report_list',
        'safety_history',
        'maintenance',
        'trip_report',
        'daily_summary',
        'settings',
        'help',
      ],
    );

    final menuItems = <Widget>[
      for (final itemId in itemIds)
        ..._buildMenuItem(
          context: context,
          itemId: itemId,
          showTrips: showTrips,
          showProfile: showProfile,
          showSettings: showSettings,
          showDriverId: showDriverId,
          showNotifications: showNotifications,
          showIncidentReport: showIncidentReport,
          showSafetyCheck: showSafetyCheck,
          showLocationTracking: showLocationTracking,
          driverId: driverId,
        ),
    ];

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context, driverName, driverPicUrl, driverId),
          ...menuItems,
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(tr('menu.logout')),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    String name,
    String? picUrl,
    String driverId,
  ) {
    final theme = Theme.of(context);
    final ImageProvider? image =
        (picUrl != null && picUrl.isNotEmpty) ? NetworkImage(picUrl) : null;

    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(color: theme.primaryColor),
      accountName: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      accountEmail: driverId.isNotEmpty
          ? Text('ID: $driverId', style: const TextStyle(fontSize: 12))
          : null,
      currentAccountPicture: CircleAvatar(
        backgroundImage: image,
        backgroundColor: theme.primaryColorLight,
        child: image == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 22, color: Colors.white),
              )
            : null,
      ),
    );
  }

  List<Widget> _buildMenuItem({
    required BuildContext context,
    required String itemId,
    required bool showTrips,
    required bool showProfile,
    required bool showSettings,
    required bool showDriverId,
    required bool showNotifications,
    required bool showIncidentReport,
    required bool showSafetyCheck,
    required bool showLocationTracking,
    required String driverId,
  }) {
    void push(String route, {Object? arguments, bool replace = false}) {
      Navigator.pop(context);
      if (replace) {
        Navigator.pushReplacementNamed(context, route, arguments: arguments);
      } else {
        Navigator.pushNamed(context, route, arguments: arguments);
      }
    }

    switch (itemId) {
      case 'home':
        return [
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(tr('menu.home')),
            onTap: () => push(AppRoutes.dashboard, replace: true),
          )
        ];
      case 'my_vehicle':
        if (!showTrips) return const [];
        return [
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: Text(tr('menu.my_vehicle')),
            onTap: () => push(AppRoutes.myVehicle, replace: true),
          )
        ];
      case 'my_id_card':
        if (!showDriverId) return const [];
        return [
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(tr('menu.my_id_card')),
            onTap: () => push(AppRoutes.myIdCard),
          )
        ];
      case 'notifications':
        if (!showNotifications) return const [];
        return [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(tr('menu.notifications')),
            onTap: () => push(AppRoutes.notifications),
          )
        ];
      case 'profile':
        if (!showProfile) return const [];
        return [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(tr('menu.profile')),
            onTap: () => push(
              AppRoutes.profile,
              arguments: {'driverId': driverId},
            ),
          )
        ];
      // case 'report_issue_list':
      //   return [
      //     ListTile(
      //       leading: const Icon(Icons.history),
      //       title: Text(tr('menu.report_issue_list')),
      //       onTap: () => push(AppRoutes.reportIssueList),
      //     )
      //   ];
      // case 'incident_report':
      //   if (!showIncidentReport) return const [];
      //   return [
      //     ListTile(
      //       leading: const Icon(Icons.warning_amber_outlined),
      //       title: Text(tr('menu.incident_report')),
      //       onTap: () => push(AppRoutes.incidentReport),
      //     )
      //   ];
      case 'incident_report_list':
        if (!showIncidentReport) return const [];
        return [
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(tr('menu.incident_report_list')),
            onTap: () => push(AppRoutes.incidentReportList),
          )
        ];
      case 'safety_history':
        if (!showSafetyCheck) return const [];
        return [
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(tr('menu.safety_history')),
            onTap: () => push(AppRoutes.safetyHistory),
          )
        ];
      case 'maintenance':
        return [
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: Text(tr('menu.maintenance')),
            onTap: () => push(AppRoutes.maintenanceList),
          )
        ];
      case 'trip_report':
        if (!showLocationTracking) return const [];
        return [
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: Text(tr('menu.trip_report')),
            onTap: () => push(AppRoutes.tripReport),
          )
        ];
      // case 'daily_summary':
      //   if (!showLocationTracking) return const [];
      //   return [
      //     ListTile(
      //       leading: const Icon(Icons.insert_chart_outlined),
      //       title: Text(tr('menu.daily_summary')),
      //       onTap: () => push(AppRoutes.dailySummary),
      //     )
      //   ];
      case 'settings':
        if (!showSettings) return const [];
        return [
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(tr('menu.settings')),
            onTap: () => push(AppRoutes.settings),
          )
        ];
      case 'help':
        return [
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: Text(tr('menu.help')),
            onTap: () => push(AppRoutes.help),
          )
        ];
      case 'messages':
        return [
          ListTile(
            leading: const Icon(Icons.message),
            title: Text('Messages'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.messages);
            },
          )
        ];
      default:
        return const [];
    }
  }
}
