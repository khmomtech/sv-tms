// 📁 lib/main.dart
import 'dart:async';
import 'dart:ui' as ui;

// import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

import 'core/accessibility/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/network/api_constants.dart';
import 'core/security/security_config.dart';
import 'core/security/token_refresh_manager.dart';
import 'providers/about_app_provider.dart';
import 'providers/app_bootstrap_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/call_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/dispatch_provider.dart';
import 'providers/driver_issue_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/safety_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/sign_in_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'services/battery_optimization_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/location_service.dart';
import 'services/native_service_bridge.dart';
import 'services/session_manager.dart';
import 'services/tracking_session_manager.dart';
import 'utils/notification_helper.dart';
import 'firebase/setup_firebase_messaging.dart' show drainPendingFcmCall;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const String backgroundTaskId = 'sv.background.fallback';

const MethodChannel _appRouteChannel = MethodChannel('app_route');

// --- Single in-app LocationService instance + guards ---
final LocationService _loc = LocationService();
bool _locStarted = false;
StreamSubscription? _locSub;
bool _locationDialogShownThisSession = false;

Future<void> _bootstrapNativeConfigOnAppLoad() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = await ApiConstants.ensureFreshAccessToken();
    final trackingToken = await ApiConstants.ensureFreshTrackingToken();
    final trackingSessionId = await ApiConstants.getTrackingSessionId();
    final refreshToken = await ApiConstants.getRefreshToken();
    final driverId = prefs.getString('driverId');

    if (token == null ||
        token.isEmpty ||
        driverId == null ||
        driverId.isEmpty) {
      debugPrint('[Init] Missing token/driverId → skip native bootstrap');
      return;
    }

    // Resolve base API and WS URL from prefs or centralized constant
    final baseApi = (prefs.getString('apiUrl') ?? ApiConstants.baseUrl).trim();
    final wsPref = (prefs.getString('wsUrl') ?? '').trim();

    String wsUrl;
    final wsAuthToken = (trackingToken != null && trackingToken.isNotEmpty)
        ? trackingToken
        : token;
    if (wsAuthToken.isEmpty) {
      debugPrint('[Init] Missing WS auth token → skip native bootstrap');
      return;
    }
    if (wsPref.isNotEmpty) {
      final normalized = _deriveWsFromBase(wsPref);
      wsUrl = _appendWsToken(normalized, wsAuthToken);
    } else {
      wsUrl = await ApiConstants.getDriverLocationWebSocketUrlWithToken(
          wsAuthToken);
    }

    final driverName = prefs.getString('driverName');
    final vehiclePlate = prefs.getString('vehiclePlate');

    // Push fresh config to native unconditionally (even if service already running)
    const channel = MethodChannel('sv/native_service');
    await channel.invokeMethod('startService', {
      'token': token,
      'trackingToken': trackingToken,
      'trackingSessionId': trackingSessionId,
      'refreshToken': refreshToken,
      'driverId': driverId,
      'wsUrl': wsUrl,
      'baseApiUrl': baseApi,
      'driverName': driverName,
      'vehiclePlate': vehiclePlate,
    });

    debugPrint(
        '[Init] Bootstrapped native config (driverId=$driverId, base=$baseApi, ws=${_maskBoot(wsUrl)})');
  } catch (e, st) {
    debugPrint('Native bootstrap failed: $e\n$st');
  }
}

String _deriveWsFromBase(String base) {
  if (base.isEmpty) return '';
  var b = base.trim();
  if (b.endsWith('/')) b = b.substring(0, b.length - 1);
  if (b.startsWith('https://')) {
    return '${b.replaceFirst('https://', 'wss://')}/ws';
  }
  if (b.startsWith('http://')) {
    return '${b.replaceFirst('http://', 'ws://')}/ws';
  }
  if (b.startsWith('wss://') || b.startsWith('ws://')) return b; // already WS
  return 'ws://$b/ws';
}

String _appendWsToken(String base, String token) {
  final uri = Uri.parse(base);
  final nextParams = Map<String, String>.from(uri.queryParameters)
    ..remove('token')
    ..['token'] = token;
  return uri.replace(queryParameters: nextParams).toString();
}

String _maskBoot(String url) {
  final i = url.indexOf('token=');
  if (i < 0) return url;
  final end = url.indexOf('&', i + 6);
  return url.replaceRange(i + 6, end < 0 ? url.length : end, '***');
}

Future<void> _ensureDartLocationServiceStarted() async {
  if (_locStarted) return;
  // Forward Dart-side updates → websocket
  _locSub ??= _loc.updates.listen((update) {
    // UI hook only: network sending handled by native FGS or Dart service itself.
  });
  await _loc.start(accuracy: LocationAccuracy.high, distanceFilterMeters: 10);
  _locStarted = true;
}

