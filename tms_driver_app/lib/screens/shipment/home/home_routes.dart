import 'package:tms_driver_app/routes/app_routes.dart';

class HomeRoutes {
  static const String navHome = 'home';
  static const String navTrips = 'trips';
  static const String navSupport = 'support';
  static const String navMore = 'more';

  static String? bottomNavRoute(int index) {
    switch (index) {
      case 1:
        return AppRoutes.trips;
      case 2:
        return AppRoutes.reportIssueList;
      case 3:
        return AppRoutes.profile;
      case 4:
        return AppRoutes.settings;
      default:
        return null;
    }
  }

  static String? bottomNavRouteById(String navId) {
    switch (navId) {
      case navTrips:
        return AppRoutes.trips;
      case navSupport:
        return AppRoutes.help;
      case navMore:
        return AppRoutes.settings;
      default:
        return null;
    }
  }

  static String? quickActionRoute(String actionId) {
    switch (actionId) {
      case 'my_trips':
        return AppRoutes.trips;
      case 'incident_report':
        return AppRoutes.incidentReport;
      case 'report_issue':
        return AppRoutes.reportIssueList;
      case 'documents':
        return AppRoutes.documents;
      case 'daily_summary':
        return AppRoutes.dailySummary;
      case 'trip_report':
        return AppRoutes.tripReport;
      case 'more':
        return AppRoutes.settings;
      case 'help_center':
        return AppRoutes.help;
      default:
        return null;
    }
  }
}
