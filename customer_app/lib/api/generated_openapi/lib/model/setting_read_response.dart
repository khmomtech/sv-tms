//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SettingReadResponse {
  /// Returns a new [SettingReadResponse] instance.
  SettingReadResponse({
    this.groupCode,
    this.keyCode,
    this.type,
    this.value,
    this.scope,
    this.scopeRef,
    this.version,
    this.updatedBy,
    this.updatedAt,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? groupCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? keyCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? type;

  Object? value;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? scope;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? scopeRef;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? version;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? updatedBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SettingReadResponse &&
    other.groupCode == groupCode &&
    other.keyCode == keyCode &&
    other.type == type &&
    other.value == value &&
    other.scope == scope &&
    other.scopeRef == scopeRef &&
    other.version == version &&
    other.updatedBy == updatedBy &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (groupCode == null ? 0 : groupCode!.hashCode) +
    (keyCode == null ? 0 : keyCode!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (value == null ? 0 : value!.hashCode) +
    (scope == null ? 0 : scope!.hashCode) +
    (scopeRef == null ? 0 : scopeRef!.hashCode) +
    (version == null ? 0 : version!.hashCode) +
    (updatedBy == null ? 0 : updatedBy!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode);

  @override
  String toString() => 'SettingReadResponse[groupCode=$groupCode, keyCode=$keyCode, type=$type, value=$value, scope=$scope, scopeRef=$scopeRef, version=$version, updatedBy=$updatedBy, updatedAt=$updatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.groupCode != null) {
      json[r'groupCode'] = this.groupCode;
    } else {
      json[r'groupCode'] = null;
    }
    if (this.keyCode != null) {
      json[r'keyCode'] = this.keyCode;
    } else {
      json[r'keyCode'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.value != null) {
      json[r'value'] = this.value;
    } else {
      json[r'value'] = null;
    }
    if (this.scope != null) {
      json[r'scope'] = this.scope;
    } else {
      json[r'scope'] = null;
    }
    if (this.scopeRef != null) {
      json[r'scopeRef'] = this.scopeRef;
    } else {
      json[r'scopeRef'] = null;
    }
    if (this.version != null) {
      json[r'version'] = this.version;
    } else {
      json[r'version'] = null;
    }
    if (this.updatedBy != null) {
      json[r'updatedBy'] = this.updatedBy;
    } else {
      json[r'updatedBy'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt;
    } else {
      json[r'updatedAt'] = null;
    }
    return json;
  }

  /// Returns a new [SettingReadResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SettingReadResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return SettingReadResponse(
        groupCode: mapValueOfType<String>(json, r'groupCode'),
        keyCode: mapValueOfType<String>(json, r'keyCode'),
        type: mapValueOfType<String>(json, r'type'),
        value: mapValueOfType<Object>(json, r'value'),
        scope: mapValueOfType<String>(json, r'scope'),
        scopeRef: mapValueOfType<String>(json, r'scopeRef'),
        version: mapValueOfType<int>(json, r'version'),
        updatedBy: mapValueOfType<String>(json, r'updatedBy'),
        updatedAt: mapValueOfType<String>(json, r'updatedAt'),
      );
    }
    return null;
  }

  static List<SettingReadResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SettingReadResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SettingReadResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SettingReadResponse> mapFromJson(dynamic json) {
    final map = <String, SettingReadResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SettingReadResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SettingReadResponse-objects as value to a dart map
  static Map<String, List<SettingReadResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SettingReadResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SettingReadResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

