import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/screens/vehicle/my_vehicle_screen.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/providers/maintenance_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyVehicleScreen displays assignment from provider', (WidgetTester tester) async {
    // Mock assignment and vehicle data
    final mockAssignment = {
      'effectiveType': 'Permanent',
      'effectiveVehicle': {
        'licensePlate': '1AB-2345',
        'type': 'Truck',
        'status': 'ACTIVE',
        'fuelType': 'Diesel',
        'engineNumber': 'ENG12345',
      },
      'assignedAt': '2026-03-18T08:00:00Z',
    };

    final mockDriverProvider = DriverProvider();
    mockDriverProvider.currentAssignment = mockAssignment;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DriverProvider>.value(value: mockDriverProvider),
          ChangeNotifierProvider<MaintenanceProvider>(create: (_) => MaintenanceProvider()),
        ],
        child: const MaterialApp(
          home: MyVehicleScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check for assignment summary
    expect(find.textContaining('Assignment: Permanent'), findsOneWidget);
    expect(find.textContaining('1AB-2345'), findsWidgets);
    expect(find.text('My Vehicle'), findsWidgets);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Truck'), findsOneWidget);
    expect(find.text('Assigned To'), findsOneWidget);
    expect(find.textContaining('អ្នកបើកបរ'), findsOneWidget);
  });
}
