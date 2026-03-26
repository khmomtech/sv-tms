//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreatePermissionRequest {
  /// Returns a new [CreatePermissionRequest] instance.
  CreatePermissionRequest({
    required this.name,
    required this.description,
    required this.resourceType,
    required this.actionType,
  });

  String name;

  String description;

  String resourceType;

  String actionType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreatePermissionRequest &&
    other.name == name &&
    other.description == description &&
    other.resourceType == resourceType &&
    other.actionType == actionType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (description.hashCode) +
    (resourceType.hashCode) +
    (actionType.hashCode);

  @override
  String toString() => 'CreatePermissionRequest[name=$name, description=$description, resourceType=$resourceType, actionType=$actionType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'description'] = this.description;
      json[r'resourceType'] = this.resourceType;
      json[r'actionType'] = this.actionType;
    return json;
  }

  /// Returns a new [CreatePermissionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreatePermissionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "CreatePermissionRequest[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "CreatePermissionRequest[name]" has a null value in JSON.');
        assert(json.containsKey(r'description'), 'Required key "CreatePermissionRequest[description]" is missing from JSON.');
        assert(json[r'description'] != null, 'Required key "CreatePermissionRequest[description]" has a null value in JSON.');
        assert(json.containsKey(r'resourceType'), 'Required key "CreatePermissionRequest[resourceType]" is missing from JSON.');
        assert(json[r'resourceType'] != null, 'Required key "CreatePermissionRequest[resourceType]" has a null value in JSON.');
        assert(json.containsKey(r'actionType'), 'Required key "CreatePermissionRequest[actionType]" is missing from JSON.');
        assert(json[r'actionType'] != null, 'Required key "CreatePermissionRequest[actionType]" has a null value in JSON.');
        return true;
      }());

      return CreatePermissionRequest(
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        resourceType: mapValueOfType<String>(json, r'resourceType')!,
        actionType: mapValueOfType<String>(json, r'actionType')!,
      );
    }
    return null;
  }

  static List<CreatePermissionRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreatePermissionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreatePermissionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreatePermissionRequest> mapFromJson(dynamic json) {
    final map = <String, CreatePermissionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreatePermissionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreatePermissionRequest-objects as value to a dart map
  static Map<String, List<CreatePermissionRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreatePermissionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreatePermissionRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'description',
    'resourceType',
    'actionType',
  };
}

