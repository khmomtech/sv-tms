//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PartsMasterDto {
  /// Returns a new [PartsMasterDto] instance.
  PartsMasterDto({
    this.id,
    required this.partCode,
    required this.partName,
    required this.category,
    this.description,
    required this.unitPrice,
    required this.unit,
    this.supplier,
    this.manufacturer,
    this.active,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  String partCode;

  String partName;

  String category;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  /// Minimum value: 0.0
  double unitPrice;

  String unit;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? supplier;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? manufacturer;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? active;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PartsMasterDto &&
    other.id == id &&
    other.partCode == partCode &&
    other.partName == partName &&
    other.category == category &&
    other.description == description &&
    other.unitPrice == unitPrice &&
    other.unit == unit &&
    other.supplier == supplier &&
    other.manufacturer == manufacturer &&
    other.active == active;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (partCode.hashCode) +
    (partName.hashCode) +
    (category.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (unitPrice.hashCode) +
    (unit.hashCode) +
    (supplier == null ? 0 : supplier!.hashCode) +
    (manufacturer == null ? 0 : manufacturer!.hashCode) +
    (active == null ? 0 : active!.hashCode);

  @override
  String toString() => 'PartsMasterDto[id=$id, partCode=$partCode, partName=$partName, category=$category, description=$description, unitPrice=$unitPrice, unit=$unit, supplier=$supplier, manufacturer=$manufacturer, active=$active]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'partCode'] = this.partCode;
      json[r'partName'] = this.partName;
      json[r'category'] = this.category;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
      json[r'unitPrice'] = this.unitPrice;
      json[r'unit'] = this.unit;
    if (this.supplier != null) {
      json[r'supplier'] = this.supplier;
    } else {
      json[r'supplier'] = null;
    }
    if (this.manufacturer != null) {
      json[r'manufacturer'] = this.manufacturer;
    } else {
      json[r'manufacturer'] = null;
    }
    if (this.active != null) {
      json[r'active'] = this.active;
    } else {
      json[r'active'] = null;
    }
    return json;
  }

  /// Returns a new [PartsMasterDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PartsMasterDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'partCode'), 'Required key "PartsMasterDto[partCode]" is missing from JSON.');
        assert(json[r'partCode'] != null, 'Required key "PartsMasterDto[partCode]" has a null value in JSON.');
        assert(json.containsKey(r'partName'), 'Required key "PartsMasterDto[partName]" is missing from JSON.');
        assert(json[r'partName'] != null, 'Required key "PartsMasterDto[partName]" has a null value in JSON.');
        assert(json.containsKey(r'category'), 'Required key "PartsMasterDto[category]" is missing from JSON.');
        assert(json[r'category'] != null, 'Required key "PartsMasterDto[category]" has a null value in JSON.');
        assert(json.containsKey(r'unitPrice'), 'Required key "PartsMasterDto[unitPrice]" is missing from JSON.');
        assert(json[r'unitPrice'] != null, 'Required key "PartsMasterDto[unitPrice]" has a null value in JSON.');
        assert(json.containsKey(r'unit'), 'Required key "PartsMasterDto[unit]" is missing from JSON.');
        assert(json[r'unit'] != null, 'Required key "PartsMasterDto[unit]" has a null value in JSON.');
        return true;
      }());

      return PartsMasterDto(
        id: mapValueOfType<int>(json, r'id'),
        partCode: mapValueOfType<String>(json, r'partCode')!,
        partName: mapValueOfType<String>(json, r'partName')!,
        category: mapValueOfType<String>(json, r'category')!,
        description: mapValueOfType<String>(json, r'description'),
        unitPrice: mapValueOfType<double>(json, r'unitPrice')!,
        unit: mapValueOfType<String>(json, r'unit')!,
        supplier: mapValueOfType<String>(json, r'supplier'),
        manufacturer: mapValueOfType<String>(json, r'manufacturer'),
        active: mapValueOfType<bool>(json, r'active'),
      );
    }
    return null;
  }

  static List<PartsMasterDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PartsMasterDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PartsMasterDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PartsMasterDto> mapFromJson(dynamic json) {
    final map = <String, PartsMasterDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PartsMasterDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PartsMasterDto-objects as value to a dart map
  static Map<String, List<PartsMasterDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PartsMasterDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PartsMasterDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'partCode',
    'partName',
    'category',
    'unitPrice',
    'unit',
  };
}