Future<void> _startTrackingOnce() async {
  final prefs = await SharedPreferences.getInstance();
  final driverId = prefs.getString('driverId');
  final token = await ApiConstants.ensureFreshAccessToken();

  if (driverId == null || driverId.isEmpty || token == null || token.isEmpty) {
    debugPrint('[Init] Missing driverId/token → skip start');
    return;
  }

  // Native foreground service (idempotent on Dart side)
  final ok = await NativeServiceBridge.startServiceOnce(
    token: token,
    driverId: driverId,
  );
  debugPrint('[Init] Native service ${ok ? "running" : "not started"}');

  // Dart-side (in-app) sender only as FALLBACK when native isn't running
  if (!ok) {
    await _ensureDartLocationServiceStarted();
  } else {
    debugPrint('[Init] Skipping Dart sender; native FGS is active');
  }
}

// Utility: check if Always Location is already granted
Future<bool> hasAlwaysLocationPermission() async {
  final status = await Permission.locationAlways.status;
  return status.isGranted;
}

/// Unified Always-location + startup flow
Future<void> requestAlwaysLocationPermissionAndStartServices(
    {BuildContext? context}) async {
  try {
    // If already granted, just start tracking
    final currentAlways = await Permission.locationAlways.status;
    if (currentAlways.isGranted) {
      await _startTrackingOnce();
      return;
    }

    // Foreground first
    final fg = await Permission.location.request();
    if (fg.isPermanentlyDenied) {
      if (!_locationDialogShownThisSession &&
          context != null &&
          context.mounted) {
        _locationDialogShownThisSession = true;
        await _showGoToSettingsDialog(
          context,
          title: 'Location Permission Required',
          message: 'Please allow location access in Settings to continue.',
        );
      }
      return;
    }

    // Always/background
    PermissionStatus always = await Permission.locationAlways.status;
    if (always.isDenied) {
      always = await Permission.locationAlways.request();
    }
    if (always.isDenied) {
      final showRationale =
          await Permission.locationAlways.shouldShowRequestRationale;
      if (showRationale &&
          !_locationDialogShownThisSession &&
          context != null &&
          context.mounted) {
        _locationDialogShownThisSession = true;
        final retry = await _showAllowDialog(context);
        if (retry == true) {
          always = await Permission.locationAlways.request();
        }
      }
    }
    if (always.isPermanentlyDenied) {
      if (!_locationDialogShownThisSession &&
          context != null &&
          context.mounted) {
        _locationDialogShownThisSession = true;
        await _showGoToSettingsDialog(
          context,
          title: 'Background Location Required',
          message:
              'Please enable "Always" location in Settings to allow background tracking.',
        );
      }
      return;
    }

    // Notifications
    await Permission.notification.request();

    // Battery optimization
    final ignoring =
        await BatteryOptimizationService.isIgnoringBatteryOptimizations();
    if (!ignoring) {
      await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
    }

    // Start both native FGS + Dart sender once
    if (always.isGranted || fg.isGranted) {
      await _startTrackingOnce();
    }
  } catch (e, stack) {
    debugPrint(
        'requestAlwaysLocationPermissionAndStartServices failed: $e\n$stack');
  }
}

// Top-level background handler for FCM (required for background isolate)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      debugPrint('[BG FCM] Initializing Firebase (cold start)');
      await Firebase.initializeApp();
    } else {
      debugPrint('[BG FCM] Firebase already initialized');
    }
    await NotificationHelper.initialize(); // idempotent
    await NotificationHelper.showRemoteMessage(message);
  } catch (e, st) {
    // ignore: avoid_print
    print('BG FCM handler error: $e\n$st');
  }
}

