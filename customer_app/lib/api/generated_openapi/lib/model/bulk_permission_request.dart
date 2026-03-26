//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class BulkPermissionRequest {
  /// Returns a new [BulkPermissionRequest] instance.
  BulkPermissionRequest({
    this.fromDate,
    this.toDate,
    this.status,
    this.notes,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fromDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? toDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is BulkPermissionRequest &&
    other.fromDate == fromDate &&
    other.toDate == toDate &&
    other.status == status &&
    other.notes == notes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (fromDate == null ? 0 : fromDate!.hashCode) +
    (toDate == null ? 0 : toDate!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() => 'BulkPermissionRequest[fromDate=$fromDate, toDate=$toDate, status=$status, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.fromDate != null) {
      json[r'fromDate'] = this.fromDate;
    } else {
      json[r'fromDate'] = null;
    }
    if (this.toDate != null) {
      json[r'toDate'] = this.toDate;
    } else {
      json[r'toDate'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    return json;
  }

  /// Returns a new [BulkPermissionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static BulkPermissionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return BulkPermissionRequest(
        fromDate: mapValueOfType<String>(json, r'fromDate'),
        toDate: mapValueOfType<String>(json, r'toDate'),
        status: mapValueOfType<String>(json, r'status'),
        notes: mapValueOfType<String>(json, r'notes'),
      );
    }
    return null;
  }

  static List<BulkPermissionRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <BulkPermissionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = BulkPermissionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, BulkPermissionRequest> mapFromJson(dynamic json) {
    final map = <String, BulkPermissionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = BulkPermissionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of BulkPermissionRequest-objects as value to a dart map
  static Map<String, List<BulkPermissionRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<BulkPermissionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = BulkPermissionRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

