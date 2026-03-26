//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ItemDto {
  /// Returns a new [ItemDto] instance.
  ItemDto({
    this.id,
    this.itemCode,
    this.itemName,
    this.itemNameKh,
    this.quantity,
    this.unit,
    this.size,
    this.weight,
    this.itemType,
    this.palletType,
    this.pallets,
    this.status,
    this.sortOrder,
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
  String? itemCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? itemName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? itemNameKh;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? quantity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unit;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? size;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? weight;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? itemType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? palletType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? pallets;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? sortOrder;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ItemDto &&
    other.id == id &&
    other.itemCode == itemCode &&
    other.itemName == itemName &&
    other.itemNameKh == itemNameKh &&
    other.quantity == quantity &&
    other.unit == unit &&
    other.size == size &&
    other.weight == weight &&
    other.itemType == itemType &&
    other.palletType == palletType &&
    other.pallets == pallets &&
    other.status == status &&
    other.sortOrder == sortOrder;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (itemCode == null ? 0 : itemCode!.hashCode) +
    (itemName == null ? 0 : itemName!.hashCode) +
    (itemNameKh == null ? 0 : itemNameKh!.hashCode) +
    (quantity == null ? 0 : quantity!.hashCode) +
    (unit == null ? 0 : unit!.hashCode) +
    (size == null ? 0 : size!.hashCode) +
    (weight == null ? 0 : weight!.hashCode) +
    (itemType == null ? 0 : itemType!.hashCode) +
    (palletType == null ? 0 : palletType!.hashCode) +
    (pallets == null ? 0 : pallets!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (sortOrder == null ? 0 : sortOrder!.hashCode);

  @override
  String toString() => 'ItemDto[id=$id, itemCode=$itemCode, itemName=$itemName, itemNameKh=$itemNameKh, quantity=$quantity, unit=$unit, size=$size, weight=$weight, itemType=$itemType, palletType=$palletType, pallets=$pallets, status=$status, sortOrder=$sortOrder]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.itemCode != null) {
      json[r'itemCode'] = this.itemCode;
    } else {
      json[r'itemCode'] = null;
    }
    if (this.itemName != null) {
      json[r'itemName'] = this.itemName;
    } else {
      json[r'itemName'] = null;
    }
    if (this.itemNameKh != null) {
      json[r'itemNameKh'] = this.itemNameKh;
    } else {
      json[r'itemNameKh'] = null;
    }
    if (this.quantity != null) {
      json[r'quantity'] = this.quantity;
    } else {
      json[r'quantity'] = null;
    }
    if (this.unit != null) {
      json[r'unit'] = this.unit;
    } else {
      json[r'unit'] = null;
    }
    if (this.size != null) {
      json[r'size'] = this.size;
    } else {
      json[r'size'] = null;
    }
    if (this.weight != null) {
      json[r'weight'] = this.weight;
    } else {
      json[r'weight'] = null;
    }
    if (this.itemType != null) {
      json[r'itemType'] = this.itemType;
    } else {
      json[r'itemType'] = null;
    }
    if (this.palletType != null) {
      json[r'palletType'] = this.palletType;
    } else {
      json[r'palletType'] = null;
    }
    if (this.pallets != null) {
      json[r'pallets'] = this.pallets;
    } else {
      json[r'pallets'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.sortOrder != null) {
      json[r'sortOrder'] = this.sortOrder;
    } else {
      json[r'sortOrder'] = null;
    }
    return json;
  }

  /// Returns a new [ItemDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ItemDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ItemDto(
        id: mapValueOfType<int>(json, r'id'),
        itemCode: mapValueOfType<String>(json, r'itemCode'),
        itemName: mapValueOfType<String>(json, r'itemName'),
        itemNameKh: mapValueOfType<String>(json, r'itemNameKh'),
        quantity: mapValueOfType<int>(json, r'quantity'),
        unit: mapValueOfType<String>(json, r'unit'),
        size: mapValueOfType<String>(json, r'size'),
        weight: mapValueOfType<String>(json, r'weight'),
        itemType: mapValueOfType<String>(json, r'itemType'),
        palletType: mapValueOfType<String>(json, r'palletType'),
        pallets: mapValueOfType<String>(json, r'pallets'),
        status: mapValueOfType<int>(json, r'status'),
        sortOrder: mapValueOfType<int>(json, r'sortOrder'),
      );
    }
    return null;
  }

  static List<ItemDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ItemDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ItemDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ItemDto> mapFromJson(dynamic json) {
    final map = <String, ItemDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ItemDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ItemDto-objects as value to a dart map
  static Map<String, List<ItemDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ItemDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ItemDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