// --- Shared notification navigation helper ---
void handleNotificationNavigation(Map data, BuildContext? ctx) {
  if (ctx == null) return;
  final type = (data['type'] ?? '').toString().toLowerCase();
  final refId = data['referenceId'];
  switch (type) {
    case 'dispatch':
      final dispatchId = refId?.toString();
      if (dispatchId != null && dispatchId.isNotEmpty) {
        Navigator.of(ctx).pushNamed(
          AppRoutes.dispatchDetail,
          arguments: {'dispatchId': dispatchId},
        );
      } else {
        debugPrint('[Navigation] Missing dispatchId in notification payload');
        Navigator.of(ctx).pushNamed(AppRoutes.notifications);
      }
      break;
    case 'issue':
      Navigator.of(ctx).pushNamed(AppRoutes.reportIssueList);
      break;
    default:
      Navigator.of(ctx).pushNamed(AppRoutes.notifications);
  }
}

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Request App Tracking Transparency only when explicitly enabled in config.
    // For enterprise driver app we disable ATT by default to avoid unnecessary prompts.
    // try {
    //   if (defaultTargetPlatform == TargetPlatform.iOS &&
    //       SecurityConfig.appUsesTracking) {
    //     final status =
    //         await AppTrackingTransparency.trackingAuthorizationStatus;
    //     if (status == TrackingStatus.notDetermined) {
    //       final req =
    //           await AppTrackingTransparency.requestTrackingAuthorization();
    //       debugPrint('[ATT] requestTrackingAuthorization -> $req');
    //     } else {
    //       debugPrint('[ATT] current status -> $status');
    //     }
    //   } else {
    //     debugPrint(
    //         '[ATT] skipped (appUsesTracking=${SecurityConfig.appUsesTracking})');
    //   }
    // } catch (e, st) {
    //   debugPrint('[ATT] error requesting tracking permission: $e\n$st');
    // }

    FlutterError.onError =
        (details) => FlutterError.dumpErrorToConsole(details);
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught platform error: $error\n$stack');
      return true;
    };

    // Parallel startup for faster boot
    await Future.wait([
      if (Firebase.apps.isEmpty)
        Firebase.initializeApp()
            .then((_) => debugPrint('[Main] Firebase initialized')),
      EasyLocalization.ensureInitialized(),
      initializeDateFormatting('km_KH', null),
    ]);

    // Initialize dependency injection (service locator)
    await setupServiceLocator();
    debugPrint('[Main] Service locator initialized');

    await ApiConstants.init();
    ApiConstants.setTokenUpdateListener((token) async {
      if (token.trim().isEmpty) return;
      final refreshToken = await ApiConstants.getRefreshToken();
      final trackingToken = await ApiConstants.getTrackingToken();
      final trackingSessionId = await ApiConstants.getTrackingSessionId();
      await NativeServiceBridge.notifyTokenUpdated(
        token: token,
        trackingToken: trackingToken,
        trackingSessionId: trackingSessionId,
        refreshToken: refreshToken,
      );
    });
    await NotificationHelper.initialize();

    // Initialize security services
    SecurityConfig.validateConfig();
    SecurityConfig.printConfig();

    // Start automatic token refresh monitoring
    final isLoggedIn = await ApiConstants.isLoggedIn();
    if (isLoggedIn) {
      await TokenRefreshManager().startAutoRefresh();
      await TrackingSessionManager.instance.ensureTrackingSession();
      debugPrint('[Main] Token refresh manager started');
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _appRouteChannel.setMethodCallHandler((call) async {
      if (call.method == 'openRoute') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        handleNotificationNavigation(
            args, navigatorKey.currentState?.overlay?.context);
      }
    });

    setOnNotificationTapHandler((data) {
      handleNotificationNavigation(
          data, navigatorKey.currentState?.overlay?.context);
    });

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('km')],
        path: 'assets/translations',
        fallbackLocale: const Locale('km'),
        startLocale: const Locale('km'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
        child: const MyApp(),
      ),
    );

    WidgetsBinding.instance.addObserver(AppLifecycleListener(
      onResume: () async {
        debugPrint('[Lifecycle] App resumed');
        await _bootstrapNativeConfigOnAppLoad();
      },
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initial =
            await _appRouteChannel.invokeMethod<Map>('getInitialRoute');
        if (initial != null) {
          handleNotificationNavigation(
              initial, navigatorKey.currentState?.overlay?.context);
        }
      } catch (_) {}

      await _bootstrapNativeConfigOnAppLoad();
      await FirebaseMessagingService().initialize();
      // Deferred: do NOT start background tracking automatically on app launch.
      // Background tracking must be started explicitly by user (On Duty toggle).

      FirebaseMessaging.onMessage.listen((m) async {
        await NotificationHelper.show(m);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        handleNotificationNavigation(
            m.data, navigatorKey.currentState?.overlay?.context);
      });

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        handleNotificationNavigation(
            initialMessage.data, navigatorKey.currentState?.overlay?.context);
      }

      // Drain any incoming call that arrived via FCM while the app was killed.
      // Must run after the navigator is mounted so _navigateToIncomingCall can push.
      try {
        await drainPendingFcmCall(navigatorKey);
      } catch (_) {}
    });
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}

@pragma('vm:entry-point')
Future<void> _delayedBackgroundInit() async {
  try {
    final ignoring =
        await BatteryOptimizationService.isIgnoringBatteryOptimizations();
    if (!ignoring) {
      await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
    }

    // Your own wrapper (topics, token upload, etc.)
    await FirebaseMessagingService().initialize();

    // Only start tracking after we've pushed config once (still safe if called twice)
    await _bootstrapNativeConfigOnAppLoad();
    // Deferred: do NOT start background tracking automatically here.
    // Background tracking must be started explicitly by the user (On Duty toggle).
  } catch (e, stack) {
    debugPrint('Background Init Error: $e\n$stack');
  }
}

/// Legacy BC
Future<void> requestPermissionsAndStartServices({BuildContext? context}) async {
  await requestAlwaysLocationPermissionAndStartServices(context: context);
}

