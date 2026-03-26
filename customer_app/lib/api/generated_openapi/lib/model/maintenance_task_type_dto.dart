//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MaintenanceTaskTypeDto {
  /// Returns a new [MaintenanceTaskTypeDto] instance.
  MaintenanceTaskTypeDto({
    this.id,
    required this.name,
    this.description,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  String name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MaintenanceTaskTypeDto &&
    other.id == id &&
    other.name == name &&
    other.description == description;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (name.hashCode) +
    (description == null ? 0 : description!.hashCode);

  @override
  String toString() => 'MaintenanceTaskTypeDto[id=$id, name=$name, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'name'] = this.name;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    return json;
  }

  /// Returns a new [MaintenanceTaskTypeDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MaintenanceTaskTypeDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'name'), 'Required key "MaintenanceTaskTypeDto[name]" is missing from JSON.');
        assert(json[r'name'] != null, 'Required key "MaintenanceTaskTypeDto[name]" has a null value in JSON.');
        return true;
      }());

      return MaintenanceTaskTypeDto(
        id: mapValueOfType<int>(json, r'id'),
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description'),
      );
    }
    return null;
  }

  static List<MaintenanceTaskTypeDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MaintenanceTaskTypeDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MaintenanceTaskTypeDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MaintenanceTaskTypeDto> mapFromJson(dynamic json) {
    final map = <String, MaintenanceTaskTypeDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MaintenanceTaskTypeDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MaintenanceTaskTypeDto-objects as value to a dart map
  static Map<String, List<MaintenanceTaskTypeDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MaintenanceTaskTypeDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MaintenanceTaskTypeDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
  };
}

