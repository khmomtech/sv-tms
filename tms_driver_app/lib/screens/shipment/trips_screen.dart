import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/providers/driver_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
// removed unused imports

const Set<String> _knownDispatchStatusKeys = {
  'PLANNED',
  'PENDING',
  'ASSIGNED',
  'DRIVER_CONFIRMED',
  'APPROVED',
  'REJECTED',
  'SCHEDULED',
  'ARRIVED_LOADING',
  'LOADING',
  'LOADED',
  'SAFETY_PASSED',
  'SAFETY_FAILED',
  'IN_QUEUE',
  'IN_TRANSIT',
  'ARRIVED_UNLOADING',
  'UNLOADING',
  'UNLOADED',
  'DELIVERED',
  'COMPLETED',
  'CANCELLED',
};

// Top-level helpers for safety badge so they are always resolvable from widgets
Color safetyColorFor(String safety) {
  final s = safety.toUpperCase();
  if (s.contains('PASSED') || s.contains('SAFETY_PASSED'))
    return Colors.green.shade600;
  if (s.contains('FAILED') || s.contains('SAFETY_FAILED'))
    return Colors.orange.shade700;
  if (s.contains('SKIPPED') || s.contains('SAFETY_SKIPPED'))
    return Colors.grey.shade600;
  return Colors.grey;
}

IconData safetyIconFor(String safety) {
  final s = safety.toUpperCase();
  if (s.contains('PASSED') || s.contains('SAFETY_PASSED'))
    return Icons.verified;
  if (s.contains('FAILED') || s.contains('SAFETY_FAILED'))
    return Icons.error_outline;
  if (s.contains('SKIPPED') || s.contains('SAFETY_SKIPPED'))
    return Icons.remove_circle_outline;
  return Icons.info_outline;
}

