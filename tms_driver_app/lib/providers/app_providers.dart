import 'package:provider/provider.dart';
import 'package:tms_driver_app/core/di/service_locator.dart';
import 'package:tms_driver_app/providers/auth_provider.dart';
import 'package:tms_driver_app/providers/contact_provider.dart';
import 'package:tms_driver_app/providers/dashboard_kpi_provider.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/providers/driver_issue_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/providers/notification_provider.dart';
import 'package:tms_driver_app/providers/safety_provider.dart';
import 'package:tms_driver_app/providers/settings_provider.dart';
import 'package:tms_driver_app/providers/sign_in_provider.dart';
import 'package:tms_driver_app/providers/theme_provider.dart';
import 'package:tms_driver_app/providers/user_provider.dart';

class AppProviders {
  static final List<ChangeNotifierProvider> all = [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => SettingsProvider()),
    ChangeNotifierProvider(create: (_) => ContactProvider()),
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => SignInProvider()),
    ChangeNotifierProvider(create: (_) => DriverProvider()),
    // Use service locator for DispatchProvider to match main.dart and DI setup
    ChangeNotifierProvider(create: (_) => sl<DispatchProvider>()),
    ChangeNotifierProvider(create: (_) => DashboardKpiProvider()),
    ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ChangeNotifierProvider(create: (_) => DriverIssueProvider()),
    ChangeNotifierProvider(create: (_) => SafetyProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ];
}
