import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tms_driver_app/screens/shipment/home/home_routes.dart';

class HomeBottomNavItem {
  final String id;
  final IconData icon;
  final String labelKey;

  const HomeBottomNavItem({
    required this.id,
    required this.icon,
    required this.labelKey,
  });
}

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    required this.currentId,
    required this.items,
    required this.onTap,
    super.key,
  });

  final String currentId;
  final List<HomeBottomNavItem> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveItems = items.isNotEmpty
      ? items
      : const <HomeBottomNavItem>[
        HomeBottomNavItem(
          id: HomeRoutes.navHome,
          icon: Icons.home,
          labelKey: 'bottom_nav.home'),
        HomeBottomNavItem(
          id: HomeRoutes.navTrips,
          icon: Icons.local_shipping,
          labelKey: 'bottom_nav.trips'),
        HomeBottomNavItem(
          id: HomeRoutes.navSupport,
          icon: Icons.support_agent,
          labelKey: 'bottom_nav.support'),
        HomeBottomNavItem(
          id: HomeRoutes.navMore,
          icon: Icons.more_horiz,
          labelKey: 'bottom_nav.more'),
        ];
    final selectedIndex = effectiveItems
        .indexWhere((item) => item.id == currentId)
        .clamp(0, 9999);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: (index) => onTap(effectiveItems[index].id),
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey.shade500,
      items: effectiveItems
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: context.tr(item.labelKey),
              ))
          .toList(),
    );
  }
}
