import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'services/generated_api_service.dart';
import 'services/api_service.dart';
import 'services/local_storage.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/shipments/shipments_screen.dart';
import 'screens/orders/order_screen.dart';
import 'screens/incidents/incidents_screen.dart';
import 'screens/bookings/bookings_screen.dart';
import 'screens/bookings/create_booking_screen.dart';
import 'screens/bookings/booking_detail_screen.dart';
import 'screens/admin/admin_orders_screen.dart';
import 'screens/bookings/drafts_screen.dart';
import 'providers/bookings_provider.dart';
import 'models/booking.dart';
import 'screens/tracking/tracking_screen.dart';
import 'screens/about/about_screen.dart';
import 'screens/articles/articles_screen.dart';
import 'screens/articles/article_detail_screen.dart';
import 'screens/contact/contact_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/create_order_screen.dart';
import 'constants/colors.dart';
import 'routes/app_routes.dart';

Widget createApp({
  String apiBaseUrl = 'http://localhost:8080',
  LocalStorage? storage,
  AuthService? authService,
  NotificationService? notificationService,
}) {
  final apiService = GeneratedApiService(basePath: apiBaseUrl);
  final localStorage = storage ?? LocalStorage();
  final localAuthService = authService ?? AuthService(storage: localStorage);
  apiService.setAuthService(localAuthService);
  final notifService = notificationService ?? NotificationService();

  final authProvider = AuthProvider(authService: localAuthService);
  final userProvider = UserProvider();
  // If authService already has a restored user with a customerId, initialize
  // the `UserProvider` so screens using it (orders/create) work immediately.
  try {
    final cId = localAuthService.currentUser?.customerId;
    if (cId != null) {
      userProvider.setCustomerId(cId);
    }
  } catch (_) {}
  final notificationProvider = NotificationProvider(
    authService: localAuthService,
    baseUrl: apiBaseUrl,
  );

  // BookingsProvider will be created by Provider using `create`

  return MultiProvider(
    providers: [
      Provider<GeneratedApiService>.value(value: apiService),
      Provider<LocalStorage>.value(value: localStorage),
      ChangeNotifierProvider<AuthService>.value(value: localAuthService),
      Provider<NotificationService>.value(value: notifService),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ChangeNotifierProvider<NotificationProvider>.value(
        value: notificationProvider,
      ),
      ChangeNotifierProvider<BookingsProvider>(
        create: (_) => BookingsProvider(
            storage: localStorage,
            apiService: apiService,
            authProvider: authProvider),
      ),
    ],
    child: Builder(
      builder: (context) => MaterialApp(
        title: 'SV-TMS Customer',

        // SV Brand Theme
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.secondary,
            onSecondary: Colors.white,
            error: AppColors.danger,
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,

        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.home: (_) => const HomeScreen(),
          AppRoutes.profile: (_) => const ProfileScreen(),
          AppRoutes.shipments: (_) => const ShipmentsScreen(),
          AppRoutes.orders: (_) => const OrderScreen(),
          AppRoutes.incidents: (_) => const IncidentsScreen(),
          AppRoutes.bookings: (_) => const BookingsScreen(),
          AppRoutes.bookingDrafts: (_) => const DraftsScreen(),
          AppRoutes.tracking: (_) => const TrackingScreen(),
          AppRoutes.contact: (_) => const ContactScreen(),
          AppRoutes.articles: (_) => const ArticlesScreen(),
          AppRoutes.settings: (_) => const SettingsScreen(),
          AppRoutes.adminOrders: (_) => const AdminOrdersScreen(),
          AppRoutes.bookingCreate: (_) => const CreateBookingScreen(),
          AppRoutes.createOrder: (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments;
            int? customerId;
            if (args is Map<String, dynamic> && args['customerId'] is int) {
              customerId = args['customerId'] as int;
            }
            if (customerId == null) {
              final up = Provider.of<UserProvider>(ctx, listen: false);
              customerId = up.customerId;
            }
            if (customerId != null) {
              return CreateOrderScreen(customerId: customerId);
            }
            return const Scaffold(
                body: Center(child: Text('customer_not_found')));
          },
          AppRoutes.bookingDetail: (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments;
            if (args is Map<String, dynamic> && args['booking'] != null) {
              return BookingDetailScreen(booking: args['booking'] as Booking);
            }
            return const Scaffold(
                body: Center(child: Text('booking_not_found')));
          },
          '/article-detail': (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments;
            if (args is Map<String, dynamic> && args['article'] != null) {
              return ArticleDetailScreen(
                article: args['article'] as Map<String, dynamic>,
              );
            }
            if (args is Map<String, dynamic> && args['index'] is int) {
              final index = args['index'] as int;
              final title = 'article_${index + 1}_title'.tr();
              final summary = 'article_${index + 1}_summary'.tr();
              return ArticleDetailScreen(
                article: {
                  'title': title,
                  'summary': summary,
                  'content': '',
                },
              );
            }
            return const ArticleDetailScreen(
              article: {'title': '', 'summary': '', 'content': ''},
            );
          },
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
          AppRoutes.changePassword: (_) => const ChangePasswordScreen(),
          AppRoutes.about: (_) => const AboutScreen(),
          // Account consolidated into profile
        },

        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    ),
  );
}
