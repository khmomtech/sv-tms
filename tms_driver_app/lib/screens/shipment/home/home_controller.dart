import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/home_layout_section_model.dart';
import 'package:tms_driver_app/providers/app_bootstrap_provider.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/providers/notification_provider.dart';
import 'package:tms_driver_app/providers/safety_provider.dart';
import 'package:tms_driver_app/providers/user_provider.dart';
import 'package:tms_driver_app/screens/shipment/home/home_localizations.dart';
import 'package:tms_driver_app/screens/shipment/home/home_mappers.dart';
import 'package:tms_driver_app/screens/shipment/home/home_state.dart';
import 'package:tms_driver_app/services/banner_service.dart';
import 'package:tms_driver_app/services/home_layout_service.dart';
import 'package:tms_driver_app/services/version_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    BannerService? bannerService,
    VersionService? versionService,
    HomeLayoutService? layoutService,
  })  : _bannerService = bannerService ?? BannerService(),
        _versionService =
            versionService ?? VersionService(apiBaseUrl: ApiConstants.baseUrl),
        _layoutService = layoutService ?? HomeLayoutService();

  final BannerService _bannerService;
  final VersionService _versionService;
  final HomeLayoutService _layoutService;

  HomeState _state = HomeState.initial();
  HomeState get state => _state;
  Map<String, String> _lastApiHealth = const <String, String>{};
  Map<String, String> get lastApiHealth => _lastApiHealth;
  bool _disposed = false;

  Future<void> initialize(BuildContext context) => _load(context);

  Future<void> refresh(BuildContext context) => _load(context);

  Future<void> _load(BuildContext context) async {
    if (_disposed) return;
    final locale = HomeLocaleStrings.fromContext(context);

    _state = _state.copyWith(isLoading: true, clearError: true);
    _notifyIfAlive();

    final driverProvider = context.read<DriverProvider>();
    final dispatchProvider = context.read<DispatchProvider>();
    final safetyProvider = context.read<SafetyProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final userProvider = context.read<UserProvider>();
    final bootstrapProvider = context.read<AppBootstrapProvider>();
    final connectWsInBackground = bootstrapProvider.policy<bool>(
      'driver.home.connect_ws_in_background',
      true,
    );

    final failures = <String>[];
    final apiHealth = <String, String>{};
// Fetch home layout configuration with validation
    List<HomeLayoutSectionModel> layoutSections = [];
    try {
      layoutSections = await _layoutService.fetchLayout();

      // Validate we got meaningful data
      if (layoutSections.isEmpty) {
        debugPrint('[Home] Layout fetch returned empty list, using defaults');
        apiHealth['layout.config'] = 'empty';
      } else {
        // Validate section keys are known and non-empty
        final validSections = layoutSections
            .where((s) =>
                s.sectionKey.isNotEmpty &&
                HomeSectionKey.all.contains(s.sectionKey))
            .toList();

        if (validSections.length < layoutSections.length) {
          debugPrint(
              '[Home] Filtered out ${layoutSections.length - validSections.length} invalid sections');
        }

        layoutSections = validSections;
        apiHealth['layout.config'] = 'ok (${validSections.length} sections)';
      }
    } catch (e, st) {
      debugPrint('[Home] Layout fetch failed: $e\n$st');
      apiHealth['layout.config'] = 'failed: $e';
      // Layout failure shouldn't block home screen, use defaults
    }

    // Convert layout to state-friendly format with fallback
    final layoutOrder = layoutSections.isNotEmpty
        ? layoutSections.map((s) => s.sectionKey).toList()
        : HomeSectionKey.all; // Fallback to default order

    final visibleSections = layoutSections.isNotEmpty
        ? layoutSections
            .where((s) => s.visible)
            .map((s) => s.sectionKey)
            .toSet()
        : HomeSectionKey.all.toSet(); // Fallback to all visible

    // Initialize driver identity first so profile/dispatch calls have driverId.
    try {
      await driverProvider
          .loadLoggedInDriverId()
          .timeout(const Duration(seconds: 8));
      await driverProvider
          .fetchDriverProfile()
          .timeout(const Duration(seconds: 10));
      apiHealth['driver.session'] = 'ok';
    } catch (e, st) {
      debugPrint('Home init session failed: $e\n$st');
      failures.add('session');
      apiHealth['driver.session'] = 'failed: $e';
    }

    final driverId = driverProvider.driverId;
    if (driverId == null || driverId.isEmpty) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: locale.accountNotLinked,
      );
      _notifyIfAlive();
      return;
    }

    final profile = driverProvider.driverProfile;
    final username = (profile?['name'] ??
            profile?['displayName'] ??
            profile?['username'] ??
            userProvider.displayName ??
            userProvider.username)
        ?.toString();

    _state = _state.copyWith(
      username: username,
      isLoading: true,
      layoutOrder: layoutOrder,
      visibleSections: visibleSections,
      shift:
          HomeShiftVm(startTime: locale.shiftStart, endTime: locale.shiftEnd),
    );
    _notifyIfAlive();

    List<HomeUpdateVm> updates;
    updates = mapBannersToUpdates(
      const [],
      isKhmer: locale.isKhmer,
      fallbackTitle: locale.fallbackUpdateTitle,
      fallbackSubtitle: locale.fallbackUpdateSubtitle,
      fallbackImageUrl:
          'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?w=1200',
    );

    await Future.wait<void>([
      () async {
        try {
          final ok = await notificationProvider
              .fetchNotifications()
              .timeout(const Duration(seconds: 8));
          apiHealth['notifications.fetch'] =
              ok ? 'ok' : 'failed: fetch returned false';
        } catch (e, st) {
          debugPrint('Home notifications failed: $e\n$st');
          apiHealth['notifications.fetch'] = 'failed: $e';
        }
      }(),
      () async {
        if (connectWsInBackground) {
          apiHealth['notifications.ws'] = 'background';
          unawaited(() async {
            try {
              await notificationProvider
                  .connectWebSocket(driverId)
                  .timeout(const Duration(seconds: 8));
            } catch (e, st) {
              debugPrint('Home notifications ws failed: $e\n$st');
            }
          }());
          return;
        }
        try {
          await notificationProvider
              .connectWebSocket(driverId)
              .timeout(const Duration(seconds: 8));
          apiHealth['notifications.ws'] = 'ok';
        } catch (e, st) {
          debugPrint('Home notifications ws failed: $e\n$st');
          apiHealth['notifications.ws'] = 'failed: $e';
        }
      }(),
      () async {
        try {
          await Future.wait<void>([
            dispatchProvider
                .fetchPendingDispatches(driverId: driverId)
                .timeout(const Duration(seconds: 10)),
            dispatchProvider
                .fetchInProgressDispatches(driverId: driverId)
                .timeout(const Duration(seconds: 10)),
          ]);
          apiHealth['dispatch.pending'] = 'ok';
          apiHealth['dispatch.in_progress'] = 'ok';
        } catch (e, st) {
          debugPrint('Home dispatches failed: $e\n$st');
          failures.add('dispatches');
          apiHealth['dispatch.pending'] = 'failed: $e';
          apiHealth['dispatch.in_progress'] = 'failed: $e';
        }
      }(),
      () async {
        try {
          var vehicleId = _vehicleIdFromDriver(driverProvider);
          if (vehicleId == null) {
            await driverProvider
                .fetchCurrentAssignment()
                .timeout(const Duration(seconds: 8));
            vehicleId = _vehicleIdFromDriver(driverProvider);
          }
          if (vehicleId != null) {
            await safetyProvider
                .loadTodaySafety(vehicleId)
                .timeout(const Duration(seconds: 8));
            apiHealth['safety.today'] = 'ok';
          } else {
            apiHealth['safety.today'] = 'skipped: vehicle not found';
          }
        } catch (e, st) {
          debugPrint('Home safety failed: $e\n$st');
          apiHealth['safety.today'] = 'failed: $e';
        }
      }(),
      () async {
        try {
          updates = mapBannersToUpdates(
            await _bannerService
                .fetchActiveBanners(forceRefresh: true)
                .timeout(const Duration(seconds: 8)),
            isKhmer: locale.isKhmer,
            fallbackTitle: locale.fallbackUpdateTitle,
            fallbackSubtitle: locale.fallbackUpdateSubtitle,
            fallbackImageUrl:
                'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?w=1200',
          );
          apiHealth['banners.active'] = 'ok';
        } catch (e, st) {
          debugPrint('Home banners failed: $e\n$st');
          apiHealth['banners.active'] = 'failed: $e';
        }
      }(),
    ]);

    HomeCurrentTripVm? currentTrip;
    try {
      currentTrip = mapCurrentTripVm(
        dispatchProvider.inProgressDispatches,
        dispatchProvider.pendingDispatches,
        emptyLoadLabel: locale.loadPrefix,
        unknownRouteLabel: locale.tripEmpty,
        etaFallback: '--:--',
        progressFallback: locale.progressFallback,
        progressTemplate: locale.progressTemplate,
      );
    } catch (e, st) {
      debugPrint('Home current trip map failed: $e\n$st');
      failures.add('trip_map');
      currentTrip = null;
    }

    _SystemBannerVm banner;
    try {
      banner = await _resolveSystemBanner(locale.isKhmer)
          .timeout(const Duration(seconds: 6));
    } catch (e, st) {
      debugPrint('Home system banner failed: $e\n$st');
      banner = const _SystemBannerVm();
    }
    _lastApiHealth = Map<String, String>.unmodifiable(apiHealth);
    debugPrint('[Home/API Health] $_lastApiHealth');

    _state = _state.copyWith(
      isLoading: false,
      username: username,
      errorMessage:
          failures.isEmpty ? null : _loadErrorMessage(locale, failures),
      shift:
          HomeShiftVm(startTime: locale.shiftStart, endTime: locale.shiftEnd),
      currentTrip: currentTrip,
      updates: updates,
      systemBannerMessage: banner.message,
      systemBannerIsMaintenance: banner.isMaintenance,
      systemBannerHasInfo: banner.hasInfo,
      layoutOrder: layoutOrder,
      visibleSections: visibleSections,
    );
    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Track banner click analytics
  /// Returns true if tracking succeeded, false otherwise
  /// Errors are logged but don't throw to avoid blocking UI
  Future<bool> trackBannerClick(int? bannerId) async {
    if (bannerId == null || bannerId <= 0) {
      debugPrint('[Home] Invalid bannerId for tracking: $bannerId');
      return false;
    }

    try {
      await _bannerService.trackBannerClick(bannerId);
      debugPrint('[Home] Banner click tracked: $bannerId');
      return true;
    } catch (e, st) {
      debugPrint('[Home] Failed to track banner click $bannerId: $e\n$st');
      // Don't throw - analytics failures shouldn't block user
      return false;
    }
  }

  int? _vehicleIdFromDriver(DriverProvider provider) {
    final vehicle = provider.effectiveVehicle ?? provider.vehicleCardData;
    if (vehicle == null) return null;
    final raw = vehicle['id'] ?? vehicle['vehicleId'] ?? vehicle['vehicle_id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  String loadApiErrorMessage(String raw, BuildContext context) {
    final lower = raw.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('timed out') ||
        lower.contains('502') ||
        lower.contains('503') ||
        lower.contains('504') ||
        lower.contains('bad gateway') ||
        lower.contains('gateway timeout') ||
        lower.contains('service unavailable')) {
      return context.tr('home.errors.api_connection', namedArgs: {
        'api': ApiConstants.baseUrl,
      });
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return context.tr('home.errors.unauthorized');
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return context.tr('home.errors.forbidden');
    }
    if (lower.contains('not assigned to a driver') ||
        lower.contains('driver not found')) {
      return context.tr('home.errors.driver_not_assigned');
    }
    if (lower.contains('formatexception') ||
        lower.contains('unexpected character') ||
        lower.contains('<!doctype') ||
        lower.contains('<html') ||
        lower.contains('invalid server response')) {
      return context.tr('home.errors.invalid_response');
    }
    return context.tr('home.errors.api_generic', namedArgs: {'error': raw});
  }

  String _loadErrorMessage(HomeLocaleStrings locale, List<String> failures) {
    final labels = <String>[];
    if (failures.contains('session')) {
      labels.add(locale.partsSession);
    }
    if (failures.contains('notifications')) {
      labels.add(locale.partsNotifications);
    }
    if (failures.contains('notifications_ws')) {
      labels.add(locale.partsWebSocket);
    }
    if (failures.contains('dispatches')) {
      labels.add(locale.partsDispatches);
    }
    if (failures.contains('banners')) {
      labels.add(locale.partsBanners);
    }
    if (failures.contains('trip_map')) {
      labels.add(locale.partsTripMap);
    }
    if (failures.contains('safety')) {
      labels.add(locale.partsSafety);
    }
    if (failures.contains('vehicle')) {
      labels.add(locale.partsVehicle);
    }

    if (labels.isEmpty) {
      return locale.loadFailed;
    }
    return locale.loadFailedWithParts(labels.join(', '));
  }

  Future<_SystemBannerVm> _resolveSystemBanner(bool isKhmer) async {
    try {
      final info = await _versionService.loadLatest();
      if (info == null || !info.systemBannerEnabled) {
        return const _SystemBannerVm();
      }

      final maintenance = isKhmer
          ? info.maintenanceMessageKm.trim()
          : info.maintenanceMessageEn.trim();
      // Only show maintenance banner when backend explicitly enabled it
      if (info.maintenanceActive && maintenance.isNotEmpty) {
        // If maintenanceUntil is provided, ensure it's still in the future
        final untilRaw = info.maintenanceUntil;
        if (untilRaw.isEmpty) {
          return _SystemBannerVm(
            message: maintenance,
            isMaintenance: true,
            hasInfo: true,
          );
        }
        try {
          final until = DateTime.parse(untilRaw);
          if (until.isAfter(DateTime.now())) {
            return _SystemBannerVm(
              message: maintenance,
              isMaintenance: true,
              hasInfo: true,
            );
          }
        } catch (e) {
          // If parse fails, be conservative and do not show the banner
          debugPrint('Failed to parse maintenanceUntil: $e');
        }
      }

      final infoMessage = isKhmer ? info.infoKm.trim() : info.infoEn.trim();
      if (infoMessage.isNotEmpty) {
        return _SystemBannerVm(message: infoMessage, hasInfo: true);
      }
    } catch (e) {
      debugPrint('Home banner resolve failed: $e');
    }

    return const _SystemBannerVm();
  }
}

class _SystemBannerVm {
  final String? message;
  final bool isMaintenance;
  final bool hasInfo;

  const _SystemBannerVm({
    this.message,
    this.isMaintenance = false,
    this.hasInfo = false,
  });
}
