//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdatePermissionRequest {
  /// Returns a new [UpdatePermissionRequest] instance.
  UpdatePermissionRequest({
    required this.description,
    required this.resourceType,
    required this.actionType,
  });

  String description;

  String resourceType;

  String actionType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdatePermissionRequest &&
    other.description == description &&
    other.resourceType == resourceType &&
    other.actionType == actionType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (description.hashCode) +
    (resourceType.hashCode) +
    (actionType.hashCode);

  @override
  String toString() => 'UpdatePermissionRequest[description=$description, resourceType=$resourceType, actionType=$actionType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'description'] = this.description;
      json[r'resourceType'] = this.resourceType;
      json[r'actionType'] = this.actionType;
    return json;
  }

  /// Returns a new [UpdatePermissionRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdatePermissionRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'description'), 'Required key "UpdatePermissionRequest[description]" is missing from JSON.');
        assert(json[r'description'] != null, 'Required key "UpdatePermissionRequest[description]" has a null value in JSON.');
        assert(json.containsKey(r'resourceType'), 'Required key "UpdatePermissionRequest[resourceType]" is missing from JSON.');
        assert(json[r'resourceType'] != null, 'Required key "UpdatePermissionRequest[resourceType]" has a null value in JSON.');
        assert(json.containsKey(r'actionType'), 'Required key "UpdatePermissionRequest[actionType]" is missing from JSON.');
        assert(json[r'actionType'] != null, 'Required key "UpdatePermissionRequest[actionType]" has a null value in JSON.');
        return true;
      }());

      return UpdatePermissionRequest(
        description: mapValueOfType<String>(json, r'description')!,
        resourceType: mapValueOfType<String>(json, r'resourceType')!,
        actionType: mapValueOfType<String>(json, r'actionType')!,
      );
    }
    return null;
  }

  static List<UpdatePermissionRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdatePermissionRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdatePermissionRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdatePermissionRequest> mapFromJson(dynamic json) {
    final map = <String, UpdatePermissionRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdatePermissionRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdatePermissionRequest-objects as value to a dart map
  static Map<String, List<UpdatePermissionRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdatePermissionRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdatePermissionRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'description',
    'resourceType',
    'actionType',
  };
}

