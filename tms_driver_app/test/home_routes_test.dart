import 'package:flutter_test/flutter_test.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/screens/shipment/home/home_routes.dart';

void main() {
  group('HomeRoutes.bottomNavRoute', () {
    test('maps expected tab indices', () {
      expect(HomeRoutes.bottomNavRoute(0), isNull);
      expect(HomeRoutes.bottomNavRoute(1), AppRoutes.trips);
      expect(HomeRoutes.bottomNavRoute(2), AppRoutes.reportIssueList);
      expect(HomeRoutes.bottomNavRoute(3), AppRoutes.profile);
      expect(HomeRoutes.bottomNavRoute(4), AppRoutes.settings);
      expect(HomeRoutes.bottomNavRoute(99), isNull);
    });
  });

  group('HomeRoutes.quickActionRoute', () {
    test('maps supported quick actions', () {
      expect(HomeRoutes.quickActionRoute('my_trips'), AppRoutes.trips);
      expect(HomeRoutes.quickActionRoute('incident_report'),
          AppRoutes.incidentReport);
      expect(HomeRoutes.quickActionRoute('report_issue'),
          AppRoutes.reportIssueList);
      expect(HomeRoutes.quickActionRoute('documents'), AppRoutes.documents);
      expect(
          HomeRoutes.quickActionRoute('daily_summary'), AppRoutes.dailySummary);
      expect(HomeRoutes.quickActionRoute('trip_report'), AppRoutes.tripReport);
      expect(HomeRoutes.quickActionRoute('more'), AppRoutes.settings);
      expect(HomeRoutes.quickActionRoute('help_center'), AppRoutes.help);
      expect(HomeRoutes.quickActionRoute('unknown'), isNull);
    });
  });

  group('HomeRoutes.bottomNavRouteById', () {
    test('maps known nav ids', () {
        expect(HomeRoutes.bottomNavRouteById(HomeRoutes.navHome), isNull);
        expect(
          HomeRoutes.bottomNavRouteById(HomeRoutes.navTrips), AppRoutes.trips);
        expect(HomeRoutes.bottomNavRouteById(HomeRoutes.navSupport),
          AppRoutes.help);
        expect(HomeRoutes.bottomNavRouteById(HomeRoutes.navMore),
          AppRoutes.settings);
        expect(HomeRoutes.bottomNavRouteById('unknown'), isNull);
    });
  });
}
