import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  final dynamic user;
  const AppDrawer({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = user?.username ?? 'Guest';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ── Gradient header ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1A2560)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withAlpha(30),
                    child: Text(
                      (userName.isNotEmpty ? userName[0] : 'G').toUpperCase(),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Navigation items ────────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text('home'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text('orders'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.orders);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_shopping_cart_outlined),
              title: Text('create_order'.tr()),
              onTap: () {
                Navigator.pop(context);
                final userProv = context.read<UserProvider>();
                final cid = userProv.customerId;
                if (cid != null) {
                  Navigator.pushNamed(context, AppRoutes.createOrder,
                      arguments: {'customerId': cid});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('no_customer'.tr())));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text('tracking'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.tracking);
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: Text('incidents'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.incidents);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: Text('bookings'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.bookings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text('articles'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.articles);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text('profile'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: Text('support'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.contact);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('about'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.about);
              },
            ),

            const Spacer(),

            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text('settings'.tr()),
              onTap: () {
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context, rootNavigator: true)
                      .pushNamed(AppRoutes.settings);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: Text(
                'logout'.tr(),
                style: const TextStyle(color: AppColors.danger),
              ),
              onTap: () async {
                final authProvider = context.read<AuthProvider>();
                final navigator = Navigator.of(context);
                await authProvider.logout();
                navigator.pushReplacementNamed(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