String safetyLabelFor(String safety) {
  final s = safety.toUpperCase();
  if (s.contains('PASSED') || s.contains('SAFETY_PASSED'))
    return '${tr('trip.pre_entry_safety')}: ${tr('status.SAFETY_PASSED')}';
  if (s.contains('FAILED') || s.contains('SAFETY_FAILED'))
    return '${tr('trip.pre_entry_safety')}: ${tr('status.SAFETY_FAILED')}';
  if (s.contains('SKIPPED') || s.contains('SAFETY_SKIPPED'))
    return '${tr('trip.pre_entry_safety')}: ${tr('status.SAFETY_SKIPPED')}';
  return safety;
}

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  /// Utility to get status from a JSON map
  String getStatusFromJson(Map<String, dynamic> json) {
    return json['status']?.toString() ?? '';
  }

  /// Return an icon representing the dispatch status
  IconData _getStatusIcon(String statusKey) {
    switch (statusKey) {
      case 'DELIVERED':
        return Icons.check_circle_outline;
      case 'PENDING':
      case 'PLANNED':
      case 'SCHEDULED':
        return Icons.access_time;
      case 'IN_TRANSIT':
      case 'LOADED':
        return Icons.local_shipping_outlined;
      case 'ARRIVED_LOADING':
      case 'ARRIVED_UNLOADING':
        return Icons.location_on_outlined;
      case 'LOADING':
      case 'UNLOADING':
        return Icons.work_outline;
      case 'REJECTED':
      case 'CANCELLED':
        return Icons.cancel_outlined;
      case 'COMPLETED':
        return Icons.verified_outlined;
      case 'SAFETY_PASSED':
        return Icons.verified;
      case 'SAFETY_FAILED':
        return Icons.error_outline;
      case 'IN_QUEUE':
        return Icons.queue;
      default:
        return Icons.info_outline;
    }
  }

  String? _lastError;

  // -------- Date helpers (handle string / array / epoch) --------
  DateTime? _parseServerDate(dynamic raw) {
    try {
      if (raw == null) return null;

      // String: "2025-08-20 14:49" or ISO
      if (raw is String) {
        final s = raw.trim();
        if (s.isEmpty) return null;
        return DateTime.tryParse(
            s.contains('T') ? s : s.replaceFirst(' ', 'T'));
      }

      // Jackson array [y, m, d, H?, M?, S?]
      if (raw is List) {
        final list = raw.cast<num>();
        if (list.length >= 3) {
          final y = list[0].toInt();
          final m = list[1].toInt();
          final d = list[2].toInt();
          final hh = list.length > 3 ? list[3].toInt() : 0;
          final mm = list.length > 4 ? list[4].toInt() : 0;
          final ss = list.length > 5 ? list[5].toInt() : 0;
          return DateTime(y, m, d, hh, mm, ss);
        }
        return null;
      }

      // Epoch (ms)
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is double) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String formatServerDate(dynamic raw) {
    final dt = _parseServerDate(raw);
    if (dt == null) return tr('trip.invalid_date');
    final day = DateFormat('dd').format(dt);
    final months = tr('months').split(',');
    final monthName = (dt.month >= 1 && dt.month <= months.length)
        ? months[dt.month - 1].trim()
        : DateFormat.MMM().format(dt);
    return '$day $monthName ${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActive();
    });
  }

  Future<void> _loadActive() async {
    setState(() {
      _lastError = null;
    });
    try {
      final driverProvider =
          Provider.of<DriverProvider>(context, listen: false);
      final dispatchProvider =
          Provider.of<DispatchProvider>(context, listen: false);

      if (driverProvider.driverId != null) {
        await dispatchProvider.fetchPendingDispatches(
            driverId: driverProvider.driverId!);
        await dispatchProvider.fetchInProgressDispatches(
            driverId: driverProvider.driverId!);
      }
    } catch (e) {
      debugPrint('Error loading active dispatches: $e');
      setState(() => _lastError = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('error.data_load_failed'),
                style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final activeTitleKey = 'trip.active_title';
    final activeTitle = tr(activeTitleKey);
    final resolvedTitle =
        activeTitle == activeTitleKey ? 'Active Trips' : activeTitle;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(resolvedTitle, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _bodyActive(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _bodyActive() {
    return Consumer<DispatchProvider>(
      builder: (context, dispatchProvider, _) {
        final pending = dispatchProvider.pendingDispatches;
        final inProgress = dispatchProvider.inProgressDispatches;
        final isLoading = dispatchProvider.isLoadingPending ||
            dispatchProvider.isLoadingInProgress;

        // Merge active dispatches, keeping in-progress first
        List<Map<String, dynamic>> filtered = [
          ...inProgress,
          ...pending,
        ];
        filtered.sort((a, b) {
          final da = _parseServerDate(a['startTime']);
          final db = _parseServerDate(b['startTime']);
          if (db == null && da == null) return 0;
          if (db == null) return -1;
          if (da == null) return 1;
          return db.compareTo(da); // newest first
        });

        return RefreshIndicator(
          onRefresh: _loadActive,
          child: ListView(
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey('${filtered.length}_${_lastError ?? ''}'),
                    children: filtered.isEmpty
                        ? [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 32),
                              child: Column(
                                children: [
                                  Icon(Icons.local_shipping_outlined,
                                      size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 10),
                                  Text(
                                    _lastError == null
                                        ? tr('dispatch.empty_list')
                                        : tr('error.data_load_failed'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, '/trip-report');
                                    },
                                    child: Text(
                                      _completedMovedLabel(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: _loadActive,
                                    icon: const Icon(Icons.refresh),
                                    label: Text(tr('common.retry')),
                                  )
                                ],
                              ),
                            ),
                          ]
                        : filtered
                            .map((dispatch) => _buildDispatchCard(dispatch))
                            .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // For new stop format, use locationName/address fields
  String codeForStopCompat(dynamic stop) {
    if (stop == null) return '';
    if (stop is Map<String, dynamic>) {
      if (stop.containsKey('code')) return stop['code']?.toString() ?? '';
      if (stop.containsKey('locationName'))
        return stop['locationName']?.toString() ?? '';
    }
    return '';
  }

  String nameForStopCompat(dynamic stop) {
    if (stop == null) return '';
    if (stop is Map<String, dynamic>) {
      if (stop.containsKey('name')) return stop['name']?.toString() ?? '';
      if (stop.containsKey('address')) return stop['address']?.toString() ?? '';
    }
    return '';
  }

  // Helper to get location name from stop (supports both legacy and new formats)
  String locationNameForStop(dynamic stop) {
    if (stop == null) return '';
    if (stop is Map<String, dynamic>) {
      if (stop.containsKey('locationName'))
        return stop['locationName']?.toString() ?? '';
      if (stop.containsKey('address') &&
          stop['address'] is Map<String, dynamic>) {
        return stop['address']['locationName']?.toString() ?? '';
      }
    }
    return '';
  }

  Widget _buildDispatchCard(Map<String, dynamic> dispatch) {
    final pickupDate = formatServerDate(dispatch['startTime']);
    final statusColor = getStatusColor(dispatch['status'] ?? '');
    final dispatchId = dispatch['id'];

    // Prefer 'from' and 'to' fields from API, fallback to stops if missing
    final fromRaw = dispatch['from'];
    final toRaw = dispatch['to'];
    final customerRaw = dispatch['customer'];
    Map<String, dynamic>? from;
    Map<String, dynamic>? to;
    Map<String, dynamic>? customer;
    if (fromRaw is Map<String, dynamic>) {
      from = fromRaw;
    } else {
      from = null;
    }
    if (toRaw is Map<String, dynamic>) {
      to = toRaw;
    } else {
      to = null;
    }
    if (customerRaw is Map<String, dynamic>) {
      customer = customerRaw;
    } else {
      customer = null;
    }

    // Robust field access for origin, destination, customer
    String originCode =
        (from != null && from['name'] != null) ? from['name'].toString() : '';
    String originAddress = (from != null && from['address'] != null)
        ? from['address'].toString()
        : '';
    String destCode =
        (to != null && to['name'] != null) ? to['name'].toString() : '';
    String destAddress =
        (to != null && to['address'] != null) ? to['address'].toString() : '';
    String customerName = (customer != null && customer['name'] != null)
        ? customer['name'].toString()
        : '';

    // Fallback to stops if from/to missing
    if (originCode.isEmpty || destCode.isEmpty) {
      final transportOrder =
          dispatch['transportOrder'] as Map<String, dynamic>?;
      List<dynamic> rawStops =
          (dispatch['stops'] as List<dynamic>?) ?? const [];
      if (rawStops.isEmpty) {
        rawStops = (transportOrder?['stops'] as List<dynamic>?) ?? const [];
      }
      final stops = _normalizeStops(rawStops);
      dynamic origin = dispatch['from'] ??
          _firstByType(stops, 'PICKUP') ??
          (stops.isNotEmpty ? stops.first : null);
      dynamic dest = dispatch['to'] ??
          _firstByType(stops, 'DROP') ??
          (stops.length > 1 ? stops.last : null);
      if (origin is Map<String, dynamic>) {
        originCode = origin['locationName']?.toString() ??
            origin['name']?.toString() ??
            '';
        originAddress = origin['address']?.toString() ?? '';
      } else {
        originCode = '';
        originAddress = '';
      }
      if (dest is Map<String, dynamic>) {
        destCode =
            dest['locationName']?.toString() ?? dest['name']?.toString() ?? '';
        destAddress = dest['address']?.toString() ?? '';
      } else {
        destCode = '';
        destAddress = '';
      }
    }

    // Use translation key matching assets/translations/en.json and km.json
    final statusKey = (dispatch['status'] ?? '')
        .toString()
        .trim()
        .toUpperCase()
        .replaceAll('-', '_');
    final statusLabelKey = 'dispatch.status.$statusKey';
    String statusLabel = _knownDispatchStatusKeys.contains(statusKey)
        ? tr(statusLabelKey)
        : statusKey;
    // easy_localization returns the key when missing; also guard against top-level 'status' key being returned
    if (statusLabel == statusLabelKey ||
        statusLabel == statusKey ||
        statusLabel == 'status') {
      // fallback to raw status if translation missing
      statusLabel = statusKey
          .replaceAll('_', ' ')
          .toLowerCase()
          .split(' ')
          .map((w) => w.isNotEmpty
              ? w[0].toUpperCase() + w.substring(1).toLowerCase()
              : '')
          .join(' ');
    }

    final statusIcon = _getStatusIcon(statusKey);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: statusColor, width: 4),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#$dispatchId',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel, // Show translated or fallback status
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Safety badge (separate from lifecycle status)
                if (dispatch['safetyStatus'] != null &&
                    dispatch['safetyStatus'].toString().toUpperCase() !=
                        'UNKNOWN') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: safetyColorFor(
                          dispatch['safetyStatus']?.toString() ?? ''),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            safetyIconFor(
                                dispatch['safetyStatus']?.toString() ?? ''),
                            color: Colors.white,
                            size: 16),
                        const SizedBox(width: 6),
                        Text(
                          safetyLabelFor(
                              dispatch['safetyStatus']?.toString() ?? ''),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        originCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFd32f2f),
                        ),
                      ),
                      if (originAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          originAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    children: const [
                      Icon(Icons.arrow_forward, color: Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        destCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFd32f2f),
                        ),
                      ),
                      if (destAddress.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          destAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  pickupDate,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (customer?['name'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.business_center,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customer?['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/dispatchDetail',
                    arguments: {'dispatchId': dispatchId},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe53935),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  tr('common.view_detail'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PLANNED':
      case 'PENDING':
        return Colors.orange;
      case 'ASSIGNED':
        return Colors.teal;
      case 'DRIVER_CONFIRMED':
        return Colors.indigo;
      case 'APPROVED':
        return Colors.green.shade700;
      case 'REJECTED':
        return Colors.red.shade700;
      case 'SCHEDULED':
        return Colors.blueGrey;
      case 'ARRIVED_LOADING':
        return Colors.deepPurple;
      case 'LOADING':
        return Colors.deepPurple.shade300;
      case 'LOADED':
        return Colors.blueAccent;
      case 'SAFETY_PASSED':
        return Colors.green.shade600;
      case 'SAFETY_FAILED':
        return Colors.orange.shade700;
      case 'IN_QUEUE':
        return Colors.grey.shade600;
      case 'IN_TRANSIT':
        return Colors.blue;
      case 'ARRIVED_UNLOADING':
        return Colors.cyan;
      case 'UNLOADING':
        return Colors.cyan.shade300;
      case 'UNLOADED':
        return Colors.green;
      case 'DELIVERED':
        return Colors.green.shade800;
      case 'COMPLETED':
        return Colors.green.shade900;
      case 'CLOSED':
        return Colors.green.shade900; // Same as COMPLETED
      case 'CANCELLED':
        return Colors.red;
      case 'AT_HUB':
        return Colors.purple;
      case 'HUB_LOADING':
        return Colors.purple.shade300;
      case 'FINANCIAL_LOCKED':
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }

    Color getSafetyColor(String safety) {
      final s = safety.toUpperCase();
      if (s.contains('PASSED') || s.contains('SAFETY_PASSED'))
        return Colors.green.shade600;
      if (s.contains('FAILED') || s.contains('SAFETY_FAILED'))
        return Colors.orange.shade700;
      if (s.contains('SKIPPED')) return Colors.grey.shade600;
      return Colors.grey;
    }

    IconData getSafetyIcon(String safety) {
      final s = safety.toUpperCase();
      if (s.contains('PASSED') || s.contains('SAFETY_PASSED'))
        return Icons.verified;
      if (s.contains('FAILED') || s.contains('SAFETY_FAILED'))
        return Icons.error_outline;
      if (s.contains('SKIPPED')) return Icons.remove_circle_outline;
      return Icons.info_outline;
    }

    String getSafetyLabel(String safety) {
      final s = safety.toUpperCase();
      if (s.contains('PASSED') || s.contains('SAFETY_PASSED'))
        return tr('status.SAFETY_PASSED');
      if (s.contains('FAILED') || s.contains('SAFETY_FAILED'))
        return tr('status.SAFETY_FAILED');
      if (s.contains('SKIPPED') || s.contains('SAFETY_SKIPPED'))
        return tr('status.SAFETY_SKIPPED');
      return safety;
    }
  }

  String _completedMovedLabel() {
    const key = 'trip.completed_moved';
    final text = tr(key);
    if (text == key) {
      return 'See completed trips in Trip Report.';
    }
    return text;
  }

  /// Deduplicate and order stops by sequence/id so the card shows clean origin/destination.
  List<dynamic> _normalizeStops(List<dynamic> raw) {
    if (raw.isEmpty) return const [];
    final deduped = <String, dynamic>{};
    for (final s in raw) {
      if (s is! Map<String, dynamic>) continue; // skip invalid
      final stop = s;
      // Support both legacy and new stop formats
      final type = (stop['type'] ?? '').toString();
      // Use 'addressId' or 'id' for keying, fallback to 'locationName' for new format
      final addrId = stop['addressId']?.toString() ??
          stop['id']?.toString() ??
          stop['locationName']?.toString() ??
          '';
      // Use 'sequence', 'stopSequence', or fallback to ''
      final seq = stop['sequence']?.toString() ??
          stop['stopSequence']?.toString() ??
          '';
      // Compose a robust deduplication key
      final key = '$type|$addrId|$seq';
      deduped[key] = stop;
    }
    final list = deduped.values.toList();
    list.sort((a, b) {
      int sa = 9999;
      int sb = 9999;
      // Try to parse sequence values safely
      if (a['sequence'] != null) {
        sa = int.tryParse(a['sequence'].toString()) ?? 9999;
      } else if (a['stopSequence'] != null) {
        sa = int.tryParse(a['stopSequence'].toString()) ?? 9999;
      }
      if (b['sequence'] != null) {
        sb = int.tryParse(b['sequence'].toString()) ?? 9999;
      } else if (b['stopSequence'] != null) {
        sb = int.tryParse(b['stopSequence'].toString()) ?? 9999;
      }
      if (sa != sb) return sa.compareTo(sb);
      // Fallback to id comparison
      int ia = 0;
      int ib = 0;
      if (a['id'] != null) ia = int.tryParse(a['id'].toString()) ?? 0;
      if (b['id'] != null) ib = int.tryParse(b['id'].toString()) ?? 0;
      return ia.compareTo(ib);
    });
    return list;
  }

  dynamic _firstByType(List<dynamic> stops, String type) {
    return stops.firstWhere(
      (s) => (s['type'] ?? '').toString().toUpperCase() == type.toUpperCase(),
      orElse: () => null,
    );
  }

  Widget _buildBottomNavigation() => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, // Trips tab is selected
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        onTap: (index) {
          switch (index) {
            case 0: // Home
              Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
              break;
            case 1: // Trips - already here
              break;
            case 2: // Report
              Navigator.pushNamed(context, AppRoutes.reportIssueList);
              break;
            case 3: // Profile
              Navigator.pushNamed(context, AppRoutes.profile);
              break;
            case 4: // More
              Navigator.pushNamed(context, AppRoutes.settings);
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: tr('bottom_nav.home')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.local_shipping),
              label: tr('bottom_nav.trips')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.report), label: tr('bottom_nav.report')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person), label: tr('bottom_nav.profile')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz), label: tr('bottom_nav.more')),
        ],
      );
}
