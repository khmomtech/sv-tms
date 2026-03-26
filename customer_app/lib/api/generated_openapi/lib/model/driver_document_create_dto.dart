//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverDocumentCreateDto {
  /// Returns a new [DriverDocumentCreateDto] instance.
  DriverDocumentCreateDto({
    this.name,
    this.category,
    this.expiryDate,
    this.description,
    this.isRequired,
    this.fileUrl,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? category;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? expiryDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isRequired;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fileUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverDocumentCreateDto &&
    other.name == name &&
    other.category == category &&
    other.expiryDate == expiryDate &&
    other.description == description &&
    other.isRequired == isRequired &&
    other.fileUrl == fileUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (category == null ? 0 : category!.hashCode) +
    (expiryDate == null ? 0 : expiryDate!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (isRequired == null ? 0 : isRequired!.hashCode) +
    (fileUrl == null ? 0 : fileUrl!.hashCode);

  @override
  String toString() => 'DriverDocumentCreateDto[name=$name, category=$category, expiryDate=$expiryDate, description=$description, isRequired=$isRequired, fileUrl=$fileUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.category != null) {
      json[r'category'] = this.category;
    } else {
      json[r'category'] = null;
    }
    if (this.expiryDate != null) {
      json[r'expiryDate'] = _dateFormatter.format(this.expiryDate!.toUtc());
    } else {
      json[r'expiryDate'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.isRequired != null) {
      json[r'isRequired'] = this.isRequired;
    } else {
      json[r'isRequired'] = null;
    }
    if (this.fileUrl != null) {
      json[r'fileUrl'] = this.fileUrl;
    } else {
      json[r'fileUrl'] = null;
    }
    return json;
  }

  /// Returns a new [DriverDocumentCreateDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverDocumentCreateDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DriverDocumentCreateDto(
        name: mapValueOfType<String>(json, r'name'),
        category: mapValueOfType<String>(json, r'category'),
        expiryDate: mapDateTime(json, r'expiryDate', r''),
        description: mapValueOfType<String>(json, r'description'),
        isRequired: mapValueOfType<bool>(json, r'isRequired'),
        fileUrl: mapValueOfType<String>(json, r'fileUrl'),
      );
    }
    return null;
  }

  static List<DriverDocumentCreateDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverDocumentCreateDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverDocumentCreateDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverDocumentCreateDto> mapFromJson(dynamic json) {
    final map = <String, DriverDocumentCreateDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverDocumentCreateDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverDocumentCreateDto-objects as value to a dart map
  static Map<String, List<DriverDocumentCreateDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverDocumentCreateDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverDocumentCreateDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

