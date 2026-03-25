import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tms_driver_app/constants/dispatch_constants.dart';
import 'package:tms_driver_app/core/network/api_constants.dart';
import 'package:tms_driver_app/models/dispatch_action_metadata.dart';
import 'package:tms_driver_app/providers/dispatch_provider.dart';
import 'package:tms_driver_app/routes/app_routes.dart';
import 'package:tms_driver_app/screens/shipment/fullscreen_image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';

class DispatchDetailScreen extends StatefulWidget {
  final String dispatchId;

  const DispatchDetailScreen({
    super.key,
    required this.dispatchId,
  });

  @override
  State<DispatchDetailScreen> createState() => _DispatchDetailScreenState();
}

class _DispatchDetailScreenState extends State<DispatchDetailScreen> {
  static const double _cardRadius = 24.0;
  static const double _cardSpacing = 16.0;
  final Color _background = const Color(0xFFF4F6FB);
  static final DateFormat _etaFormatter = DateFormat('dd-MMM-yyyy HH:mm');
  static const Map<String, String> _statusMapping = {
    '0': DispatchStatus.assigned,
    '1': DispatchStatus.driverConfirmed,
    '2': DispatchStatus.arrivedLoading,
    '3': DispatchStatus.loaded,
    '4': DispatchStatus.inTransit,
    '5': DispatchStatus.arrivedUnloading,
    '6': DispatchStatus.unloaded,
    '7': DispatchStatus.delivered,
    'IN TRANSIT': DispatchStatus.inTransit,
    'IN-TRANSIT': DispatchStatus.inTransit,
    'IN_QUEUE': DispatchStatus.inQueue,
    'QUEUED': DispatchStatus.inQueue,
    'PENDING': DispatchStatus.pending,
    'APPROVED': DispatchStatus.approved,
    'SCHEDULED': DispatchStatus.scheduled,
    'PICKED_UP': DispatchStatus.driverConfirmed,
  };
  static const Set<String> _knownStatusKeys = {
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
  static const Set<String> _knownDispatchActionKeys = {
    'accept',
    'not_authorized',
    'confirm_pickup',
    'arrive_loading',
    'arrive_at_loading',
    'get_ticket',
    'start_loading',
    'finish_loading',
    'load',
    'start_transit',
    'start',
    'arrive_unloading',
    'arrive_at_unloading',
    'start_unloading',
    'finish_unloading',
    'unload',
    'deliver',
    'complete_delivery',
    'complete',
    'mark_completed',
    'confirm_delivery',
    'cancel',
    'cancel_dispatch',
    'reject',
    'reject_dispatch',
    'pass_safety_check',
    'safety_check',
    'arrive_at_hub',
    'start_hub_loading',
    'depart_for_delivery',
    'depart_from_hub',
    'lock_financials',
    'close_dispatch',
    'enter_queue',
    'approve_dispatch',
    'schedule_dispatch',
    'assign_dispatch',
    'set_pending',
    'no_actions',
  };

  Map<String, dynamic>? _dispatch;
  bool _isLoading = true;
  bool _actionInProgress = false;
  String? _pendingTargetStatus;

  @override
  void initState() {
    super.initState();
    _loadDispatch();
  }

  Future<void> _loadDispatch() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dispatchProvider =
          Provider.of<DispatchProvider>(context, listen: false);
      final data = await dispatchProvider.getDispatchById(widget.dispatchId);

      if (!mounted) return;
      setState(() {
        _dispatch = data;
        _isLoading = false;
      });
      if (kDebugMode) {
        debugPrint(
            '[DispatchDetail] Loaded id=${widget.dispatchId} status=${_dispatch?["status"]}');
      }
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[DispatchDetail] Load failed: $e\n$st');
      setState(() {
        _dispatch = null;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('dispatch.load_error'.tr()),
          action: SnackBarAction(
            label: 'common.retry'.tr(),
            onPressed: _loadDispatch,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _reloadDispatchUntilExpected({
    required String expectedStatus,
    int maxAttempts = 5,
    int delayMs = 450,
  }) async {
    final provider = Provider.of<DispatchProvider>(context, listen: false);
    for (int i = 0; i < maxAttempts; i++) {
      provider.clearAvailableActionsCache(widget.dispatchId);
      final data = await provider.getDispatchById(widget.dispatchId);
      if (!mounted) return;
      if (data != null) {
        setState(() => _dispatch = data);
        final current = _normalizeStatus(data['status']);
        if (current == expectedStatus) {
          return;
        }
      }
      if (i < maxAttempts - 1) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  double scaleText(BuildContext context, double base) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 768) {
      return base * 1.4;
    } else if (screenWidth >= 600) {
      return base * 1.2;
    }
    return base;
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty || phone == '-') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('dispatch.no_phone'.tr())),
        );
      }
      return;
    }
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('dispatch.call_failed'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('dispatch.call_error'.tr())),
        );
      }
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    if (lat == 0 || lng == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('dispatch.no_coordinates'.tr())),
        );
      }
      return;
    }
    final url = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('dispatch.map_failed'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('dispatch.map_error'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text('dispatch.detail.title'.tr()),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2), // blue header
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dispatch == null
              ? Center(child: Text('dispatch.detail.no_data'.tr()))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _cardSpacing, vertical: _cardSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildModernTripCard(context),
                      const SizedBox(height: 20),
                      Center(
                        child: buildActionButton(
                            _dispatch!['status'] ?? DispatchStatus.assigned),
                      )
                    ],
                  ),
                ),
    );
  }

  Widget _buildModernTripCard(BuildContext context) {
    final dispatch = _dispatch!;
    final status =
        dispatch['status']?.toString().toUpperCase() ?? DispatchStatus.assigned;
    final driverName = dispatch['driverName'] ?? '-';
    final stops = _extractStops(dispatch);
    final itemsData = dispatch['transportOrder']?['items'];
    final items = itemsData is List
        ? List<Map<String, dynamic>>.from(itemsData)
        : <Map<String, dynamic>>[];

    return _buildModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(context, status, driverName),
          const SizedBox(height: 20),
          if (stops.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('dispatch.detail.no_data'.tr(),
                  style: const TextStyle(color: Colors.black54)),
            )
          else
            ...stops.map((stop) {
              final address = stop['address'];
              final isPickup = stop['type'] == 'PICKUP';
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildStop(
                  isPickup,
                  stop['eta'] ?? '',
                  address,
                  isPickup ? driverName : 'dispatch.detail.receiver_label'.tr(),
                  address?['latitude'] ?? 0.0,
                  address?['longitude'] ?? 0.0,
                  stop['contactPhone'] ?? '',
                ),
              );
            }),
          _buildProofSection('loadProof', 'dispatch.load_proof.label'.tr()),
          _buildProofSection('unloadProof', 'dispatch.unload_proof.label'.tr()),
          if (items.isNotEmpty) _buildItemsSection(items),
        ],
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: child,
    );
  }

  List<Map<String, dynamic>> _extractStops(Map<String, dynamic> dispatch) {
    final rawStops = <dynamic>[];
    void addStops(dynamic source) {
      if (source == null) return;
      if (source is Iterable) {
        rawStops.addAll(source);
      } else {
        rawStops.add(source);
      }
    }

    // Use only transport order stops to avoid duplication
    addStops(dispatch['transportOrder']?['stops']);

    final seenIds = <String>{};
    final normalized = <Map<String, dynamic>>[];

    for (var raw in rawStops) {
      final stop = _normalizeStop(raw);
      if (stop.isEmpty) continue;
      final key = stop['id']?.toString();
      if (key != null && key.isNotEmpty) {
        if (seenIds.contains(key)) continue;
        seenIds.add(key);
      } else {
        // fallback dedupe by type+address
        final addr = stop['location']?['address']?.toString() ?? '';
        final type = stop['type']?.toString() ?? '';
        final composite = '$type|$addr';
        if (seenIds.contains(composite)) continue;
        seenIds.add(composite);
      }
      normalized.add(stop);
    }
    return normalized;
  }

  Map<String, dynamic> _normalizeStop(dynamic raw) {
    if (raw == null) return {};

    final type =
        (raw['type'] ?? raw['stopType'] ?? 'PICKUP').toString().toUpperCase();
    final location = <String, dynamic>{};

    if (raw['address'] is Map) {
      location.addAll(Map<String, dynamic>.from(raw['address']));
    } else {
      if (raw['locationName'] != null) location['name'] = raw['locationName'];
      if (raw['address'] != null) location['address'] = raw['address'];
      if (raw['location'] != null) location['address'] ??= raw['location'];
      if (raw['pickupLocation'] != null)
        location['address'] ??= raw['pickupLocation'];
    }

    // Ensure human-readable name is present
    if (location['name'] == null || location['name'].toString().isEmpty) {
      if (raw['locationName'] != null &&
          raw['locationName'].toString().isNotEmpty) {
        location['name'] = raw['locationName'].toString();
      } else if (location['address'] != null &&
          location['address'].toString().isNotEmpty) {
        location['name'] = location['address'].toString();
      }
    }

    final coords =
        raw['coordinates'] ?? raw['coordinate'] ?? location['coordinates'];
    if (coords is String && coords.contains(',')) {
      final parts = coords.split(',').map((e) => e.trim()).toList();
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null) location['latitude'] = lat;
        if (lng != null) location['longitude'] = lng;
      }
    }

    location['latitude'] ??=
        raw['latitude'] ?? raw['pickupLat'] ?? raw['dropoffLat'];
    location['longitude'] ??=
        raw['longitude'] ?? raw['pickupLng'] ?? raw['dropoffLng'];

    final contactPhone = raw['contactPhone'] ??
        raw['driverPhone'] ??
        raw['phone'] ??
        raw['contactTel'] ??
        raw['telephone'];

    final person = raw['confirmedBy'] ??
        raw['contactPerson'] ??
        raw['driverName'] ??
        raw['person'];

    final remarks = raw['remarks'] ?? raw['note'] ?? raw['description'];

    String eta = '';
    final rawEta = raw['eta'] ?? raw['arrivalTime'] ?? raw['scheduledTime'];
    if (rawEta != null) {
      eta = _formatEta(rawEta);
    }

    final id = raw['id']?.toString() ??
        raw['stopSequence']?.toString() ??
        location['id']?.toString();

    return {
      'id': id,
      'type': type,
      'eta': eta,
      'location': location,
      'person': person,
      'latitude': location['latitude'],
      'longitude': location['longitude'],
      'contactPhone': contactPhone,
      'remarks': remarks,
    };
  }

  String _formatEta(dynamic raw) {
    try {
      if (raw == null) return 'N/A';
      if (raw is int) {
        return _etaFormatter.format(DateTime.fromMillisecondsSinceEpoch(raw));
      }
      if (raw is double) {
        return _etaFormatter
            .format(DateTime.fromMillisecondsSinceEpoch(raw.toInt()));
      }
      if (raw is List && raw.isNotEmpty) {
        final parts = List<int>.filled(6, 0);
        for (var i = 0; i < raw.length && i < 6; i++) {
          final value = raw[i];
          if (value is int) {
            parts[i] = value;
          } else if (value is String) {
            parts[i] = int.tryParse(value) ?? 0;
          }
        }
        final dt = DateTime(
            parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]);
        return _etaFormatter.format(dt);
      }
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return _etaFormatter.format(parsed);
        return raw;
      }
      return raw.toString();
    } catch (_) {
      return raw?.toString() ?? 'N/A';
    }
  }

  Widget _buildHeaderRow(
      BuildContext context, String status, String driverName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'dispatch.detail.trip_no'.tr(args: [(widget.dispatchId)]),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: scaleText(context, 16)),
              ),
              const SizedBox(height: 6),
              Text(
                driverName,
                style: const TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getStatusColor(status),
              width: 1.5,
            ),
          ),
          child: Text(
            _statusLabel(status),
            style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        )
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        return Colors.orange;
      case 'DRIVER_CONFIRMED':
        return Colors.blue;
      case 'ARRIVED_LOADING':
      case 'LOADING':
        return Colors.purple;
      case 'LOADED':
        return Colors.teal;
      case 'SAFETY_PASSED':
        return Colors.green;
      case 'SAFETY_FAILED':
        return Colors.red;
      case 'IN_TRANSIT':
        return Colors.indigo;
      case 'ARRIVED_UNLOADING':
      case 'UNLOADING':
        return Colors.deepPurple;
      case 'UNLOADED':
        return Colors.cyan;
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      case 'AT_HUB':
      case 'HUB_LOADING':
        return Colors.brown;
      case 'CLOSED':
      case 'FINANCIAL_LOCKED':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildStop(bool isPickup, dynamic date, dynamic location,
      dynamic person, dynamic lat, dynamic lng, dynamic phone) {
    final notes = location?['remarks'] ?? location?['notes'];
    final accent = isPickup ? Colors.green : Colors.blue;
    final etaText = _formatEta(date);
    // Resolve name/address with fallbacks (stop address name > locationName > top-level pickup/drop)
    String _fallbackName() {
      if (location is Map &&
          location['name'] != null &&
          location['name'].toString().isNotEmpty) {
        return location['name'].toString();
      }
      if (location is Map &&
          location['locationName'] != null &&
          location['locationName'].toString().isNotEmpty) {
        return location['locationName'].toString();
      }
      if (isPickup && _dispatch != null) {
        final topName =
            _dispatch!['pickupName'] ?? _dispatch!['pickupLocation'];
        if (topName != null && topName.toString().isNotEmpty)
          return topName.toString();
      }
      if (!isPickup && _dispatch != null) {
        final topName =
            _dispatch!['dropoffName'] ?? _dispatch!['dropoffLocation'];
        if (topName != null && topName.toString().isNotEmpty)
          return topName.toString();
      }
      return isPickup ? 'trip.from'.tr() : 'trip.to'.tr();
    }

    String _fallbackAddress() {
      if (location is Map &&
          location['address'] != null &&
          location['address'].toString().isNotEmpty) {
        return location['address'].toString();
      }
      if (isPickup && _dispatch != null) {
        final addr =
            _dispatch!['pickupLocation'] ?? _dispatch!['pickupAddress'];
        if (addr != null && addr.toString().isNotEmpty) return addr.toString();
        final toAddr =
            _dispatch?['transportOrder']?['pickupAddress']?['address'];
        if (toAddr != null && toAddr.toString().isNotEmpty)
          return toAddr.toString();
      }
      if (!isPickup && _dispatch != null) {
        final addr =
            _dispatch!['dropoffLocation'] ?? _dispatch!['dropoffAddress'];
        if (addr != null && addr.toString().isNotEmpty) return addr.toString();
        final toAddr = _dispatch?['transportOrder']?['dropAddress']?['address'];
        if (toAddr != null && toAddr.toString().isNotEmpty)
          return toAddr.toString();
      }
      return 'N/A';
    }

    final stopName = _fallbackName();
    final stopAddress = _fallbackAddress();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(isPickup ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                  color: accent, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stopName,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, color: accent),
                    ),
                    const SizedBox(height: 4),
                    Text(etaText,
                        style: TextStyle(
                            color: accent.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map, size: 20),
                onPressed: () => _openMap(lat ?? 0.0, lng ?? 0.0),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  onTap: () => _openMap(lat ?? 0.0, lng ?? 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stopName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(stopAddress),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(person ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () => _makePhoneCall(phone ?? ''),
              ),
            ],
          ),
          if (notes != null && notes.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes.toString(),
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProofSection(String proofKey, String title) {
    final proof = _dispatch![proofKey];
    if (proof == null) return const SizedBox();

    final rawPaths = proof['proofImagePaths'] ?? proof['imageUrls'] ?? const [];
    final imagePaths = List<String>.from(rawPaths);
    if (imagePaths.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: imagePaths.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final path = imagePaths[index];
            final imageUrl = _resolveImageUrl(path);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullscreenImageViewer(imageUrl: imageUrl),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _resolveImageUrl(String path) {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) return '';

    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Use ApiConstants.image() to handle localhost URL normalization
      return ApiConstants.image(normalizedPath);
    }

    // Backend may return:
    //  - /uploads/load-proof/2/a.jpg
    //  - uploads/load-proof/2/a.jpg
    //  - load-proof/2/a.jpg (without uploads prefix)
    String relative = normalizedPath;
    if (relative.startsWith('/')) {
      relative = relative.substring(1);
    }
    if (!relative.startsWith('uploads/')) {
      relative = 'uploads/$relative';
    }

    return ApiConstants.image(relative);
  }

  String _normalizeStatus(dynamic statusParam) {
    final rawStatus = statusParam?.toString() ?? '';
    final normalized = rawStatus.toUpperCase().replaceAll('-', '_').trim();
    return _statusMapping[normalized] ?? normalized;
  }

  String _statusLabel(dynamic statusParam) {
    final normalized = _normalizeStatus(statusParam);
    if (_knownStatusKeys.contains(normalized)) {
      return 'dispatch.status.$normalized'.tr();
    }
    return normalized.isEmpty
        ? DispatchStatus.assigned.replaceAll('_', ' ')
        : normalized.replaceAll('_', ' ');
  }

  Future<void> _handleAction(Future<void> Function() action) async {
    if (!mounted) return;
    setState(() => _actionInProgress = true);
    try {
      await action();
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[DispatchDetail] Action failed: $e\n$st');

      // Parse validation errors from response if available
      String message = 'dispatch.action.failed'.tr();
      if (message == 'dispatch.action.failed') {
        message = 'Action failed';
      }
      String? details;

      // Check if this is a Dio HTTP error with response data
      if (e.toString().contains('DioException')) {
        // Handle HTTP-specific errors by checking response field
        try {
          final dynamic errorObj = e;
          final response = errorObj.response;

          if (response != null) {
            final statusCode = response.statusCode;
            if (statusCode == 401) {
              message = 'dispatch.unauthorized'.tr();
            } else if (statusCode == 400) {
              // Try to parse validation errors
              try {
                final data = response.data;
                if (data is Map<String, dynamic>) {
                  if (data.containsKey('message')) {
                    details = data['message'] as String;
                  }
                  if (data.containsKey('errors') && data['errors'] is Map) {
                    final Map<String, dynamic> fieldErrors =
                        data['errors'] as Map<String, dynamic>;
                    final statusError = fieldErrors['status']?.toString();
                    final code = fieldErrors['code']?.toString();
                    if (statusError != null && statusError.trim().isNotEmpty) {
                      details = statusError.trim();
                    }
                    if (code != null && code.trim().isNotEmpty) {
                      details = details == null
                          ? 'Code: ${code.trim()}'
                          : '$details\nCode: ${code.trim()}';
                    }
                    final errorList = fieldErrors.entries
                        .map((entry) => '${entry.key}: ${entry.value}')
                        .toList();
                    if (details == null && errorList.isNotEmpty) {
                      details = errorList.join('\n');
                    }
                  }
                  if (data.containsKey('validationErrors') &&
                      data['validationErrors'] is Map) {
                    final Map<String, dynamic> errors =
                        data['validationErrors'] as Map<String, dynamic>;
                    final errorList = errors.entries
                        .map((entry) => '${entry.key}: ${entry.value}')
                        .toList();
                    details = errorList.join('\n');
                  }
                }
              } catch (parseError) {
                if (kDebugMode)
                  debugPrint(
                      '[DispatchDetail] Error parsing validation errors: $parseError');
              }
            }
          }
        } catch (e) {
          debugPrint('[DispatchDetail] Error inspecting exception: $e');
        }
      }

      // Check for network errors
      if (e.toString().contains('Network') ||
          e.toString().contains('SocketException')) {
        message = 'dispatch.network_error'.tr();
      }
      if ((details == null || details.trim().isEmpty) &&
          e.toString().contains('Submit POL before updating to transit')) {
        details = 'Submit POL before updating to transit.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (details != null) ...[
                const SizedBox(height: 8),
                Text(
                  details,
                  style: const TextStyle(fontSize: 12),
                )
              ]
            ],
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Dismiss'.tr(),
            onPressed: () {},
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Widget buildActionButton(dynamic statusParam) {
    final status = _normalizeStatus(statusParam);

    // Terminal states - no actions available
    if (status == DispatchStatus.completed ||
        status == DispatchStatus.cancelled) {
      return Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 16,
          color: status == DispatchStatus.completed ? Colors.green : Colors.red,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // Fetch available actions dynamically from API with full metadata
    return FutureBuilder<DispatchActionsResponse?>(
      future: Provider.of<DispatchProvider>(context, listen: false)
          .getAvailableActions(widget.dispatchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final actionsResponse = snapshot.data;

        // If API response is missing, do not apply local transition fallbacks.
        // Driver actions must follow server policy.
        if (actionsResponse == null) {
          return _buildActionListFromServer(
            status: status,
            actions: const [],
            canPerformActions: false,
            emptyMessage: _translateActionKey('no_actions'),
          );
        }

        // If backend returns no actions, do not force local workflow fallbacks.
        // Template-driven transitions may intentionally have no valid action.
        if (actionsResponse.availableActions.isEmpty) {
          return _buildActionListFromServer(
            status: status,
            actions: const [],
            canPerformActions: actionsResponse.canPerformActions,
            emptyMessage: actionsResponse.actionRestrictionMessage ??
                _translateActionKey('no_actions'),
            restrictionMessage: actionsResponse.actionRestrictionMessage,
          );
        }

        // Show all next actions from backend, but enable only those allowed for driver now.
        final allActions = actionsResponse.availableActions.toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));

        if (allActions.isEmpty) {
          return _buildActionListFromServer(
            status: status,
            actions: const [],
            canPerformActions: actionsResponse.canPerformActions,
            emptyMessage: actionsResponse.actionRestrictionMessage ??
                _translateActionKey('no_actions'),
            restrictionMessage: actionsResponse.actionRestrictionMessage,
          );
        }

        return _buildActionListFromServer(
          status: status,
          actions: allActions,
          canPerformActions: actionsResponse.canPerformActions,
          emptyMessage: actionsResponse.actionRestrictionMessage ??
              _translateActionKey('no_actions'),
          restrictionMessage: actionsResponse.actionRestrictionMessage,
        );
      },
    );
  }

  Widget _buildActionListFromServer({
    required String status,
    required List<DispatchActionMetadata> actions,
    required bool canPerformActions,
    required String emptyMessage,
    String? restrictionMessage,
  }) {
    if (actions.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    final sortedActions = actions.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedActions
          .map(
            (action) => _buildActionButton(
              status,
              action,
              canPerformActions: canPerformActions,
              disableOverrideReason: canPerformActions
                  ? null
                  : (restrictionMessage ?? emptyMessage),
            ),
          )
          .toList(),
    );
  }

  /// Build an action button from backend action metadata
  /// Uses metadata for label, icon, color, and interaction behavior
  Widget _buildActionButton(String currentStatus, DispatchActionMetadata action,
      {required bool canPerformActions, String? disableOverrideReason}) {
    final actionLabel = _resolveActionLabel(action.actionLabel);
    final forceEnableForDriver =
        _isDriverAllowedOverrideAction(currentStatus, action) ||
            _isBlockedInputGuidanceAction(action);
    final waitingSameTarget = _pendingTargetStatus == action.targetStatus;
    final isEnabled = !waitingSameTarget &&
        (canPerformActions || forceEnableForDriver) &&
        _isActionEnabled(action);
    final disableReason = !isEnabled
        ? (disableOverrideReason ??
            (action.blockedReason?.trim().isNotEmpty == true
                ? action.blockedReason!.trim()
                : (action.validationMessage?.trim().isNotEmpty == true
                    ? action.validationMessage!.trim()
                    : _translateActionKey(action.requiresAdminApproval
                        ? 'not_authorized'
                        : 'no_actions'))))
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_actionInProgress || !isEnabled)
                  ? null
                  : () async {
                      if (_isBlockedPolAction(currentStatus, action)) {
                        await _openPolSubmissionFlow();
                        return;
                      }
                      if (_isBlockedPodAction(action)) {
                        await _openPodSubmissionFlow();
                        return;
                      }
                      await _executeAction(currentStatus, action);
                    },
              icon: _actionInProgress
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    )
                  : Icon(_getIconFromName(action.iconName)),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _parseColor(action.buttonColor),
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: action.isDestructive
                      ? BorderSide(color: Colors.red.shade300, width: 1.5)
                      : BorderSide.none,
                ),
                elevation: action.isDestructive ? 0 : 2,
              ),
            ),
          ),
          if (disableReason != null) ...[
            const SizedBox(height: 6),
            Text(
              disableReason,
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }

  bool _isActionEnabled(DispatchActionMetadata action) {
    if (!action.allowedForCurrentUser) {
      if (_isBlockedInputGuidanceAction(action)) {
        return true;
      }
      return false;
    }

    // Allow driver to update GET_TICKET from ARRIVED_LOADING -> IN_QUEUE.
    if (_isGetTicketAction(action)) {
      return true;
    }

    // Input-driven actions (e.g. LOADED via POL upload) must remain clickable.
    // Backend may mark these with guidance text instead of direct patch action.
    if (action.requiresInput) {
      return true;
    }
    if (!action.driverInitiated) {
      return false;
    }
    if (action.requiresAdminApproval) {
      return false;
    }
    if (action.validationMessage != null &&
        action.validationMessage!.trim().isNotEmpty) {
      return false;
    }
    return true;
  }

  bool _isGetTicketAction(DispatchActionMetadata action) {
    final label = action.actionLabel.toLowerCase();
    return action.targetStatus == DispatchStatus.safetyPassed &&
        (label.contains('get_ticket') || label.contains('get ticket'));
  }

  bool _isDriverAllowedOverrideAction(
      String currentStatus, DispatchActionMetadata action) {
    return currentStatus == DispatchStatus.arrivedLoading &&
        _isGetTicketAction(action);
  }

  bool _isBlockedPolAction(
      String currentStatus, DispatchActionMetadata action) {
    if (_isPolInputAction(action)) {
      return true;
    }
    if (currentStatus != DispatchStatus.loaded) {
      return false;
    }
    if (action.targetStatus != DispatchStatus.inTransit) {
      return false;
    }
    final reason = (action.blockedReason ?? '').toLowerCase();
    return reason.contains('submit pol');
  }

  bool _isBlockedPodAction(DispatchActionMetadata action) {
    if (_isPodInputAction(action)) {
      return true;
    }
    final reason = (action.blockedReason ?? '').toLowerCase();
    return reason.contains('submit pod');
  }

  bool _isBlockedInputGuidanceAction(DispatchActionMetadata action) {
    return _isPolInputAction(action) || _isPodInputAction(action);
  }

  bool _isPolInputAction(DispatchActionMetadata action) {
    final requiredInput = action.requiredInput.toUpperCase();
    final routeHint = (action.inputRouteHint ?? '').toUpperCase();
    final blockedCode = (action.blockedCode ?? '').toUpperCase();
    return requiredInput == 'POL' ||
        routeHint == 'LOAD_PROOF' ||
        blockedCode == 'POL_REQUIRED';
  }

  bool _isPodInputAction(DispatchActionMetadata action) {
    final requiredInput = action.requiredInput.toUpperCase();
    final routeHint = (action.inputRouteHint ?? '').toUpperCase();
    final blockedCode = (action.blockedCode ?? '').toUpperCase();
    return requiredInput == 'POD' ||
        routeHint == 'UNLOAD_PROOF' ||
        blockedCode == 'POD_REQUIRED';
  }

  Future<void> _openPolSubmissionFlow() async {
    if (!mounted) return;

    final result = await Navigator.pushNamed(
      context,
      AppRoutes.loadTaskDetail,
      arguments: {'dispatchId': widget.dispatchId},
    );

    if (!mounted) return;
    if (result == true) {
      await _reloadDispatchUntilExpected(
        expectedStatus: DispatchStatus.loaded,
      );
    }
  }

  Future<void> _openPodSubmissionFlow() async {
    if (!mounted) return;

    final result = await Navigator.pushNamed(
      context,
      AppRoutes.unloadTaskDetail,
      arguments: {'dispatchId': widget.dispatchId},
    );

    if (!mounted) return;
    if (result == true) {
      await _reloadDispatchUntilExpected(
        expectedStatus: DispatchStatus.unloaded,
      );
    }
  }

  /// Map icon name string to MaterialIcons
  IconData _getIconFromName(String iconName) {
    const iconMap = {
      'check_circle': Icons.check_circle,
      'check_circle_outline': Icons.check_circle_outline,
      'local_shipping': Icons.local_shipping,
      'warehouse': Icons.warehouse,
      'play_arrow': Icons.play_arrow,
      'done': Icons.done,
      'done_all': Icons.done_all,
      'sync': Icons.sync,
      'inventory': Icons.inventory_2,
      'verified': Icons.verified,
      'flag': Icons.flag,
      'verified_user': Icons.verified_user,
      'lock': Icons.lock,
      'archive': Icons.archive,
      'block': Icons.block,
      'navigation': Icons.navigation,
      'location_on': Icons.location_on,
      'cancel': Icons.cancel,
      'arrow_back': Icons.arrow_back,
      'info': Icons.info,
      'table_rows': Icons.table_rows,
    };
    return iconMap[iconName] ?? Icons.check_circle_outline;
  }

  /// Parse hex color string to Color object
  /// Supports formats: #RRGGBB, #AARRGGBB, RRGGBB
  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return const Color(0xFF4CAF50); // Default green
    }

    String hex = hexColor.replaceAll('#', '');

    // Add alpha if not present
    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      debugPrint(
          '[DispatchDetail] Failed to parse color: $hexColor, using default');
      return const Color(0xFF4CAF50); // Default green
    }
  }

  String _resolveActionLabel(String rawLabel) {
    final normalized = rawLabel.trim();
    if (normalized.isEmpty) return _translateActionKey('no_actions');
    if (normalized.startsWith('dispatch.action.')) {
      return _translateActionKey(
          normalized.replaceFirst('dispatch.action.', '').trim().toLowerCase());
    }
    if (normalized.startsWith('action.')) {
      return _translateActionKey(
          normalized.replaceFirst('action.', '').trim().toLowerCase());
    }
    if (normalized.contains('.')) return normalized;
    return _translateActionKey(normalized.toLowerCase());
  }

  String _translateActionKey(String shortKey) {
    final normalized = shortKey.trim().toLowerCase();
    if (_knownDispatchActionKeys.contains(normalized)) {
      return 'dispatch.action.$normalized'.tr();
    }
    const fallback = <String, String>{
      'no_actions': 'No actions available',
      'not_authorized': 'You are not authorized to perform this action',
      'arrive_at_loading': 'Arrive at Loading Point',
      'get_ticket': 'Get Ticket',
      'safety_check': 'Safety Check',
      'enter_queue': 'Enter Queue',
      'pass_safety_check': 'Pass Safety Check',
      'start_loading': 'Start Loading',
      'finish_loading': 'Finish Loading',
      'start_transit': 'Start Transit',
      'arrive_at_unloading': 'Arrive at Unloading Point',
      'start_unloading': 'Start Unloading',
      'finish_unloading': 'Finish Unloading',
      'complete_delivery': 'Confirm Delivery',
      'mark_completed': 'Complete Trip',
    };
    return fallback[normalized] ?? normalized.replaceAll('_', ' ');
  }

  /// Execute an action with confirmation if required
  Future<void> _executeAction(
      String currentStatus, DispatchActionMetadata action) async {
    if (!mounted) return;

    // Show confirmation dialog for destructive or confirmation-required actions
    if (action.requiresConfirmation || action.isDestructive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(action.isDestructive
              ? 'dispatch.confirm.destructive'.tr()
              : 'dispatch.confirm.action'.tr()),
          content: Text(
            'dispatch.confirm.message'.tr(args: [action.actionLabel.tr()]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: action.isDestructive
                  ? TextButton.styleFrom(foregroundColor: Colors.red)
                  : null,
              child: Text('common.confirm'.tr()),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // Execute optimistic update
    await _optimisticStatusUpdate(
      currentStatus,
      action.targetStatus,
      action.actionLabel.tr(),
      action,
    );
  }

  /// Implement optimistic UI update: show status change immediately,
  /// confirm with backend asynchronously, revert on error
  Future<void> _optimisticStatusUpdate(String currentStatus, String nextStatus,
      String label, DispatchActionMetadata action) async {
    if (!mounted) return;

    // Show optimistic status change immediately
    final previousDispatch =
        _dispatch == null ? null : Map<String, dynamic>.from(_dispatch!);
    setState(() {
      _dispatch?['status'] = nextStatus;
      _actionInProgress = true;
      _pendingTargetStatus = nextStatus;
    });

    try {
      // Check for special cases requiring navigation
      if (nextStatus == DispatchStatus.loaded) {
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.loadTaskDetail,
          arguments: {'dispatchId': widget.dispatchId},
        );
        if (!mounted) return;
        if (result != true) {
          // User cancelled - revert optimistic update
          setState(() => _dispatch = previousDispatch);
          return;
        }
        // Load task submission endpoint updates status to LOADED server-side.
        if (mounted) {
          await _reloadDispatchUntilExpected(
            expectedStatus: DispatchStatus.loaded,
          );
        }
        return;
      } else if (nextStatus == DispatchStatus.unloading) {
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.unloadTaskDetail,
          arguments: {'dispatchId': widget.dispatchId},
        );
        if (!mounted) return;
        if (result != true) {
          // User cancelled - revert optimistic update
          setState(() => _dispatch = previousDispatch);
          return;
        }
        // Unload submission endpoint advances status server-side (to UNLOADED).
        // Do not patch back to UNLOADING after successful proof submission.
        if (mounted) {
          await _reloadDispatchUntilExpected(
            expectedStatus: DispatchStatus.unloaded,
          );
        }
        return;
      }

      // Perform actual API call
      if (currentStatus == DispatchStatus.assigned &&
          nextStatus == DispatchStatus.driverConfirmed) {
        await Provider.of<DispatchProvider>(context, listen: false)
            .acceptDispatch(widget.dispatchId);
      } else {
        await Provider.of<DispatchProvider>(context, listen: false)
            .updateDispatchStatus(widget.dispatchId, nextStatus);
      }

      // Success - reload dispatch to sync with backend
      if (mounted) {
        await _reloadDispatchUntilExpected(expectedStatus: nextStatus);
        if (_normalizeStatus(_dispatch?['status']) ==
            DispatchStatus.completed) {
          Navigator.pushReplacementNamed(context, AppRoutes.tripReport);
          return;
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[DispatchDetail] Optimistic update failed: $e\n$st');
      }

      // Revert optimistic update on error
      if (mounted) {
        setState(() => _dispatch = previousDispatch);

        // Show error message
        await _handleAction(() async {
          throw e;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionInProgress = false;
          _pendingTargetStatus = null;
        });
      }
    }
  }

  Widget _buildItemsSection(List<Map<String, dynamic>> items) {
    // Show items only from transport order; defensively dedupe by id/code/name
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final item in items) {
      final key = item['id']?.toString() ??
          item['itemId']?.toString() ??
          item['itemCode']?.toString() ??
          '${item['itemName'] ?? ''}|${item['warehouse'] ?? ''}';
      if (seen.contains(key)) continue;
      seen.add(key);
      deduped.add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('dispatch.detail.items'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: deduped.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final item = deduped[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['itemName'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${'dispatch.detail.qty'.tr()}: ${item['quantity'] ?? '0'} ${item['unitOfMeasurement'] ?? ''}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      if (item['palletType'] != null)
                        Text(
                          '${'dispatch.detail.pallet_type'.tr()}: ${double.tryParse(item['palletType'].toString())?.toStringAsFixed(2) ?? item['palletType']}',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      if (item['warehouse'] != null)
                        Text(
                            '${'dispatch.detail.WH'.tr()}: ${item['warehouse']}',
                            style: const TextStyle(color: Colors.black54)),
                      if (item['dimensions'] != null &&
                          item['dimensions'].toString().isNotEmpty)
                        Text('Size: ${item['dimensions']}',
                            style: const TextStyle(color: Colors.black54)),
                      if (item['fromDestination'] != null &&
                          item['toDestination'] != null)
                        Text(
                            'From: ${item['fromDestination']} → ${item['toDestination']}',
                            style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
