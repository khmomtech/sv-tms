/// Utilities for rendering dispatch stops safely across different payload shapes.
library stop_utils;

/// Safely resolve a stop name from possible fields.
String nameForStop(dynamic stop) {
  if (stop == null) return '';
  final addressValue = stop['address'];
  final address = addressValue is Map<String, dynamic> ? addressValue : null;
  final directName = (stop['name'] ?? '').toString();
  final locationName = (stop['locationName'] ?? '').toString();
  final addrName = (address?['name'] ??
          address?['description'] ??
          address?['address'] ??
          (addressValue is String ? addressValue : ''))
      .toString();

  if (directName.isNotEmpty) return directName;
  if (locationName.isNotEmpty) return locationName;
  if (addrName.isNotEmpty) return addrName;
  return '';
}

/// Safely derive a stop code from direct or nested address fields.
String codeForStop(dynamic stop) {
  final dynamic rawAddress = stop?['address'];
  final Map<String, dynamic>? address =
      rawAddress is Map<String, dynamic> ? rawAddress : null;
  final directCode = (stop?['code'] ?? '').toString();
  final directName = (stop?['name'] ?? '').toString();

  if (directCode.isNotEmpty) return directCode;
  if ((address?['code'] ?? '').toString().isNotEmpty) {
    return address!['code'].toString();
  }
  if (rawAddress is String && rawAddress.isNotEmpty) {
    return rawAddress;
  }

  final nameCandidate =
      (address?['name'] ?? address?['address'] ?? directName ?? '').toString();
  if (nameCandidate.isNotEmpty) {
    final derived = shortCodeFromName(nameCandidate);
    return derived.isNotEmpty ? derived : nameCandidate;
  }
  return '--';
}

/// Create a short code from a name (initials or first 3 letters).
String shortCodeFromName(String name) {
  if (name.isEmpty) return '';
  final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) {
    final w = words.first;
    return w.length <= 3 ? w.toUpperCase() : w.substring(0, 3).toUpperCase();
  }
  final initials = words.take(3).map((w) => w[0].toUpperCase()).join();
  return initials;
}
