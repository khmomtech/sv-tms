import 'package:flutter/material.dart';
import 'package:tms_driver_app/features/settings/screens/biometric_settings_screen.dart';
import 'package:tms_driver_app/features/settings/screens/privacy_settings_screen.dart';
import 'package:tms_driver_app/screens/auth/change_password_screen.dart';
import 'package:tms_driver_app/screens/auth/sign_in_screen.dart';
import 'package:tms_driver_app/screens/auth/register_screen.dart';
import 'package:tms_driver_app/screens/core/diagnostics_screen.dart';
import 'package:tms_driver_app/screens/core/permissions_screen.dart';
import 'package:tms_driver_app/screens/core/route_map_screen.dart';
import 'package:tms_driver_app/screens/core/settings_screen.dart';
import 'package:tms_driver_app/screens/core/splash_screen.dart';
import 'package:tms_driver_app/screens/notifications/notifications_screen.dart';
import 'package:tms_driver_app/screens/shipment/about_screen.dart';
import 'package:tms_driver_app/screens/shipment/driver_id_screen.dart';
import 'package:tms_driver_app/screens/shipment/help_center_screen.dart';
import 'package:tms_driver_app/screens/shipment/daily_summary_screen.dart';
import 'package:tms_driver_app/screens/shipment/home_screen.dart';
import 'package:tms_driver_app/screens/shipment/issue_form_screen.dart';
import 'package:tms_driver_app/screens/shipment/issue_list_screen.dart';
import 'package:tms_driver_app/screens/shipment/load_screen.dart';
import 'package:tms_driver_app/screens/shipment/location_log_viewer_screen.dart';
import 'package:tms_driver_app/screens/shipment/profile_screen_modern.dart';
import 'package:tms_driver_app/screens/shipment/report_screen.dart';
import 'package:tms_driver_app/screens/shipment/trip_detail_screen.dart';
import 'package:tms_driver_app/screens/shipment/trips_screen.dart';
import 'package:tms_driver_app/screens/shipment/unload_screen.dart';
import 'package:tms_driver_app/screens/vehicle/my_vehicle_screen.dart';
import 'package:tms_driver_app/screens/shipment/trip_report_screen.dart';
import 'package:tms_driver_app/screens/shipment/banner_article_screen.dart';
import 'package:tms_driver_app/screens/vehicle/incident_report_screen.dart';
import 'package:tms_driver_app/screens/vehicle/incident_report_list_screen.dart';
import 'package:tms_driver_app/screens/vehicle/incident_report_detail_screen.dart';
import 'package:tms_driver_app/screens/vehicle/incident_report_edit_screen.dart';
import 'package:tms_driver_app/screens/safety/driver_safety_check_screen.dart';
import 'package:tms_driver_app/screens/safety/safety_history_screen.dart';
import 'package:tms_driver_app/screens/safety/safety_detail_screen.dart';
import 'package:tms_driver_app/models/safety_check_model.dart';
import 'package:tms_driver_app/screens/maintenance/maintenance_list_screen.dart';
import 'package:tms_driver_app/screens/maintenance/create_maintenance_request_screen.dart';
import 'package:tms_driver_app/screens/messages/incoming_call_screen.dart';
import 'package:tms_driver_app/screens/messages/messages_inbox_screen.dart';
import 'package:tms_driver_app/screens/messages/messages_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String signin = '/signin';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String documents = '/documents';
  static const String messages = '/messages';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String changePassword = '/change-password';
  static const String settings = '/settings';
  static const String reportIssue = '/report-issue';
  static const String reportIssueList = '/report-issue-list';
  static const String reports = '/reports';
  static const String help = '/help';
  static const String about = '/about';
  static const String taskDetail = '/task-detail';
  static const String load = '/load';
  static const String driverMap = '/driver-map';
  static const String dispatchDetail = '/dispatchDetail';
  static const String loadTaskDetail = '/loadTaskDetail';
  static const String unloadTaskDetail = '/unloadTaskDetail';
  static const String locationLogs = '/location-logs';
  static const String permissions = '/permissions';
  static const String diagnostics = '/diagnostics';
  static const String trips = '/trips';
  static const String tripReport = '/trip-report';
  static const String bannerArticle = '/banner-article';
  static const String myVehicle = '/my-vehicle';
  static const String incidentReport = '/incident-report';
  static const String incidentReportList = '/incident-report-list';
  static const String incidentReportDetail = '/incident-report-detail';
  static const String incidentReportEdit = '/incident-report-edit';
  static const String myIdCard = '/my-id-card';
  static const String dailySummary = '/daily-summary';
  static const String privacySettings = '/privacy-settings';
  static const String biometricSettings = '/biometric-settings';
  static const String termsOfService = '/terms-of-service';
  static const String safetyCheck = '/safety-check';
  static const String safetyHistory = '/safety-history';
  static const String safetyDetail = '/safety-detail';
  static const String maintenanceList = '/maintenance-list';
  static const String maintenanceCreate = '/maintenance-create';
  static const String messagesChat = '/messages/chat';
  static const String incomingCall = '/incoming-call';
}

