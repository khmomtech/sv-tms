//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DashboardSummaryResponse {
  /// Returns a new [DashboardSummaryResponse] instance.
  DashboardSummaryResponse({
    this.summary,
    this.topDrivers = const [],
    this.liveDrivers = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DashboardSummaryDto? summary;

  List<TopDriverDto> topDrivers;

  List<DriverDto> liveDrivers;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DashboardSummaryResponse &&
    other.summary == summary &&
    _deepEquality.equals(other.topDrivers, topDrivers) &&
    _deepEquality.equals(other.liveDrivers, liveDrivers);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (summary == null ? 0 : summary!.hashCode) +
    (topDrivers.hashCode) +
    (liveDrivers.hashCode);

  @override
  String toString() => 'DashboardSummaryResponse[summary=$summary, topDrivers=$topDrivers, liveDrivers=$liveDrivers]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.summary != null) {
      json[r'summary'] = this.summary;
    } else {
      json[r'summary'] = null;
    }
      json[r'topDrivers'] = this.topDrivers;
      json[r'liveDrivers'] = this.liveDrivers;
    return json;
  }

  /// Returns a new [DashboardSummaryResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DashboardSummaryResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DashboardSummaryResponse(
        summary: DashboardSummaryDto.fromJson(json[r'summary']),
        topDrivers: TopDriverDto.listFromJson(json[r'topDrivers']),
        liveDrivers: DriverDto.listFromJson(json[r'liveDrivers']),
      );
    }
    return null;
  }

  static List<DashboardSummaryResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DashboardSummaryResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DashboardSummaryResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DashboardSummaryResponse> mapFromJson(dynamic json) {
    final map = <String, DashboardSummaryResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DashboardSummaryResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DashboardSummaryResponse-objects as value to a dart map
  static Map<String, List<DashboardSummaryResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DashboardSummaryResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DashboardSummaryResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

