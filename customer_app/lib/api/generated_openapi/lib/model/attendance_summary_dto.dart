//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AttendanceSummaryDto {
  /// Returns a new [AttendanceSummaryDto] instance.
  AttendanceSummaryDto({
    this.driverId,
    this.year,
    this.month,
    this.byStatus = const {},
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? driverId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? year;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? month;

  Map<String, int> byStatus;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AttendanceSummaryDto &&
    other.driverId == driverId &&
    other.year == year &&
    other.month == month &&
    _deepEquality.equals(other.byStatus, byStatus);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (driverId == null ? 0 : driverId!.hashCode) +
    (year == null ? 0 : year!.hashCode) +
    (month == null ? 0 : month!.hashCode) +
    (byStatus.hashCode);

  @override
  String toString() => 'AttendanceSummaryDto[driverId=$driverId, year=$year, month=$month, byStatus=$byStatus]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.driverId != null) {
      json[r'driverId'] = this.driverId;
    } else {
      json[r'driverId'] = null;
    }
    if (this.year != null) {
      json[r'year'] = this.year;
    } else {
      json[r'year'] = null;
    }
    if (this.month != null) {
      json[r'month'] = this.month;
    } else {
      json[r'month'] = null;
    }
      json[r'byStatus'] = this.byStatus;
    return json;
  }

  /// Returns a new [AttendanceSummaryDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AttendanceSummaryDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AttendanceSummaryDto(
        driverId: mapValueOfType<int>(json, r'driverId'),
        year: mapValueOfType<int>(json, r'year'),
        month: mapValueOfType<int>(json, r'month'),
        byStatus: mapCastOfType<String, int>(json, r'byStatus') ?? const {},
      );
    }
    return null;
  }

  static List<AttendanceSummaryDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AttendanceSummaryDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AttendanceSummaryDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AttendanceSummaryDto> mapFromJson(dynamic json) {
    final map = <String, AttendanceSummaryDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AttendanceSummaryDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AttendanceSummaryDto-objects as value to a dart map
  static Map<String, List<AttendanceSummaryDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AttendanceSummaryDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AttendanceSummaryDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

