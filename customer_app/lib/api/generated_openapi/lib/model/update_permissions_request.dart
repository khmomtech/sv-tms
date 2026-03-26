//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdatePermissionsRequest {
  /// Returns a new [UpdatePermissionsRequest] instance.
  UpdatePermissionsRequest({
    this.canManageDrivers,
    this.canManageCustomers,
    this.canViewReports,
    this.canManageSettings,
    this.isPrimary,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? canManageDrivers;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? canManageCustomers;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? canViewReports;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? canManageSettings;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isPrimary;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdatePermissionsRequest &&
    other.canManageDrivers == canManageDrivers &&
    other.canManageCustomers == canManageCustomers &&
    other.canViewReports == canViewReports &&
    other.canManageSettings == canManageSettings &&
    other.isPrimary == isPrimary;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (canManageDrivers == null ? 0 : canManageDrivers!.hashCode) +
    (canManageCustomers == null ? 0 : canManageCustomers!.hashCode) +
    (canViewReports == null ? 0 : canViewReports!.hashCode) +
    (canManageSettings == null ? 0 : canManageSettings!.hashCode) +
    (isPrimary == null ? 0 : isPrimary!.hashCode);

  @override
  String toString() => 'UpdatePermissionsRequest[canManageDrivers=$canManageDrivers, canManageCustomers=$canManageCustomers, canViewReports=$canViewReports, canManageSettings=$canManageSettings, isPrimary=$isPrimary]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.canManageDrivers != null) {
      json[r'canManageDrivers'] = this.canManageDrivers;
    } else {
      json[r'canManageDrivers'] = null;
    }
    if (this.canManageCustomers != null) {
      json[r'canManageCustomers'] = this.canManageCustomers;
    } else {
      json[r'canManageCustomers'] = null;
    }
    if (this.canViewReports != null) {
      json[r'canViewReports'] = this.canViewReports;
    } else {
      json[r'canViewReports'] = null;
    }
    if (this.canManageSettings != null) {
      json[r'canManageSettings'] = this.canManageSettings;
    } else {
      json[r'canManageSettings'] = null;
    }
    if (this.isPrimary != null) {
      json[r'isPrimary'] = this.isPrimary;
    } else {
      json[r'isPrimary'] = null;
    }
    return json;
  }

  /// Returns a new [UpdatePermissionsRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdatePermissionsRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdatePermissionsRequest(
        canManageDrivers: mapValueOfType<bool>(json, r'canManageDrivers'),
        canManageCustomers: mapValueOfType<bool>(json, r'canManageCustomers'),
        canViewReports: mapValueOfType<bool>(json, r'canViewReports'),
        canManageSettings: mapValueOfType<bool>(json, r'canManageSettings'),
        isPrimary: mapValueOfType<bool>(json, r'isPrimary'),
      );
    }
    return null;
  }

  static List<UpdatePermissionsRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdatePermissionsRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdatePermissionsRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdatePermissionsRequest> mapFromJson(dynamic json) {
    final map = <String, UpdatePermissionsRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdatePermissionsRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdatePermissionsRequest-objects as value to a dart map
  static Map<String, List<UpdatePermissionsRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdatePermissionsRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdatePermissionsRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

