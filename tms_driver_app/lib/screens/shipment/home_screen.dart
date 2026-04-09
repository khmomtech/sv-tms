import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/home_layout_section_model.dart';
import 'package:tms_driver_app/providers/notification_provider.dart';
import 'package:tms_driver_app/providers/app_bootstrap_provider.dart';
import 'package:tms_driver_app/providers/settings_provider.dart';
import 'package:tms_driver_app/providers/user_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/screens/shipment/home/home_controller.dart';
import 'package:tms_driver_app/screens/shipment/home/home_routes.dart';
import 'package:tms_driver_app/screens/shipment/home/home_state.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/current_trip_section.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/home_bottom_nav.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/home_header_section.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/important_updates_section.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/maintenance_banner_section.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/quick_actions_section.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/safety_status_section.dart';
import 'package:tms_driver_app/screens/shipment/home/sections/shift_status_section.dart';
import 'package:tms_driver_app/screens/shipment/widgets/home_error_view.dart';
import 'package:tms_driver_app/screens/shipment/widgets/loading_placeholder.dart';
import 'package:tms_driver_app/utils/banner_navigation.dart';
import 'package:tms_driver_app/widgets/driver_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final HomeController _controller = HomeController();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _dashboardRefreshTimer;
  VoidCallback? _settingsListener;
  bool _wasDisconnected = false;
  bool _isBannerDismissed = false;

  String _selectedBottomNavId = HomeRoutes.navHome;

  @override
  void initState() {
    super.initState();
    _listenToConnectivityChanges();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isLoggedIn = await ApiConstants.isLoggedIn();
      if (!mounted) return;
      if (!isLoggedIn) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.signin, (_) => false);
        return;
      }
      try {
        await context
            .read<AppBootstrapProvider>()
            .refreshFromServer()
            .timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('[Home] Bootstrap refresh timeout/failure: $e');
      }
      await _controller.initialize(context);
      _setupAutoRefresh();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _dashboardRefreshTimer?.cancel();
    final listener = _settingsListener;
    if (listener != null) {
      try {
        context.read<SettingsProvider>().removeListener(listener);
      } catch (_) {}
    }
    _controller.dispose();
    try {
      context.read<NotificationProvider>().disconnectWebSocket();
    } catch (_) {}
    super.dispose();
  }

  void _setupAutoRefresh() {
    _dashboardRefreshTimer?.cancel();
    final settings = context.read<SettingsProvider>();
    final bootstrap = context.read<AppBootstrapProvider>();
    final policySec = bootstrap.policy<int>('dashboard.refresh_sec', -1);
    final intervalSec = settings.dashboardRefreshSec.clamp(10, 300);
    final effectiveSec = policySec > 0 ? policySec.clamp(10, 300) : intervalSec;

    _settingsListener ??= () {
      if (!mounted) return;
      _setupAutoRefresh();
    };
    settings.removeListener(_settingsListener!);
    settings.addListener(_settingsListener!);

    _dashboardRefreshTimer =
        Timer.periodic(Duration(seconds: effectiveSec), (_) async {
      if (!mounted) return;
      await _controller.refresh(context);
    });
  }

  Future<void> _onRefresh() async {
    _isBannerDismissed = false;
    await _controller.refresh(context);
    if (!mounted) return;
    setState(() {});
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isConnected =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      if (isConnected && _wasDisconnected) {
        _showSnackBar('connectivity.online', Colors.green);
      } else if (!isConnected) {
        _showSnackBar('connectivity.offline', Colors.red);
      }

      _wasDisconnected = !isConnected;
    });
  }

  void _showSnackBar(String key, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(key)),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _onUpdateTap(HomeUpdateVm item) async {
    // Track click asynchronously but don't block navigation
    // Analytics failures shouldn't prevent user from accessing content
    _controller.trackBannerClick(item.id).catchError((e) {
      debugPrint('[Home] Banner click tracking failed: $e');
      return false;
    });

    final target = item.targetUrl;
    if (target == null || target.isEmpty) return;

    final resolution = resolveBannerTarget(target);
    switch (resolution.type) {
      case BannerNavType.internalRoute:
        final route = resolution.route;
        if (route != null && mounted) {
          try {
            await Navigator.pushNamed(context, route);
          } catch (_) {
            _showSnackBar('error.data_load_failed', Colors.red);
          }
        }
        return;
      case BannerNavType.externalUrl:
        if (resolution.url != null) {
          final canLaunch = await canLaunchUrl(resolution.url!);
          if (!canLaunch) {
            _showSnackBar('error.data_load_failed', Colors.red);
            return;
          }
          await launchUrl(
            resolution.url!,
            mode: LaunchMode.externalApplication,
          );
        }
        return;
      case BannerNavType.bannerArticle:
        if (!mounted) return;
        try {
          await Navigator.pushNamed(
            context,
            AppRoutes.bannerArticle,
            arguments: <String, dynamic>{
              'id': resolution.articleId,
              'url': resolution.articleUrl?.toString(),
              'title': item.title,
            },
          );
        } catch (_) {
          _showSnackBar('error.data_load_failed', Colors.red);
        }
        return;
      case BannerNavType.invalid:
        _showSnackBar('error.data_load_failed', Colors.red);
        return;
    }
  }

  void _onQuickActionTap(String actionId) {
    final bootstrap = context.read<AppBootstrapProvider>();
    final featureKey = _featureKeyForQuickAction(actionId);
    if (featureKey != null &&
        !bootstrap.isFeatureEnabled(featureKey, fallback: true)) {
      _showSnackBar('feature.coming_soon', Colors.blue);
      return;
    }

    final route = HomeRoutes.quickActionRoute(actionId);
    if (route == null) {
      _showSnackBar('feature.coming_soon', Colors.blue);
      return;
    }
    Navigator.pushNamed(context, route);
  }

  void _onBottomNavTap(String navId) {
    final bootstrap = context.read<AppBootstrapProvider>();
    final screenKey = _screenKeyForBottomNav(navId);
    if (screenKey != null &&
        !bootstrap.isScreenVisible(screenKey, fallback: true)) {
      _showSnackBar('feature.coming_soon', Colors.blue);
      return;
    }

    setState(() => _selectedBottomNavId = navId);
    final route = HomeRoutes.bottomNavRouteById(navId);
    if (route != null) {
      Navigator.pushNamed(context, route);
    }
  }

  String? _featureKeyForQuickAction(String actionId) {
    switch (actionId) {
      case 'incident_report':
        return 'incident_report.enabled';
      case 'report_issue':
        return 'incident_report.enabled';
      case 'my_trips':
      case 'trip_report':
        return 'location_tracking.enabled';
      default:
        return null;
    }
  }

  String? _screenKeyForBottomNav(String navId) {
    switch (navId) {
      case HomeRoutes.navTrips:
        return 'trips.visible';
      case HomeRoutes.navSupport:
        return 'support.visible';
      case HomeRoutes.navMore:
        return 'settings.visible';
      default:
        return null;
    }
  }

  List<String> _quickActionIds(AppBootstrapProvider bootstrap) {
    return bootstrap.policyStringList(
      'nav.home.quick_actions',
      fallback: const <String>[
        'my_trips',
        'incident_report',
        'report_issue',
        'documents',
        'trip_report',
        'help_center',
      ],
    );
  }

  List<HomeBottomNavItem> _bottomNavItems(AppBootstrapProvider bootstrap) {
    final ids = bootstrap.policyStringList(
      'nav.bottom.items',
      fallback: const <String>[
        HomeRoutes.navHome,
        HomeRoutes.navTrips,
        HomeRoutes.navSupport,
        HomeRoutes.navMore,
      ],
    );
    const specs = <String, HomeBottomNavItem>{
      HomeRoutes.navHome: HomeBottomNavItem(
          id: HomeRoutes.navHome,
          icon: Icons.home,
          labelKey: 'bottom_nav.home'),
      HomeRoutes.navTrips: HomeBottomNavItem(
          id: HomeRoutes.navTrips,
          icon: Icons.local_shipping,
          labelKey: 'bottom_nav.trips'),
      HomeRoutes.navSupport: HomeBottomNavItem(
          id: HomeRoutes.navSupport,
          icon: Icons.support_agent,
          labelKey: 'bottom_nav.support'),
      HomeRoutes.navMore: HomeBottomNavItem(
          id: HomeRoutes.navMore,
          icon: Icons.more_horiz,
          labelKey: 'bottom_nav.more'),
    };
    return ids.map((id) => specs[id]).whereType<HomeBottomNavItem>().toList();
  }

  /// Build home sections dynamically based on layout configuration
  List<Widget> _buildHomeSections(HomeState state, int unreadCount) {
    final sections = <Widget>[];

    // If no layout configured, use default order
    final layoutOrder =
        state.layoutOrder.isNotEmpty ? state.layoutOrder : HomeSectionKey.all;
    final visibleSections = state.visibleSections.isNotEmpty
        ? state.visibleSections
        : HomeSectionKey.all.toSet();

    // Build each section in order
    for (final sectionKey in layoutOrder) {
      // Skip if not visible
      if (!visibleSections.contains(sectionKey)) continue;

      Widget? section;
      switch (sectionKey) {
        case HomeSectionKey.header:
          section = HomeHeaderSection(
            key: const ValueKey('home_section_header'),
            username:
                state.username ?? context.tr('home.header.driver_fallback'),
            unreadCount: unreadCount,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onNotificationsTap: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
          );
          break;

        case HomeSectionKey.maintenanceBanner:
          // Only build if there's a message to show
          if (!_isBannerDismissed && state.systemBannerMessage != null) {
            section = MaintenanceBannerSection(
              key: const ValueKey('home_section_maintenance'),
              message: state.systemBannerMessage,
              isMaintenance: state.systemBannerIsMaintenance,
              hasInfo: state.systemBannerHasInfo,
              onInfoTap: () => Navigator.pushNamed(context, AppRoutes.about),
              onClose: () => setState(() => _isBannerDismissed = true),
            );
          }
          break;

        case HomeSectionKey.shiftStatus:
          if (context
              .read<AppBootstrapProvider>()
              .isFeatureEnabled('home.shift_status.visible', fallback: false)) {
            section = ShiftStatusSection(
              key: const ValueKey('home_section_shift'),
              shift: state.shift,
            );
          }
          break;

        case HomeSectionKey.safetyStatus:
          section = SafetyStatusSection(
            key: const ValueKey('home_section_safety'),
            onOpenSafetyCheck: () =>
                Navigator.pushNamed(context, AppRoutes.safetyCheck),
            onOpenSafetyDetail: (safety) => Navigator.pushNamed(
              context,
              AppRoutes.safetyDetail,
              arguments: <String, dynamic>{'safety': safety},
            ),
            mapApiError: (raw) =>
                _controller.loadApiErrorMessage(raw, context),
          );
          break;

        case HomeSectionKey.importantUpdates:
          section = ImportantUpdatesSection(
            key: const ValueKey('home_section_updates'),
            updates: state.updates,
            onTap: _onUpdateTap,
          );
          break;

        case HomeSectionKey.currentTrip:
          section = CurrentTripSection(
            key: const ValueKey('home_section_trip'),
            trip: state.currentTrip,
          );
          break;

        case HomeSectionKey.quickActions:
          section = QuickActionsSection(
            key: const ValueKey('home_section_actions'),
            actionIds: _quickActionIds(context.read<AppBootstrapProvider>()),
            onTap: _onQuickActionTap,
          );
          break;

        default:
          debugPrint('[Home] Unknown section key: $sectionKey');
          break;
      }

      if (section != null) {
        sections.add(section);
      }
    }

    // Always add error view at the end if there's an error
    if (state.errorMessage != null) {
      sections.add(
        HomeErrorView(
          errorMessage: state.errorMessage!,
          onRetry: _onRefresh,
        ),
      );
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final unreadCount = context.watch<NotificationProvider>().unreadCount;
        final bootstrap = context.watch<AppBootstrapProvider>();
        final bottomNavItems = _bottomNavItems(bootstrap);

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF4F6FA),
          drawer: DriverDrawer(
            onLogout: () async {
              await context.read<UserProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.signin);
            },
          ),
          body: SafeArea(
            child: state.isLoading && state.username == null
                ? const Center(
                    child: LoadingPlaceholder(height: 120, width: 140))
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: _buildHomeSections(state, unreadCount),
                    ),
                  ),
          ),
          bottomNavigationBar: HomeBottomNav(
            currentId: _selectedBottomNavId,
            items: bottomNavItems,
            onTap: _onBottomNavTap,
          ),
        );
      },
    );
  }
}