// ----------------------- UI scaffolding -----------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AppBootstrapProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SignInProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => SafetyProvider()),
        ChangeNotifierProvider(create: (_) => sl<DispatchProvider>()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProxyProvider<CallProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, callProvider, chatProvider) {
            chatProvider!.callProvider = callProvider;
            return chatProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => DriverIssueProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AboutAppProvider()),
        ChangeNotifierProvider(create: (_) => SessionManager.instance),
      ],
      child: const _ThemedApp(),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();
  @override
  Widget build(BuildContext context) {
    final isDark = context.select<ThemeProvider, bool>((p) => p.isDarkTheme);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        ErrorWidget.builder = (details) => Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Something went wrong.\n${details.exceptionAsString()}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );

        // Respect system font size settings for accessibility
        // Allow text scaling up to 2.0x (200%) to support users with visual impairments
        final media = MediaQuery.of(context);
        final textScaleFactor = media.textScaler.scale(1.0);
        final constrainedScaleFactor = textScaleFactor.clamp(0.8, 2.0);

        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(constrainedScaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}

// ---------------- helper dialogs ----------------
Future<void> _showGoToSettingsDialog(BuildContext context,
    {required String title, required String message}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later')),
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings')),
      ],
    ),
  );
}

Future<bool?> _showAllowDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Allow Background Location'),
      content: const Text(
          'We need "Always" location so trips can be tracked while the app is in the background.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now')),
        TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow')),
      ],
    ),
  );
}

// ---------------- Diagnostics Screen ----------------
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});
  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final MethodChannel _diag = const MethodChannel('diag');
  Map<String, dynamic> _native = {};
  bool _locFg = false;
  bool _locBg = false;
  bool _notifPerm = false;
  bool _batteryIgnored = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final diagRaw = await _diag.invokeMethod('getDiagnostics');
      final diag = Map<String, dynamic>.from(diagRaw as Map);

      final fg = await Permission.locationWhenInUse.isGranted;
      final bg = await Permission.locationAlways.isGranted;
      final notif = await Permission.notification.isGranted;
      final ignoring =
          await BatteryOptimizationService.isIgnoringBatteryOptimizations();

      if (!mounted) return;
      setState(() {
        _native = diag;
        _locFg = fg;
        _locBg = bg;
        _notifPerm = notif;
        _batteryIgnored = ignoring;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _native = {'error': e.toString()};
      });
    }
  }

  String _mask(String s) {
    final i = s.indexOf('token=');
    if (i < 0) return s;
    final end = s.indexOf('&', i + 6);
    return s.replaceRange(i + 6, end < 0 ? s.length : end, '***');
  }

  @override
  Widget build(BuildContext context) {
    final lastHbMs = (_native['lastHeartbeatMs'] ?? 0) as int;
    final lastHb = lastHbMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastHbMs).toLocal().toString()
        : '—';
    final running = _native['running'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Config', [
              _row('Base API', _native['baseApi'] ?? '—'),
              _row('WS URL', _mask((_native['wsUrl'] ?? '') as String)),
              _row('Driver ID', _native['driverId'] ?? '—'),
              _row('Driver Name', _native['driverName'] ?? '—'),
              _row('Vehicle Plate', _native['vehiclePlate'] ?? '—'),
            ]),
            const SizedBox(height: 12),
            _section('Service', [
              _row('Running', running ? 'Yes' : 'No'),
              _row('Last Heartbeat', lastHb),
            ]),
            const SizedBox(height: 12),
            _section('Permissions', [
              _row('Location (While Using)', _locFg ? 'Granted' : 'Denied'),
              _row('Background Location', _locBg ? 'Granted' : 'Denied'),
              _row('Notifications', _notifPerm ? 'Granted' : 'Denied'),
            ]),
            const SizedBox(height: 12),
            _section('Battery Optimization', [
              _row('Ignoring Optimizations', _batteryIgnored ? 'Yes' : 'No'),
            ]),
            const SizedBox(height: 12),
            _section('Notification Channels', [
              _row('Alerts (sv_driver_alerts)',
                  _native['hasAlertsChannel'] == true ? 'Present' : 'Missing'),
              _row('Updates (sv_driver_notifications)',
                  _native['hasUpdatesChannel'] == true ? 'Present' : 'Missing'),
              _row('App Notifications Enabled',
                  _native['notifEnabled'] == true ? 'Yes' : 'No'),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.permissions),
                  icon: const Icon(Icons.security),
                  label: const Text('Fix Permissions'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ...children,
            ],
          ),
        ),
      );

  Widget _row(String k, Object? v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(k)),
            const SizedBox(width: 12),
            Flexible(
                child: Text(v?.toString() ?? '—', textAlign: TextAlign.right)),
          ],
        ),
      );
}
