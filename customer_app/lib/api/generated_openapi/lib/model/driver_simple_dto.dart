//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverSimpleDto {
  /// Returns a new [DriverSimpleDto] instance.
  DriverSimpleDto({
    this.id,
    this.fullName,
    this.phone,
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
  String? fullName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? phone;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverSimpleDto &&
    other.id == id &&
    other.fullName == fullName &&
    other.phone == phone;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (fullName == null ? 0 : fullName!.hashCode) +
    (phone == null ? 0 : phone!.hashCode);

  @override
  String toString() => 'DriverSimpleDto[id=$id, fullName=$fullName, phone=$phone]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.fullName != null) {
      json[r'fullName'] = this.fullName;
    } else {
      json[r'fullName'] = null;
    }
    if (this.phone != null) {
      json[r'phone'] = this.phone;
    } else {
      json[r'phone'] = null;
    }
    return json;
  }

  /// Returns a new [DriverSimpleDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverSimpleDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DriverSimpleDto(
        id: mapValueOfType<int>(json, r'id'),
        fullName: mapValueOfType<String>(json, r'fullName'),
        phone: mapValueOfType<String>(json, r'phone'),
      );
    }
    return null;
  }

  static List<DriverSimpleDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverSimpleDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverSimpleDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverSimpleDto> mapFromJson(dynamic json) {
    final map = <String, DriverSimpleDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverSimpleDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverSimpleDto-objects as value to a dart map
  static Map<String, List<DriverSimpleDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverSimpleDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverSimpleDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

