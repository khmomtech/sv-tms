//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AuditTrail {
  /// Returns a new [AuditTrail] instance.
  AuditTrail({
    this.id,
    this.userId,
    this.username,
    this.action,
    this.resourceType,
    this.resourceId,
    this.resourceName,
    this.timestamp,
    this.details,
    this.ipAddress,
    this.userAgent,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

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
  String? username;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? action;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? resourceType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? resourceId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? resourceName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? timestamp;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? details;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? ipAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? userAgent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AuditTrail &&
    other.id == id &&
    other.userId == userId &&
    other.username == username &&
    other.action == action &&
    other.resourceType == resourceType &&
    other.resourceId == resourceId &&
    other.resourceName == resourceName &&
    other.timestamp == timestamp &&
    other.details == details &&
    other.ipAddress == ipAddress &&
    other.userAgent == userAgent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (userId == null ? 0 : userId!.hashCode) +
    (username == null ? 0 : username!.hashCode) +
    (action == null ? 0 : action!.hashCode) +
    (resourceType == null ? 0 : resourceType!.hashCode) +
    (resourceId == null ? 0 : resourceId!.hashCode) +
    (resourceName == null ? 0 : resourceName!.hashCode) +
    (timestamp == null ? 0 : timestamp!.hashCode) +
    (details == null ? 0 : details!.hashCode) +
    (ipAddress == null ? 0 : ipAddress!.hashCode) +
    (userAgent == null ? 0 : userAgent!.hashCode);

  @override
  String toString() => 'AuditTrail[id=$id, userId=$userId, username=$username, action=$action, resourceType=$resourceType, resourceId=$resourceId, resourceName=$resourceName, timestamp=$timestamp, details=$details, ipAddress=$ipAddress, userAgent=$userAgent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.userId != null) {
      json[r'userId'] = this.userId;
    } else {
      json[r'userId'] = null;
    }
    if (this.username != null) {
      json[r'username'] = this.username;
    } else {
      json[r'username'] = null;
    }
    if (this.action != null) {
      json[r'action'] = this.action;
    } else {
      json[r'action'] = null;
    }
    if (this.resourceType != null) {
      json[r'resourceType'] = this.resourceType;
    } else {
      json[r'resourceType'] = null;
    }
    if (this.resourceId != null) {
      json[r'resourceId'] = this.resourceId;
    } else {
      json[r'resourceId'] = null;
    }
    if (this.resourceName != null) {
      json[r'resourceName'] = this.resourceName;
    } else {
      json[r'resourceName'] = null;
    }
    if (this.timestamp != null) {
      json[r'timestamp'] = this.timestamp!.toUtc().toIso8601String();
    } else {
      json[r'timestamp'] = null;
    }
    if (this.details != null) {
      json[r'details'] = this.details;
    } else {
      json[r'details'] = null;
    }
    if (this.ipAddress != null) {
      json[r'ipAddress'] = this.ipAddress;
    } else {
      json[r'ipAddress'] = null;
    }
    if (this.userAgent != null) {
      json[r'userAgent'] = this.userAgent;
    } else {
      json[r'userAgent'] = null;
    }
    return json;
  }

  /// Returns a new [AuditTrail] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AuditTrail? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AuditTrail(
        id: mapValueOfType<int>(json, r'id'),
        userId: mapValueOfType<int>(json, r'userId'),
        username: mapValueOfType<String>(json, r'username'),
        action: mapValueOfType<String>(json, r'action'),
        resourceType: mapValueOfType<String>(json, r'resourceType'),
        resourceId: mapValueOfType<int>(json, r'resourceId'),
        resourceName: mapValueOfType<String>(json, r'resourceName'),
        timestamp: mapDateTime(json, r'timestamp', r''),
        details: mapValueOfType<String>(json, r'details'),
        ipAddress: mapValueOfType<String>(json, r'ipAddress'),
        userAgent: mapValueOfType<String>(json, r'userAgent'),
      );
    }
    return null;
  }

  static List<AuditTrail> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AuditTrail>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AuditTrail.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AuditTrail> mapFromJson(dynamic json) {
    final map = <String, AuditTrail>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AuditTrail.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AuditTrail-objects as value to a dart map
  static Map<String, List<AuditTrail>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AuditTrail>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AuditTrail.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

