import 'dart:convert';

/// Model for home screen layout section configuration
/// Received from backend to control visibility and order of home sections
class HomeLayoutSectionModel {
  final String sectionKey;
  final int displayOrder;
  final bool visible;
  final String? configJson;

  const HomeLayoutSectionModel({
    required this.sectionKey,
    required this.displayOrder,
    required this.visible,
    this.configJson,
  });

  factory HomeLayoutSectionModel.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      final s = '$v';
      return int.tryParse(s) ?? 0;
    }

    bool _asBool(dynamic v) {
      if (v is bool) return v;
      final s = ('$v').toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }

    String _asString(dynamic v) {
      if (v == null) return '';
      if (v is String) return v;
      return '$v';
    }

    String? _asNullableString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v.isEmpty ? null : v;
      if (v is Map) {
        // Convert Map to JSON string
        try {
          return v.isEmpty ? null : jsonEncode(v);
        } catch (_) {
          return v.toString();
        }
      }
      final s = '$v';
      return s.isEmpty ? null : s;
    }

    return HomeLayoutSectionModel(
      sectionKey: _asString(json['sectionKey']),
      displayOrder: _asInt(json['displayOrder']),
      visible: _asBool(json['visible']),
      configJson: _asNullableString(json['configJson']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionKey': sectionKey,
      'displayOrder': displayOrder,
      'visible': visible,
      'configJson': configJson,
    };
  }

  @override
  String toString() {
    return 'HomeLayoutSection(sectionKey: $sectionKey, displayOrder: $displayOrder, visible: $visible)';
  }
}

/// Enum for home screen section keys
class HomeSectionKey {
  static const String header = 'header';
  static const String maintenanceBanner = 'maintenance_banner';
  static const String shiftStatus = 'shift_status';
  static const String safetyStatus = 'safety_status';
  static const String importantUpdates = 'important_updates';
  static const String currentTrip = 'current_trip';
  static const String quickActions = 'quick_actions';

  /// All known section keys
  static const List<String> all = [
    header,
    maintenanceBanner,
    shiftStatus,
    safetyStatus,
    importantUpdates,
    currentTrip,
    quickActions,
  ];
}
