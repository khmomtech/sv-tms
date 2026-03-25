// 📁 lib/core/di/service_locator.dart

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Error Handling
import 'package:tms_driver_app/core/errors/error_handler.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
// Core
import 'package:tms_driver_app/core/network/dio_client.dart';
import 'package:tms_driver_app/core/repositories/dispatch_repository.dart';
// Repositories
import 'package:tms_driver_app/core/repositories/driver_repository.dart';
import 'package:tms_driver_app/core/repositories/notification_repository.dart';
import 'package:tms_driver_app/providers/about_app_provider.dart';
import 'package:tms_driver_app/providers/auth_provider.dart';
import 'package:tms_driver_app/providers/contact_provider.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/providers/driver_issue_provider.dart';
// Providers
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/providers/notification_provider.dart';
import 'package:tms_driver_app/providers/settings_provider.dart';
import 'package:tms_driver_app/providers/sign_in_provider.dart';
import 'package:tms_driver_app/providers/theme_provider.dart';
import 'package:tms_driver_app/providers/user_provider.dart';
import 'package:tms_driver_app/services/assignment_service.dart';
import 'package:tms_driver_app/services/banner_service.dart';
import 'package:tms_driver_app/services/enhanced_firebase_messaging_service.dart';
import 'package:tms_driver_app/services/enhanced_websocket_manager.dart';
// Services
import 'package:tms_driver_app/services/location_service.dart';
import 'package:tms_driver_app/services/notification_action_handler.dart';
import 'package:tms_driver_app/services/session_manager.dart';
import 'package:tms_driver_app/services/version_service.dart';
import 'package:tms_driver_app/services/web_socket_service.dart';

/// Global service locator instance using get_it
///
/// This provides dependency injection throughout the app:
/// - Repositories for data access
/// - Services for business logic
/// - Providers for state management
/// - Singletons for shared instances
final GetIt sl = GetIt.instance;

/// Initialize all dependencies
///
/// Call this once in main() before runApp()
Future<void> setupServiceLocator() async {
  // ============================================================
  // External Dependencies (must be initialized first)
  // ============================================================

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // ============================================================
  // Core - Network Client
  // ============================================================

  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  // ============================================================
  // Core - Error Handling
  // ============================================================

  sl.registerLazySingleton<ErrorHandler>(() => ErrorHandler());

  // ============================================================
  // Repositories (Data Layer)
  // ============================================================

  sl.registerLazySingleton<DriverRepository>(
    () => DriverRepository(
      dio: sl<Dio>(),
      prefs: sl<SharedPreferences>(),
    ),
  );

  sl.registerLazySingleton<DispatchRepository>(
    () => DispatchRepository(
      dio: sl<Dio>(),
      prefs: sl<SharedPreferences>(),
    ),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(
      dio: sl<Dio>(),
      prefs: sl<SharedPreferences>(),
    ),
  );

  // ============================================================
  // Services (Business Logic Layer)
  // ============================================================

  // Singletons for services that should have single instance
  sl.registerSingleton<LocationService>(LocationService());
  sl.registerSingleton<WebSocketService>(WebSocketService.instance);
  sl.registerSingleton<SessionManager>(SessionManager.instance);

  // Lazy singletons for services that can be initialized on demand
  sl.registerLazySingleton<BannerService>(() => BannerService());
  sl.registerLazySingleton<VersionService>(() => VersionService(
        apiBaseUrl: ApiConstants.baseUrl,
      ));
  sl.registerLazySingleton<AssignmentService>(() => AssignmentService());

  // Enhanced services (also using factory constructors)
  sl.registerLazySingleton<EnhancedFirebaseMessagingService>(
    () => EnhancedFirebaseMessagingService(),
  );
  sl.registerLazySingleton<NotificationActionHandler>(
    () => NotificationActionHandler(),
  );
  sl.registerLazySingleton<EnhancedWebSocketManager>(
    () => EnhancedWebSocketManager(),
  );

  // ============================================================
  // Providers (State Management Layer)
  // ============================================================

  // Note: Providers are ChangeNotifiers and should be created fresh for each
  // MultiProvider tree. We use factory registration to allow multiple instances
  // if needed, but typically they'll be created once in the MultiProvider.

  sl.registerFactory<ThemeProvider>(() => ThemeProvider());
  sl.registerFactory<SettingsProvider>(() => SettingsProvider());
  sl.registerFactory<ContactProvider>(() => ContactProvider());
  sl.registerFactory<UserProvider>(() => UserProvider());
  sl.registerFactory<SignInProvider>(() => SignInProvider());

  // Providers with repository dependencies
  // TODO: Migrate these to use repositories when refactoring individual providers
  sl.registerFactory<DriverProvider>(() => DriverProvider());

  sl.registerFactory<DispatchProvider>(
    () => DispatchProvider(dispatchRepository: sl<DispatchRepository>()),
  );

  sl.registerFactory<NotificationProvider>(() => NotificationProvider());

  sl.registerFactory<DriverIssueProvider>(() => DriverIssueProvider());
  sl.registerFactory<AuthProvider>(() => AuthProvider());
  sl.registerFactory<AboutAppProvider>(() => AboutAppProvider());
}

/// Reset the service locator (useful for testing)
Future<void> resetServiceLocator() async {
  await sl.reset();
}

/// Helper function to get dependency
///
/// Example:
/// ```dart
/// final driverRepo = getIt<DriverRepository>();
/// ```
T getIt<T extends Object>() => sl<T>();
