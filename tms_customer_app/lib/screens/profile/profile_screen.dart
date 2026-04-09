import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// localization not required in this screen

import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    final companyName = user?.username ?? 'SV Warehouse Co., Ltd.';
    final accountId = user?.customerId != null
        ? 'CUSTOMER-${user!.customerId}'
        : 'CUSTOMER-0018';
    const contact = '';
    final email = user?.email ?? 'ops@company.com';

    Widget sectionHeader(Widget child) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: theme.colorScheme.surface.withAlpha(20))),
        ),
        child: child,
      );
    }

    final TextStyle smallStyle = theme.textTheme.bodySmall
            ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w900) ??
        const TextStyle(fontSize: 12);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header using app primary color (red)
            Stack(
              children: [
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: theme.colorScheme.onPrimary.withAlpha((0.12 * 255).round()),
                          child: Icon(Icons.person, color: theme.colorScheme.onPrimary, size: 36),
                        ),
                        const SizedBox(width: 12),
                        // Greeting
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              const Text('Hello!',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                companyName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Settings icon
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                          icon: Icon(Icons.settings, color: theme.colorScheme.onPrimary),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),

            // Content
            Expanded(
              child: ListView(
                children: [
                  sectionHeader(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(companyName,
                          style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900, fontSize: 18, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Text('Account: $accountId', style: smallStyle),
                    ],
                  )),

                  sectionHeader(Column(
                    children: [
                      _rowItem(context, 'Contact', contact, smallStyle),
                      _rowItem(context, 'Email', email, smallStyle),
                      _rowItem(context, 'Billing Terms', 'NET 15', smallStyle),
                      _rowItem(
                          context, 'Language', 'Khmer / English', smallStyle),
                    ],
                  )),

                    // Consolidated account menu (Top-up, Red Pocket, Addresses, Orders, Tracking)
                    sectionHeader(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Column(
                        children: [
                        // Top-up and Red Pocket removed — not used in this build
                        ListTile(
                          visualDensity: const VisualDensity(vertical: -1),
                          leading: CircleAvatar(
                            backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.location_on,
                              color: theme.colorScheme.primary)),
                          title: Text('My Address',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                          trailing: Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurface.withAlpha(153)),
                          onTap: () => Navigator.pushNamed(
                            context, AppRoutes.profile),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          visualDensity: const VisualDensity(vertical: -1),
                          leading: CircleAvatar(
                            backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.list_alt,
                              color: theme.colorScheme.primary)),
                          title: Text('My Orders',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                          trailing: Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurface.withAlpha(153)),
                          onTap: () => Navigator.pushNamed(
                            context, AppRoutes.orders),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          visualDensity: const VisualDensity(vertical: -1),
                          leading: CircleAvatar(
                            backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.search,
                              color: theme.colorScheme.primary)),
                          title: Text('Search Tracking Number',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                          trailing: Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurface.withAlpha(153)),
                          onTap: () => Navigator.pushNamed(
                            context, AppRoutes.tracking),
                        ),
                        ],
                      ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child:
                        Text('Support', style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                      ),
                      Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Column(
                        children: [
                        ListTile(
                          visualDensity: const VisualDensity(vertical: -1),
                          leading: CircleAvatar(
                            backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.notifications,
                              color: theme.colorScheme.primary)),
                          title: Text('Notification',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                          trailing: Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurface.withAlpha(153)),
                          onTap: () => Navigator.pushNamed(
                            context, AppRoutes.notifications),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          visualDensity: const VisualDensity(vertical: -1),
                          leading: CircleAvatar(
                            backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.support_agent,
                              color: theme.colorScheme.primary)),
                          title: Text('Contact Support',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                          trailing: Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurface.withAlpha(153)),
                          onTap: () => Navigator.pushNamed(
                            context, AppRoutes.contact),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          visualDensity: const VisualDensity(vertical: -1),
                          leading: CircleAvatar(
                            backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.help_outline,
                              color: theme.colorScheme.primary)),
                          title: Text('Help Center',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface)),
                          trailing: Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurface.withAlpha(153)),
                          onTap: () => Navigator.pushNamed(
                            context, AppRoutes.articles),
                        ),
                        ],
                      ),
                      ),
                    ],
                    )),

                  sectionHeader(Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => Navigator.pushNamed(
                              context, AppRoutes.changePassword),
                          child: const Text('Change Password',
                              style:
                                  TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            await auth.logout();
                            if (!navigator.mounted) return;
                            navigator.pushReplacementNamed(AppRoutes.login);
                          },
                          child: const Text('🚪 Logout',
                              style:
                                  TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  )),

                  const SizedBox(height: 88), // space for bottom nav
                ],
              ),
            ),

            // Bottom nav (sticky)
            Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: theme.colorScheme.surface.withAlpha(20))),
                color: Colors.white,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _navItem(context, Icons.home, 'Home', AppRoutes.home),
                    _navItem(
                        context, Icons.list_alt, 'Orders', AppRoutes.shipments),
                    _navItem(context, Icons.support_agent, 'Support',
                        AppRoutes.contact),
                    _navItem(context, Icons.person, 'Me', AppRoutes.profile,
                        active: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowItem(
      BuildContext context, String label, String value, TextStyle smallStyle) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              Text(value, style: smallStyle),
            ],
          ),
        ),
        Divider(color: theme.colorScheme.onSurface.withAlpha(15), height: 1),
      ],
    );
  }

  Widget _navItem(
      BuildContext context, IconData icon, String label, String route,
      {bool active = false}) {
    final theme = Theme.of(context);
    final color = active ? Colors.red : Colors.grey[600];
    return Expanded(
      child: InkWell(
        onTap: () {
          if (route.isNotEmpty) Navigator.pushNamed(context, route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: color, fontWeight: FontWeight.w900, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
