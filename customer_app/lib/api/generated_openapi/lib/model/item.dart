//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Item {
  /// Returns a new [Item] instance.
  Item({
    this.id,
    this.itemCode,
    this.itemName,
    this.itemNameKh,
    this.itemType,
    this.size,
    this.weight,
    this.unit,
    this.quantity,
    this.pallets,
    this.palletType,
    this.status,
    this.sortOrder,
    this.createdAt,
    this.updatedAt,
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

  ItemItemTypeEnum? itemType;

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
  String? unit;

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
  String? pallets;

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
  int? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? sortOrder;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Item &&
    other.id == id &&
    other.itemCode == itemCode &&
    other.itemName == itemName &&
    other.itemNameKh == itemNameKh &&
    other.itemType == itemType &&
    other.size == size &&
    other.weight == weight &&
    other.unit == unit &&
    other.quantity == quantity &&
    other.pallets == pallets &&
    other.palletType == palletType &&
    other.status == status &&
    other.sortOrder == sortOrder &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (itemCode == null ? 0 : itemCode!.hashCode) +
    (itemName == null ? 0 : itemName!.hashCode) +
    (itemNameKh == null ? 0 : itemNameKh!.hashCode) +
    (itemType == null ? 0 : itemType!.hashCode) +
    (size == null ? 0 : size!.hashCode) +
    (weight == null ? 0 : weight!.hashCode) +
    (unit == null ? 0 : unit!.hashCode) +
    (quantity == null ? 0 : quantity!.hashCode) +
    (pallets == null ? 0 : pallets!.hashCode) +
    (palletType == null ? 0 : palletType!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (sortOrder == null ? 0 : sortOrder!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode);

  @override
  String toString() => 'Item[id=$id, itemCode=$itemCode, itemName=$itemName, itemNameKh=$itemNameKh, itemType=$itemType, size=$size, weight=$weight, unit=$unit, quantity=$quantity, pallets=$pallets, palletType=$palletType, status=$status, sortOrder=$sortOrder, createdAt=$createdAt, updatedAt=$updatedAt]';

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
    if (this.itemType != null) {
      json[r'itemType'] = this.itemType;
    } else {
      json[r'itemType'] = null;
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
    if (this.unit != null) {
      json[r'unit'] = this.unit;
    } else {
      json[r'unit'] = null;
    }
    if (this.quantity != null) {
      json[r'quantity'] = this.quantity;
    } else {
      json[r'quantity'] = null;
    }
    if (this.pallets != null) {
      json[r'pallets'] = this.pallets;
    } else {
      json[r'pallets'] = null;
    }
    if (this.palletType != null) {
      json[r'palletType'] = this.palletType;
    } else {
      json[r'palletType'] = null;
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
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updatedAt'] = null;
    }
    return json;
  }

  /// Returns a new [Item] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Item? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return Item(
        id: mapValueOfType<int>(json, r'id'),
        itemCode: mapValueOfType<String>(json, r'itemCode'),
        itemName: mapValueOfType<String>(json, r'itemName'),
        itemNameKh: mapValueOfType<String>(json, r'itemNameKh'),
        itemType: ItemItemTypeEnum.fromJson(json[r'itemType']),
        size: mapValueOfType<String>(json, r'size'),
        weight: mapValueOfType<String>(json, r'weight'),
        unit: mapValueOfType<String>(json, r'unit'),
        quantity: mapValueOfType<int>(json, r'quantity'),
        pallets: mapValueOfType<String>(json, r'pallets'),
        palletType: mapValueOfType<String>(json, r'palletType'),
        status: mapValueOfType<int>(json, r'status'),
        sortOrder: mapValueOfType<int>(json, r'sortOrder'),
        createdAt: mapDateTime(json, r'createdAt', r''),
        updatedAt: mapDateTime(json, r'updatedAt', r''),
      );
    }
    return null;
  }

  static List<Item> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Item>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Item.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Item> mapFromJson(dynamic json) {
    final map = <String, Item>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Item.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Item-objects as value to a dart map
  static Map<String, List<Item>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Item>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Item.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class ItemItemTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const ItemItemTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const DOCUMENT = ItemItemTypeEnum._(r'DOCUMENT');
  static const ELECTRONICS = ItemItemTypeEnum._(r'ELECTRONICS');
  static const FURNITURE = ItemItemTypeEnum._(r'FURNITURE');
  static const FRAGILE = ItemItemTypeEnum._(r'FRAGILE');
  static const PERISHABLE = ItemItemTypeEnum._(r'PERISHABLE');
  static const HEAVY_EQUIPMENT = ItemItemTypeEnum._(r'HEAVY_EQUIPMENT');
  static const CLOTHING = ItemItemTypeEnum._(r'CLOTHING');
  static const PHARMACEUTICAL = ItemItemTypeEnum._(r'PHARMACEUTICAL');
  static const AUTOPARTS = ItemItemTypeEnum._(r'AUTOPARTS');
  static const CONSUMER_GOODS = ItemItemTypeEnum._(r'CONSUMER_GOODS');
  static const BEVERAGE = ItemItemTypeEnum._(r'BEVERAGE');
  static const OTHERS = ItemItemTypeEnum._(r'OTHERS');

  /// List of all possible values in this [enum][ItemItemTypeEnum].
  static const values = <ItemItemTypeEnum>[
    DOCUMENT,
    ELECTRONICS,
    FURNITURE,
    FRAGILE,
    PERISHABLE,
    HEAVY_EQUIPMENT,
    CLOTHING,
    PHARMACEUTICAL,
    AUTOPARTS,
    CONSUMER_GOODS,
    BEVERAGE,
    OTHERS,
  ];

  static ItemItemTypeEnum? fromJson(dynamic value) => ItemItemTypeEnumTypeTransformer().decode(value);

  static List<ItemItemTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ItemItemTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ItemItemTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ItemItemTypeEnum] to String,
/// and [decode] dynamic data back to [ItemItemTypeEnum].
class ItemItemTypeEnumTypeTransformer {
  factory ItemItemTypeEnumTypeTransformer() => _instance ??= const ItemItemTypeEnumTypeTransformer._();

  const ItemItemTypeEnumTypeTransformer._();

  String encode(ItemItemTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ItemItemTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ItemItemTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'DOCUMENT': return ItemItemTypeEnum.DOCUMENT;
        case r'ELECTRONICS': return ItemItemTypeEnum.ELECTRONICS;
        case r'FURNITURE': return ItemItemTypeEnum.FURNITURE;
        case r'FRAGILE': return ItemItemTypeEnum.FRAGILE;
        case r'PERISHABLE': return ItemItemTypeEnum.PERISHABLE;
        case r'HEAVY_EQUIPMENT': return ItemItemTypeEnum.HEAVY_EQUIPMENT;
        case r'CLOTHING': return ItemItemTypeEnum.CLOTHING;
        case r'PHARMACEUTICAL': return ItemItemTypeEnum.PHARMACEUTICAL;
        case r'AUTOPARTS': return ItemItemTypeEnum.AUTOPARTS;
        case r'CONSUMER_GOODS': return ItemItemTypeEnum.CONSUMER_GOODS;
        case r'BEVERAGE': return ItemItemTypeEnum.BEVERAGE;
        case r'OTHERS': return ItemItemTypeEnum.OTHERS;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ItemItemTypeEnumTypeTransformer] instance.
  static ItemItemTypeEnumTypeTransformer? _instance;
}


