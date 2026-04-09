import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tms_driver_app/routes/app_routes.dart';

import '../../providers/driver_provider.dart';
import '../../providers/maintenance_provider.dart';
import 'incident_report_screen.dart';

class MyVehicleScreen extends StatefulWidget {
  const MyVehicleScreen({super.key});

  @override
  State<MyVehicleScreen> createState() => _MyVehicleScreenState();
}

class _MyVehicleScreenState extends State<MyVehicleScreen> {
  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.loadLoggedInDriverId();
    await driverProvider.fetchDriverProfile();
    await driverProvider.fetchCurrentAssignment();
  }

  Future<void> _refreshData() async {
    await _loadVehicleData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle data refreshed'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isLoading, {String? error}) {
    if (isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading vehicle info...', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    final errorMessage = _humanizeError(error);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          errorMessage == null ? 'No Vehicle Assigned' : 'Unable to load vehicle',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          errorMessage ?? 'You don\'t have a vehicle assigned yet',
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _refreshData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563eb),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  String? _humanizeError(String? error) {
    if (error == null || error.isEmpty) return null;
    if (error.startsWith('server_')) {
      return 'Server error (${error.split('_').last}). Please try again later.';
    }
    switch (error) {
      case 'forbidden':
        return 'Access denied. Please check your login and permissions.';
      case 'missing_auth_headers':
        return 'Not authenticated. Please log in again.';
      case 'no_internet':
        return 'No internet connection. Check your network and try again.';
      case 'timeout':
        return 'Request timed out. Please try again.';
      case 'not_found':
        return 'No driver record found. Please check your account.';
      default:
        return error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f7fc),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563eb),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Vehicle',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            final nav = Navigator.of(context);
            if (nav.canPop()) {
              nav.pop();
            } else {
              nav.pushReplacementNamed(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: Consumer<DriverProvider>(
        builder: (context, driverProvider, child) {
          var vehicle = driverProvider.vehicleCardData;
          final assignment = driverProvider.currentAssignment;
          // If vehicleCardData is empty but we have an effectiveVehicle from
          // the current assignment, prefer that so the UI shows API data.
          if ((vehicle == null || vehicle.isEmpty) &&
              driverProvider.effectiveVehicle != null) {
            vehicle =
                Map<String, dynamic>.from(driverProvider.effectiveVehicle!);
          }
          final isLoading = driverProvider.isLoadingCurrentAssignment;

          if (vehicle == null || vehicle.isEmpty) {
            final error = driverProvider.assignmentError ?? driverProvider.lastProfileFetchError;
            return RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: Center(child: _buildEmptyState(isLoading, error: error)),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'My Vehicle',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ព័ត៌មាន និងស្ថានភាពយានយន្តរបស់អ្នក',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildVehicleInfoCard(
                          vehicle, assignment, driverProvider),
                      // Quick assignment summary for debugging and clarity
                      if (assignment != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFeef2ff),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.assignment_turned_in,
                                  color: Color(0xFF2563eb)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Assignment: ${assignment['effectiveType'] ?? ''} — ${((assignment['effectiveVehicle'] ?? {})['licensePlate']) ?? ((assignment['permanentVehicle'] ?? {})['licensePlate']) ?? 'N/A'}',
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF333333)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildMaintenanceCard(vehicle),
                      const SizedBox(height: 18),
                      _buildDocumentExpiryCard(vehicle),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleInfoCard(Map<String, dynamic> vehicle,
      Map<String, dynamic>? assignment, DriverProvider provider) {
    final licensePlate = _vehiclePlate(vehicle);
    final status = _safeText(vehicle['status'], fallback: 'AVAILABLE');
    final vehicleType = _safeText(
      vehicle['type'] ?? vehicle['vehicleType'],
      fallback: 'Truck',
    );
    final fuelType = _safeText(vehicle['fuelType'], fallback: 'N/A');
    final engineNumber = _safeText(
      vehicle['engineNumber'] ?? vehicle['engineNo'],
      fallback: 'N/A',
    );
    final driverName =
        _resolveAssignedDriverName(vehicle, assignment, provider);
    final assignedDateRaw = _resolveAssignedDate(vehicle, assignment);
    final assignedDate = _formatDate(assignedDateRaw);

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Code for Vehicle
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFe9ecf3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: 'VEHICLE:$licensePlate',
                    version: QrVersions.auto,
                    size: 140,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    embeddedImage:
                        const AssetImage('assets/icons/app_icon.png'),
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(30, 30),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // License Plate & Status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    licensePlate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Vehicle Info Section
            const SizedBox(height: 14),
            _buildSectionTitle('Vehicle Info'),
            const SizedBox(height: 8),
            _buildInfoRow('Type', vehicleType),
            _buildInfoRow('Fuel', fuelType),
            _buildInfoRow('Engine No.', engineNumber),

            // Assignment Section
            const SizedBox(height: 14),
            _buildSectionTitle('Assignment'),
            const SizedBox(height: 8),
            _buildInfoRow('Assigned To', 'អ្នកបើកបរ: $driverName'),
            _buildInfoRow('Assigned Date', assignedDate),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard(Map<String, dynamic> vehicle) {
    final maintenanceStatus = _safeText(
      vehicle['maintenanceStatus'],
      fallback: 'N/A',
    );
    final annualInspection = _formatDate(
      vehicle['annualInspectionAt'] ?? vehicle['inspectionAt'],
    );
    final nextPreventiveCheck = _formatDate(
      vehicle['preventiveCheckAt'] ?? vehicle['nextPreventiveCheckAt'],
    );
    final fatsRemaining = _safeText(
      vehicle['fatsRemainingKm'] ?? vehicle['remainingMaintenanceKm'],
      fallback: 'N/A',
    );
    final remainingOilDistance = _safeText(
      vehicle['oilRemainingKm'] ?? vehicle['remainingOilKm'],
      fallback: 'N/A',
    );

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Maintenance Status'),
            const SizedBox(height: 8),

            _buildInfoRow(
                'Last Service',
                _formatDate(
                    vehicle['lastServiceAt'] ?? vehicle['serviceDate'])),
            _buildInfoRow(
              'Estimate Complete',
              _formatDate(vehicle['nextServiceAt'] ?? vehicle['etaComplete']),
              valueColor: const Color(0xFF28a745),
              isBold: true,
            ),
            _buildInfoRow(
              'Status',
              maintenanceStatus,
              valueColor:
                  maintenanceStatus == 'N/A' ? null : const Color(0xFF28a745),
              isBold: maintenanceStatus != 'N/A',
            ),

            // Preventive Maintenance
            const SizedBox(height: 14),
            _buildSectionTitle('Preventive Maintenance'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Annual Inspection',
              annualInspection,
              valueColor:
                  annualInspection == 'N/A' ? null : const Color(0xFF28a745),
              isBold: annualInspection != 'N/A',
            ),
            _buildInfoRow('Next Preventive Check', nextPreventiveCheck),
            _buildInfoRow(
              'FATS Remaining',
              fatsRemaining,
              valueColor:
                  fatsRemaining == 'N/A' ? null : const Color(0xFFf0ad4e),
              isBold: fatsRemaining != 'N/A',
            ),

            // Engine Oil Status
            const SizedBox(height: 14),
            _buildSectionTitle('Engine Oil Status'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Remaining Distance',
              remainingOilDistance,
              valueColor: remainingOilDistance == 'N/A'
                  ? null
                  : const Color(0xFFf0ad4e),
              isBold: remainingOilDistance != 'N/A',
            ),

            const SizedBox(height: 4),

            // Action Buttons
            _buildActionButton('🚨 Report Issue', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IncidentReportScreen(),
                ),
              );
            }),

            // Maintenance tasks navigation
            Consumer<MaintenanceProvider>(
              builder: (ctx, mp, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _buildActionButton(
                    '🔧 View Maintenance Tasks',
                    () {
                      mp.fetchTasks();
                      Navigator.pushNamed(ctx, AppRoutes.maintenanceList);
                    },
                  ),
                  if (mp.overdueCount > 0) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${mp.overdueCount} overdue task${mp.overdueCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentExpiryCard(Map<String, dynamic> vehicle) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Document Expiry'),
            const SizedBox(height: 8),
            _buildInfoRow(
                'Insurance',
                _formatDate(
                    vehicle['insuranceExpiry'] ?? vehicle['insuranceAt'])),
            _buildInfoRow(
              'Registration',
              _formatDate(
                  vehicle['registrationExpiry'] ?? vehicle['registrationAt']),
              valueColor: const Color(0xFFf0ad4e),
              isBold: true,
            ),
            _buildInfoRow(
              'Road Permit',
              _formatDate(vehicle['permitExpiry'] ?? vehicle['roadPermitAt']),
              valueColor: const Color(0xFFd9534f),
              isBold: true,
            ),
            _buildInfoRow(
              'GPS Certificate',
              _formatDate(vehicle['gpsCertificateExpiry'] ??
                  vehicle['gpsCertificateAt']),
              valueColor: const Color(0xFF28a745),
              isBold: true,
            ),
            const SizedBox(height: 14),
            _buildActionButton('📄 View Documents', () {
              Navigator.pushNamed(context, '/documents');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFf1f3f8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _vehiclePlate(Map<String, dynamic> vehicle,
      {String fallback = 'N/A'}) {
    final raw = vehicle['licensePlate'] ??
        vehicle['plateNumber'] ??
        vehicle['truckNumber'] ??
        vehicle['vehiclePlate'] ??
        vehicle['plate'];
    final plate = (raw?.toString() ?? '').trim();
    if (plate.isEmpty) return fallback;
    return plate;
  }

  String _safeText(dynamic value, {String fallback = 'N/A'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  String _driverNameFromMap(Map<String, dynamic>? driver) {
    if (driver == null || driver.isEmpty) return '';
    final first = driver['firstName']?.toString().trim() ?? '';
    final last = driver['lastName']?.toString().trim() ?? '';
    final full = '$first $last'.trim();
    return [
      full,
      driver['name']?.toString().trim() ?? '',
      driver['displayName']?.toString().trim() ?? '',
      driver['fullName']?.toString().trim() ?? '',
      driver['username']?.toString().trim() ?? '',
    ].firstWhere((item) => item.isNotEmpty, orElse: () => '');
  }

  String _resolveAssignedDriverName(
    Map<String, dynamic> vehicle,
    Map<String, dynamic>? assignment,
    DriverProvider provider,
  ) {
    final relationDrivers =
        _asMapList(vehicle['vehicle_drivers'] ?? vehicle['vehicleDrivers']);
    if (relationDrivers.isNotEmpty) {
      final active = relationDrivers.firstWhere(
        (entry) =>
            entry['endedAt'] == null &&
            entry['endDate'] == null &&
            entry['inactiveAt'] == null,
        orElse: () => relationDrivers.first,
      );
      final relationDriver = _asMap(active['driver']);
      final relationName = _driverNameFromMap(relationDriver);
      if (relationName.isNotEmpty) return relationName;
    }

    final assignedDriver =
        _driverNameFromMap(_asMap(vehicle['assignedDriver']));
    if (assignedDriver.isNotEmpty) return assignedDriver;

    final assignmentDriver = _driverNameFromMap(
        _asMap(assignment?['driver'] ?? assignment?['assignedDriver']));
    if (assignmentDriver.isNotEmpty) return assignmentDriver;

    final profileName = _driverNameFromMap(provider.driverProfile);
    return profileName.isEmpty ? 'N/A' : profileName;
  }

  dynamic _resolveAssignedDate(
    Map<String, dynamic> vehicle,
    Map<String, dynamic>? assignment,
  ) {
    final relationDrivers =
        _asMapList(vehicle['vehicle_drivers'] ?? vehicle['vehicleDrivers']);
    if (relationDrivers.isNotEmpty) {
      final active = relationDrivers.firstWhere(
        (entry) =>
            entry['endedAt'] == null &&
            entry['endDate'] == null &&
            entry['inactiveAt'] == null,
        orElse: () => relationDrivers.first,
      );
      final date = active['assignedAt'] ??
          active['startDate'] ??
          active['createdAt'] ??
          active['effectiveFrom'];
      if (date != null) return date;
    }

    return vehicle['assignedAt'] ??
        assignment?['assignedAt'] ??
        assignment?['createdAt'] ??
        assignment?['startTime'];
  }

  /// Get color for vehicle status badge
  ///
  /// Vehicle Status Enum (matches backend VehicleStatus):
  /// - ACTIVE: Ready for assignment (Green)
  /// - UNDER_REPAIR: Work order in progress (Orange)
  /// - SAFETY_HOLD: Critical safety issue (Red)
  /// - RETIRED: Removed from fleet (Gray)
  /// - IN_ISSUE: Legal/Issue hold (Red)
  /// - AVAILABLE: Ready for assignment (Green)
  /// - IN_USE: Currently assigned to a driver/route (Blue)
  /// - MAINTENANCE: Under repair or scheduled service (Orange)
  /// - OUT_OF_SERVICE: Not operational, requires major repair (Red)
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'AVAILABLE':
        return const Color(0xFF16a34a); // Green - Ready for assignment
      case 'IN_USE':
        return const Color(0xFF2563eb); // Blue - Currently assigned/active
      case 'UNDER_REPAIR':
      case 'MAINTENANCE':
        return const Color(0xFFd97706); // Orange - Under repair/service
      case 'SAFETY_HOLD':
      case 'IN_ISSUE':
      case 'OUT_OF_SERVICE':
        return const Color(0xFFdc2626); // Red - Not operational
      case 'RETIRED':
        return const Color(0xFF6b7280); // Gray - Retired
      default:
        return const Color(0xFF6b7280); // Gray - Unknown status
    }
  }

  /// Get display text for vehicle status
  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'UNDER_REPAIR':
        return 'Under Repair';
      case 'SAFETY_HOLD':
        return 'Safety Hold';
      case 'IN_ISSUE':
        return 'In Issue';
      case 'RETIRED':
        return 'Retired';
      case 'AVAILABLE':
        return 'Available';
      case 'IN_USE':
        return 'In Use';
      case 'MAINTENANCE':
        return 'Maintenance';
      case 'OUT_OF_SERVICE':
        return 'Out of Service';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  DateTime? _parseToDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is int) {
      // Some APIs return seconds, others return milliseconds
      final ms = value < 1000000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      // Numeric string as epoch
      final intValue = int.tryParse(trimmed);
      if (intValue != null) {
        final ms = intValue < 1000000000000 ? intValue * 1000 : intValue;
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }

      // ISO 8601 or other parseable formats
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) return parsed;

      // Fallback to common manual patterns
      const formats = [
        'yyyy-MM-dd',
        'yyyy/MM/dd',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'dd-MM-yyyy',
        'yyyy-MM-dd HH:mm:ss',
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
      ];
      for (final pattern in formats) {
        try {
          return DateFormat(pattern).parseLoose(trimmed);
        } catch (_) {
          // ignore
        }
      }

      return null;
    }

    if (value is List) {
      if (value.isEmpty) return null;
      final nums = value
          .take(6)
          .map((v) => int.tryParse(v?.toString() ?? ''))
          .toList(growable: false);
      if (nums.length < 3 || nums[0] == null || nums[1] == null || nums[2] == null) {
        return null;
      }
      try {
        return DateTime(
          nums[0]!,
          nums[1]!,
          nums[2]!,
          nums.length > 3 && nums[3] != null ? nums[3]! : 0,
          nums.length > 4 && nums[4] != null ? nums[4]! : 0,
          nums.length > 5 && nums[5] != null ? nums[5]! : 0,
        );
      } catch (_) {
        return null;
      }
    }

    final map = _asMap(value);
    if (map != null && map.isNotEmpty) {
      final keys = [
        'millisecondsSinceEpoch',
        'epochMs',
        'epochMilliseconds',
        'timestamp',
        'epochSeconds',
        'seconds',
        'ms',
      ];
      for (final key in keys) {
        if (!map.containsKey(key)) continue;
        final v = map[key];
        if (v == null) continue;
        final intValue = v is int ? v : int.tryParse(v.toString());
        if (intValue == null) continue;

        if (key == 'epochSeconds' || key == 'seconds') {
          return DateTime.fromMillisecondsSinceEpoch(intValue * 1000);
        }

        final ms = intValue < 1000000000000 ? intValue * 1000 : intValue;
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }

    return null;
  }

  String _formatDate(dynamic value) {
    final dt = _parseToDateTime(value);
    if (dt == null) return 'N/A';
    return DateFormat('yyyy-MM-dd').format(dt);
  }
}
