//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AssignAdminRequest {
  /// Returns a new [AssignAdminRequest] instance.
  AssignAdminRequest({
    this.userId,
    this.companyId,
    this.isPrimary,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? userId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? companyId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isPrimary;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AssignAdminRequest &&
    other.userId == userId &&
    other.companyId == companyId &&
    other.isPrimary == isPrimary;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId == null ? 0 : userId!.hashCode) +
    (companyId == null ? 0 : companyId!.hashCode) +
    (isPrimary == null ? 0 : isPrimary!.hashCode);

  @override
  String toString() => 'AssignAdminRequest[userId=$userId, companyId=$companyId, isPrimary=$isPrimary]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.userId != null) {
      json[r'userId'] = this.userId;
    } else {
      json[r'userId'] = null;
    }
    if (this.companyId != null) {
      json[r'companyId'] = this.companyId;
    } else {
      json[r'companyId'] = null;
    }
    if (this.isPrimary != null) {
      json[r'isPrimary'] = this.isPrimary;
    } else {
      json[r'isPrimary'] = null;
    }
    return json;
  }

  /// Returns a new [AssignAdminRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AssignAdminRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AssignAdminRequest(
        userId: mapValueOfType<int>(json, r'userId'),
        companyId: mapValueOfType<int>(json, r'companyId'),
        isPrimary: mapValueOfType<bool>(json, r'isPrimary'),
      );
    }
    return null;
  }

  static List<AssignAdminRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AssignAdminRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AssignAdminRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AssignAdminRequest> mapFromJson(dynamic json) {
    final map = <String, AssignAdminRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AssignAdminRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AssignAdminRequest-objects as value to a dart map
  static Map<String, List<AssignAdminRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AssignAdminRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AssignAdminRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

