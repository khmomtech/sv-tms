class DispatchInfo {
  final int id;
  final int? driverId;
  final String? driverName;
  final int? vehicleId;
  final String? licensePlate;
  final String? routeCode;
  final String? status;
  final String? loadingLocation;
  final String? unloadingLocation;

  DispatchInfo({
    required this.id,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.licensePlate,
    this.routeCode,
    this.status,
    this.loadingLocation,
    this.unloadingLocation,
  });

  factory DispatchInfo.fromJson(Map<String, dynamic> json) {
    String _clean(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? '' : text;
    }

    String _shortCodeFromName(String name) {
      if (name.isEmpty) return '';
      final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.isEmpty) return '';
      if (words.length == 1) {
        final w = words.first;
        return w.length <= 3 ? w.toUpperCase() : w.substring(0, 3).toUpperCase();
      }
      return words.take(3).map((w) => w[0].toUpperCase()).join();
    }

    String? _stopName(Map<String, dynamic>? stop) {
      if (stop == null) return null;
      final address = stop['address'];
      final addressMap = address is Map<String, dynamic> ? address : null;
      final directName = _clean(stop['name'] ?? stop['locationName']);
      final addrName = _clean(addressMap?['name'] ??
          addressMap?['description'] ??
          addressMap?['address'] ??
          (address is String ? address : null));
      if (directName.isNotEmpty) return directName;
      if (addrName.isNotEmpty) return addrName;
      return null;
    }

    String _stopCode(Map<String, dynamic>? stop) {
      if (stop == null) return '';
      final address = stop['address'];
      final addressMap = address is Map<String, dynamic> ? address : null;
      final directCode = _clean(stop['code'] ?? stop['shortCode']);
      final addressCode = _clean(addressMap?['code']);
      if (directCode.isNotEmpty) return directCode;
      if (addressCode.isNotEmpty) return addressCode;
      final name = _stopName(stop) ?? '';
      return _shortCodeFromName(name);
    }

    String? _formatStop(Map<String, dynamic>? stop) {
      if (stop == null) return null;
      final name = _stopName(stop) ?? '';
      final code = _stopCode(stop);
      if (name.isEmpty && code.isEmpty) return null;
      if (name.isEmpty) return code;
      if (code.isEmpty) return name;
      if (name.toUpperCase() == code.toUpperCase()) return name;
      return '$code • $name';
    }

    int _parseSequence(Map<String, dynamic> stop) {
      final value = stop['sequence'] ?? stop['stopSequence'];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 9999;
      return 9999;
    }

    int _parseId(Map<String, dynamic> stop) {
      final value = stop['id'];
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    Map<String, dynamic>? _firstByType(List<Map<String, dynamic>> stops, String type) {
      for (final stop in stops) {
        final candidate = _clean(stop['type']).toUpperCase();
        if (candidate == type.toUpperCase()) return stop;
      }
      return null;
    }

    List<Map<String, dynamic>> _collectStops() {
      final result = <Map<String, dynamic>>[];

      void addStops(dynamic raw) {
        if (raw is List) {
          for (final item in raw) {
            if (item is Map<String, dynamic>) {
              result.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }

      addStops(json['stops']);
      final transportOrder = json['transportationOrder'] ?? json['transportOrder'];
      if (transportOrder is Map<String, dynamic>) {
        addStops(transportOrder['stops']);
      }

      result.sort((a, b) {
        final seq = _parseSequence(a).compareTo(_parseSequence(b));
        if (seq != 0) return seq;
        return _parseId(a).compareTo(_parseId(b));
      });
      return result;
    }

    final stops = _collectStops();
    final pickupStop = _firstByType(stops, 'PICKUP') ?? (stops.isNotEmpty ? stops.first : null);
    final dropStop =
        _firstByType(stops, 'DROP') ?? (stops.length > 1 ? stops.last : pickupStop);

    String? resolveLoading() {
      return json['pickupName']?.toString() ??
          json['pickupLocation']?.toString() ??
          json['fromLocation']?.toString();
    }

    String? resolveUnloading() {
      return json['dropoffName']?.toString() ??
          json['dropoffLocation']?.toString() ??
          json['toLocation']?.toString();
    }

    return DispatchInfo(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      driverId: json['driverId'] != null ? int.tryParse(json['driverId'].toString()) : null,
      driverName: json['driverName']?.toString(),
      vehicleId: json['vehicleId'] != null ? int.tryParse(json['vehicleId'].toString()) : null,
      licensePlate: json['licensePlate']?.toString(),
      routeCode: json['routeCode']?.toString(),
      status: json['status']?.toString(),
      loadingLocation: _formatStop(pickupStop) ?? resolveLoading(),
      unloadingLocation: _formatStop(dropStop) ?? resolveUnloading(),
    );
  }
}