class IncomingCallRouteArgs {
  final String channelName;
  final String callerName;
  final int? sessionId;
  final int? driverId;

  const IncomingCallRouteArgs({
    required this.channelName,
    required this.callerName,
    this.sessionId,
    this.driverId,
  });
}

class ChatRouteArgs {
  final String? entryPoint;
  final String? initialDraft;

  const ChatRouteArgs({
    this.entryPoint,
    this.initialDraft,
  });
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.signin:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());
      case AppRoutes.messages:
        return MaterialPageRoute(builder: (_) => const MessagesInboxScreen());
      case AppRoutes.messagesChat:
        final chatArgs = args is ChatRouteArgs ? args : null;
        return MaterialPageRoute(
          builder: (_) => MessagesScreen(
            entryPoint: chatArgs?.entryPoint,
            initialDraft: chatArgs?.initialDraft,
          ),
        );
      case AppRoutes.incomingCall:
        // args: IncomingCallRouteArgs { channelName, callerName }
        final callArgs = args is IncomingCallRouteArgs ? args : null;
        return MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const IncomingCallScreen(),
          settings: RouteSettings(
            name: AppRoutes.incomingCall,
            arguments: callArgs,
          ),
        );
      case AppRoutes.documents:
        // Documents entry points currently resolve to driver ID/document card view.
        return MaterialPageRoute(builder: (_) => const DriverIdScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreenModern());
      case AppRoutes.changePassword:
        return MaterialPageRoute(builder: (_) => ChangePasswordScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingScreen());
      case AppRoutes.dailySummary:
        return MaterialPageRoute(builder: (_) => const DailySummaryScreen());
      case AppRoutes.reportIssue:
        return MaterialPageRoute(builder: (_) => const IssueFormScreen());
      case AppRoutes.reportIssueList:
        return MaterialPageRoute(builder: (_) => IssueListScreen());
      case AppRoutes.reports:
        return MaterialPageRoute(builder: (_) => const ReportScreen());
      case AppRoutes.incidentReport:
        return MaterialPageRoute(builder: (_) => const IncidentReportScreen());
      case AppRoutes.incidentReportList:
        return MaterialPageRoute(
            builder: (_) => const IncidentReportListScreen());
      case AppRoutes.incidentReportDetail:
        if (args is Map<String, dynamic>) {
          final id = args['incidentId'] ?? args['issueId'] ?? args['id'];
          if (id is int || id is String) {
            final intId = id is int ? id : int.tryParse(id) ?? 0;
            if (intId > 0) {
              return MaterialPageRoute(
                  builder: (_) =>
                      IncidentReportDetailScreen(incidentId: intId));
            }
          }
        }
        return _errorRoute(message: 'Missing incident id');
      case AppRoutes.incidentReportEdit:
        if (args is Map<String, dynamic>) {
          final id = args['incidentId'] ?? args['issueId'] ?? args['id'];
          if (id is int || id is String) {
            final intId = id is int ? id : int.tryParse(id) ?? 0;
            if (intId > 0) {
              return MaterialPageRoute(
                  builder: (_) => IncidentReportEditScreen(incidentId: intId));
            }
          }
        }
        return _errorRoute(message: 'Missing incident id');
      case AppRoutes.help:
        return MaterialPageRoute(builder: (_) => const HelpCenterScreen());
      case AppRoutes.about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      case AppRoutes.taskDetail:
        return _errorRoute(message: 'Task detail moved to dispatch flow.');
      case AppRoutes.load:
        return _errorRoute(message: 'Use the load task detail route instead.');
      case AppRoutes.driverMap:
        if (args is Map<String, dynamic>) {
          if (args.containsKey('pickup') && args.containsKey('dropoff')) {
            return MaterialPageRoute(
              builder: (_) => RouteMapScreen(
                  pickup: args['pickup'], dropoff: args['dropoff']),
            );
          }
        }
        return _errorRoute();
      case AppRoutes.dispatchDetail:
        if (args is Map<String, dynamic>) {
          final id = args['dispatchId']?.toString();
          if (id != null && id.isNotEmpty) {
            return MaterialPageRoute(
                builder: (_) => DispatchDetailScreen(dispatchId: id));
          }
        }
        return _errorRoute(message: 'Missing dispatch ID');
      case AppRoutes.loadTaskDetail:
        if (args is Map<String, dynamic>) {
          final dispatchId = args['dispatchId'];
          if (dispatchId != null &&
              (dispatchId is String && dispatchId.isNotEmpty)) {
            return MaterialPageRoute(
                builder: (_) => LoadTaskDetailScreen(dispatchId: dispatchId));
          }
        }
        return _errorRoute(message: 'Missing dispatch ID');
      case AppRoutes.unloadTaskDetail:
        if (args is Map<String, dynamic>) {
          final id = args['dispatchId'];
          if (id != null) {
            return MaterialPageRoute(
                builder: (_) => UnloadScreen(dispatchId: id));
          }
        }
        return _errorRoute(message: 'Missing dispatch ID');
      case AppRoutes.locationLogs:
        return MaterialPageRoute(
            builder: (_) => const LocationLogViewerScreen());
      case AppRoutes.permissions:
        return MaterialPageRoute(builder: (_) => const PermissionsScreen());
      case AppRoutes.diagnostics:
        return MaterialPageRoute(builder: (_) => const DiagnosticsScreen());
      case AppRoutes.trips:
        return MaterialPageRoute(builder: (_) => const TripsScreen());
      case AppRoutes.tripReport:
        return MaterialPageRoute(builder: (_) => const TripReportScreen());
      case AppRoutes.bannerArticle:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => BannerArticleScreen(
              id: args['id']?.toString(),
              url: args['url']?.toString(),
              title: args['title']?.toString(),
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const BannerArticleScreen());
      case AppRoutes.myVehicle:
        return MaterialPageRoute(builder: (_) => const MyVehicleScreen());
      case AppRoutes.myIdCard:
        return MaterialPageRoute(builder: (_) => const DriverIdScreen());
      case AppRoutes.privacySettings:
        return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
      case AppRoutes.biometricSettings:
        return MaterialPageRoute(
            builder: (_) => const BiometricSettingsScreen());
      case AppRoutes.safetyCheck:
        return MaterialPageRoute(
            builder: (_) => const DriverSafetyCheckScreen());
      case AppRoutes.safetyHistory:
        return MaterialPageRoute(builder: (_) => const SafetyHistoryScreen());
      case AppRoutes.safetyDetail:
        if (args is Map<String, dynamic> && args['safety'] is SafetyCheck) {
          return MaterialPageRoute(
            builder: (_) =>
                SafetyDetailScreen(safetyCheck: args['safety'] as SafetyCheck),
          );
        }
        return _errorRoute(message: 'Missing safety check detail');
      case AppRoutes.maintenanceList:
        return MaterialPageRoute(builder: (_) => const MaintenanceListScreen());
      case AppRoutes.maintenanceCreate:
        return MaterialPageRoute(
            builder: (_) => const CreateMaintenanceRequestScreen());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute({String message = 'Page not found'}) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
