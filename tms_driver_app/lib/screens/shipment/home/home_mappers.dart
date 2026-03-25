import 'package:easy_localization/easy_localization.dart';
import 'package:tms_driver_app/models/banner_model.dart';
import 'package:tms_driver_app/screens/shipment/home/home_state.dart';

HomeCurrentTripVm? mapCurrentTripVm(
  List<Map<String, dynamic>> inProgress,
  List<Map<String, dynamic>> pending, {
  required String emptyLoadLabel,
  required String unknownRouteLabel,
  required String etaFallback,
  required String progressFallback,
  String? progressTemplate,
}) {
  final dynamic raw = inProgress.isNotEmpty
      ? inProgress.first
      : (pending.isNotEmpty ? pending.first : null);
  if (raw is! Map<String, dynamic>) return null;

  final loadNo = _pickString(raw, const <String>[
    'loadNo',
    'loadNumber',
    'dispatchNo',
    'dispatchNumber',
    'orderReference',
    'trackingNo',
    'routeCode',
    'id',
  ]);
  final loadLabel = loadNo == null || loadNo.isEmpty
      ? emptyLoadLabel
      : '$emptyLoadLabel$loadNo';

  final from = _locationName(raw['from']) ??
      _pickString(raw, const <String>['fromLocation', 'pickupLocation']);
  final to = _locationName(raw['to']) ??
      _pickString(raw, const <String>['toLocation', 'dropoffLocation']);
  final stops = _stops(raw);
  final String fallbackFrom =
      stops.isNotEmpty ? (_locationName(stops.first) ?? '') : '';
  final String fallbackTo =
      stops.length > 1 ? (_locationName(stops.last) ?? '') : '';

  final String origin = (from?.isNotEmpty ?? false) ? (from ?? '') : fallbackFrom;
  final String destination =
      (to?.isNotEmpty ?? false) ? (to ?? '') : fallbackTo;

  final routeLabel = (origin.isNotEmpty && destination.isNotEmpty)
      ? '$origin -> $destination'
      : unknownRouteLabel;

  final eta = _formatEta(_pickDynamic(raw, const <String>[
    'eta',
    'estimatedArrival',
    'estimatedArrivalAt',
    'expectedArrivalTime',
    'arrivalAt',
  ]));

  final progressValue = _progress(_pickDynamic(raw, const <String>[
    'progress',
    'completionPercent',
    'completedPercent',
    'progressPercent',
  ]));

  final miles = _toDouble(_pickDynamic(raw, const <String>[
    'remainingMiles',
    'remainingDistanceMiles',
    'distanceRemaining',
    'remainingKm',
  ]));

  final progressLabel = miles != null
      ? (progressTemplate ?? '{miles} miles remaining ({percent}% complete)')
          .replaceAll('{miles}', miles.toStringAsFixed(0))
          .replaceAll('{percent}', (progressValue * 100).toStringAsFixed(0))
      : progressFallback;

  return HomeCurrentTripVm(
    loadNumber: loadLabel,
    routeLabel: routeLabel,
    etaLabel: eta ?? etaFallback,
    progress: progressValue,
    progressLabel: progressLabel,
  );
}

List<HomeUpdateVm> mapBannersToUpdates(
  List<BannerModel> banners, {
  required bool isKhmer,
  required String fallbackTitle,
  required String fallbackSubtitle,
  required String fallbackImageUrl,
}) {
  final items = banners.where((b) => (b.imageUrl ?? '').isNotEmpty).map((b) {
    final title = isKhmer && (b.titleKh ?? '').trim().isNotEmpty
        ? b.titleKh!.trim()
        : b.title.trim();
    final subtitle = isKhmer && (b.subtitleKh ?? '').trim().isNotEmpty
        ? b.subtitleKh!.trim()
        : (b.subtitle ?? '').trim();
    return HomeUpdateVm(
      id: b.id,
      title: title.isEmpty ? fallbackTitle : title,
      subtitle: subtitle.isEmpty ? fallbackSubtitle : subtitle,
      imageUrl: b.imageUrl ?? fallbackImageUrl,
      targetUrl: b.targetUrl,
    );
  }).toList();

  if (items.isNotEmpty) return items;

  return <HomeUpdateVm>[
    HomeUpdateVm(
      title: fallbackTitle,
      subtitle: fallbackSubtitle,
      imageUrl: fallbackImageUrl,
    ),
  ];
}

String? _pickString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final v = json[key];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return null;
}

dynamic _pickDynamic(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return json[key];
  }
  return null;
}

List<dynamic> _stops(Map<String, dynamic> dispatch) {
  final rawStops = dispatch['stops'];
  if (rawStops is List) return rawStops;
  final transportOrder = dispatch['transportOrder'];
  if (transportOrder is Map<String, dynamic> &&
      transportOrder['stops'] is List) {
    return transportOrder['stops'] as List<dynamic>;
  }
  return const <dynamic>[];
}

String? _locationName(dynamic raw) {
  if (raw is Map<String, dynamic>) {
    final fromName =
        (raw['name'] ?? raw['locationName'] ?? '').toString().trim();
    if (fromName.isNotEmpty) return fromName;
    final address = raw['address'];
    if (address is String && address.trim().isNotEmpty) return address.trim();
    if (address is Map<String, dynamic>) {
      final loc =
          (address['locationName'] ?? address['name'] ?? '').toString().trim();
      if (loc.isNotEmpty) return loc;
    }
  }
  if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  return null;
}

String? _formatEta(dynamic raw) {
  final parsed = _asDateTime(raw);
  if (parsed == null) return null;
  return DateFormat('hh:mm a').format(parsed);
}

DateTime? _asDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is String && raw.trim().isNotEmpty) {
    return DateTime.tryParse(raw.trim());
  }
  if (raw is List && raw.length >= 3) {
    final y = _toInt(raw[0]) ?? 0;
    final m = (_toInt(raw[1]) ?? 1).clamp(1, 12);
    final d = (_toInt(raw[2]) ?? 1).clamp(1, 31);
    final hh = (_toInt(raw.length > 3 ? raw[3] : 0) ?? 0).clamp(0, 23);
    final mm = (_toInt(raw.length > 4 ? raw[4] : 0) ?? 0).clamp(0, 59);
    final ss = (_toInt(raw.length > 5 ? raw[5] : 0) ?? 0).clamp(0, 59);
    return DateTime(y, m, d, hh, mm, ss);
  }
  return null;
}

double _progress(dynamic raw) {
  final value = _toDouble(raw);
  if (value == null) return 0.0;
  final normalized = value > 1 ? value / 100.0 : value;
  return normalized.clamp(0.0, 1.0);
}

int? _toInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is double) return raw.toInt();
  return int.tryParse(raw.toString());
}

double? _toDouble(dynamic raw) {
  if (raw is double) return raw;
  if (raw is int) return raw.toDouble();
  return double.tryParse(raw.toString());
}
