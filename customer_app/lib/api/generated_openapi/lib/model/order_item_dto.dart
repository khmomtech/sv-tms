//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OrderItemDto {
  /// Returns a new [OrderItemDto] instance.
  OrderItemDto({
    this.id,
    this.itemId,
    this.itemCode,
    this.itemType,
    this.itemName,
    this.itemNameKh,
    this.quantity,
    this.unitOfMeasurement,
    this.palletType,
    this.dimensions,
    this.weight,
    this.pickupAddress,
    this.dropAddress,
    this.fromDestination,
    this.toDestination,
    this.warehouse,
    this.department,
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
  int? itemId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? itemCode;

  OrderItemDtoItemTypeEnum? itemType;

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
  double? quantity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unitOfMeasurement;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? palletType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? dimensions;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? weight;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  OrderAddressDto? pickupAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  OrderAddressDto? dropAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fromDestination;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? toDestination;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? warehouse;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? department;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OrderItemDto &&
    other.id == id &&
    other.itemId == itemId &&
    other.itemCode == itemCode &&
    other.itemType == itemType &&
    other.itemName == itemName &&
    other.itemNameKh == itemNameKh &&
    other.quantity == quantity &&
    other.unitOfMeasurement == unitOfMeasurement &&
    other.palletType == palletType &&
    other.dimensions == dimensions &&
    other.weight == weight &&
    other.pickupAddress == pickupAddress &&
    other.dropAddress == dropAddress &&
    other.fromDestination == fromDestination &&
    other.toDestination == toDestination &&
    other.warehouse == warehouse &&
    other.department == department;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (itemId == null ? 0 : itemId!.hashCode) +
    (itemCode == null ? 0 : itemCode!.hashCode) +
    (itemType == null ? 0 : itemType!.hashCode) +
    (itemName == null ? 0 : itemName!.hashCode) +
    (itemNameKh == null ? 0 : itemNameKh!.hashCode) +
    (quantity == null ? 0 : quantity!.hashCode) +
    (unitOfMeasurement == null ? 0 : unitOfMeasurement!.hashCode) +
    (palletType == null ? 0 : palletType!.hashCode) +
    (dimensions == null ? 0 : dimensions!.hashCode) +
    (weight == null ? 0 : weight!.hashCode) +
    (pickupAddress == null ? 0 : pickupAddress!.hashCode) +
    (dropAddress == null ? 0 : dropAddress!.hashCode) +
    (fromDestination == null ? 0 : fromDestination!.hashCode) +
    (toDestination == null ? 0 : toDestination!.hashCode) +
    (warehouse == null ? 0 : warehouse!.hashCode) +
    (department == null ? 0 : department!.hashCode);

  @override
  String toString() => 'OrderItemDto[id=$id, itemId=$itemId, itemCode=$itemCode, itemType=$itemType, itemName=$itemName, itemNameKh=$itemNameKh, quantity=$quantity, unitOfMeasurement=$unitOfMeasurement, palletType=$palletType, dimensions=$dimensions, weight=$weight, pickupAddress=$pickupAddress, dropAddress=$dropAddress, fromDestination=$fromDestination, toDestination=$toDestination, warehouse=$warehouse, department=$department]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.itemId != null) {
      json[r'itemId'] = this.itemId;
    } else {
      json[r'itemId'] = null;
    }
    if (this.itemCode != null) {
      json[r'itemCode'] = this.itemCode;
    } else {
      json[r'itemCode'] = null;
    }
    if (this.itemType != null) {
      json[r'itemType'] = this.itemType;
    } else {
      json[r'itemType'] = null;
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
    if (this.unitOfMeasurement != null) {
      json[r'unitOfMeasurement'] = this.unitOfMeasurement;
    } else {
      json[r'unitOfMeasurement'] = null;
    }
    if (this.palletType != null) {
      json[r'palletType'] = this.palletType;
    } else {
      json[r'palletType'] = null;
    }
    if (this.dimensions != null) {
      json[r'dimensions'] = this.dimensions;
    } else {
      json[r'dimensions'] = null;
    }
    if (this.weight != null) {
      json[r'weight'] = this.weight;
    } else {
      json[r'weight'] = null;
    }
    if (this.pickupAddress != null) {
      json[r'pickupAddress'] = this.pickupAddress;
    } else {
      json[r'pickupAddress'] = null;
    }
    if (this.dropAddress != null) {
      json[r'dropAddress'] = this.dropAddress;
    } else {
      json[r'dropAddress'] = null;
    }
    if (this.fromDestination != null) {
      json[r'fromDestination'] = this.fromDestination;
    } else {
      json[r'fromDestination'] = null;
    }
    if (this.toDestination != null) {
      json[r'toDestination'] = this.toDestination;
    } else {
      json[r'toDestination'] = null;
    }
    if (this.warehouse != null) {
      json[r'warehouse'] = this.warehouse;
    } else {
      json[r'warehouse'] = null;
    }
    if (this.department != null) {
      json[r'department'] = this.department;
    } else {
      json[r'department'] = null;
    }
    return json;
  }

  /// Returns a new [OrderItemDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OrderItemDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return OrderItemDto(
        id: mapValueOfType<int>(json, r'id'),
        itemId: mapValueOfType<int>(json, r'itemId'),
        itemCode: mapValueOfType<String>(json, r'itemCode'),
        itemType: OrderItemDtoItemTypeEnum.fromJson(json[r'itemType']),
        itemName: mapValueOfType<String>(json, r'itemName'),
        itemNameKh: mapValueOfType<String>(json, r'itemNameKh'),
        quantity: mapValueOfType<double>(json, r'quantity'),
        unitOfMeasurement: mapValueOfType<String>(json, r'unitOfMeasurement'),
        palletType: mapValueOfType<double>(json, r'palletType'),
        dimensions: mapValueOfType<String>(json, r'dimensions'),
        weight: mapValueOfType<double>(json, r'weight'),
        pickupAddress: OrderAddressDto.fromJson(json[r'pickupAddress']),
        dropAddress: OrderAddressDto.fromJson(json[r'dropAddress']),
        fromDestination: mapValueOfType<String>(json, r'fromDestination'),
        toDestination: mapValueOfType<String>(json, r'toDestination'),
        warehouse: mapValueOfType<String>(json, r'warehouse'),
        department: mapValueOfType<String>(json, r'department'),
      );
    }
    return null;
  }

  static List<OrderItemDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderItemDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderItemDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OrderItemDto> mapFromJson(dynamic json) {
    final map = <String, OrderItemDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OrderItemDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OrderItemDto-objects as value to a dart map
  static Map<String, List<OrderItemDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OrderItemDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OrderItemDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class OrderItemDtoItemTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const OrderItemDtoItemTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const DOCUMENT = OrderItemDtoItemTypeEnum._(r'DOCUMENT');
  static const ELECTRONICS = OrderItemDtoItemTypeEnum._(r'ELECTRONICS');
  static const FURNITURE = OrderItemDtoItemTypeEnum._(r'FURNITURE');
  static const FRAGILE = OrderItemDtoItemTypeEnum._(r'FRAGILE');
  static const PERISHABLE = OrderItemDtoItemTypeEnum._(r'PERISHABLE');
  static const HEAVY_EQUIPMENT = OrderItemDtoItemTypeEnum._(r'HEAVY_EQUIPMENT');
  static const CLOTHING = OrderItemDtoItemTypeEnum._(r'CLOTHING');
  static const PHARMACEUTICAL = OrderItemDtoItemTypeEnum._(r'PHARMACEUTICAL');
  static const AUTOPARTS = OrderItemDtoItemTypeEnum._(r'AUTOPARTS');
  static const CONSUMER_GOODS = OrderItemDtoItemTypeEnum._(r'CONSUMER_GOODS');
  static const BEVERAGE = OrderItemDtoItemTypeEnum._(r'BEVERAGE');
  static const OTHERS = OrderItemDtoItemTypeEnum._(r'OTHERS');

  /// List of all possible values in this [enum][OrderItemDtoItemTypeEnum].
  static const values = <OrderItemDtoItemTypeEnum>[
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

  static OrderItemDtoItemTypeEnum? fromJson(dynamic value) => OrderItemDtoItemTypeEnumTypeTransformer().decode(value);

  static List<OrderItemDtoItemTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderItemDtoItemTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderItemDtoItemTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [OrderItemDtoItemTypeEnum] to String,
/// and [decode] dynamic data back to [OrderItemDtoItemTypeEnum].
class OrderItemDtoItemTypeEnumTypeTransformer {
  factory OrderItemDtoItemTypeEnumTypeTransformer() => _instance ??= const OrderItemDtoItemTypeEnumTypeTransformer._();

  const OrderItemDtoItemTypeEnumTypeTransformer._();

  String encode(OrderItemDtoItemTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a OrderItemDtoItemTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  OrderItemDtoItemTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'DOCUMENT': return OrderItemDtoItemTypeEnum.DOCUMENT;
        case r'ELECTRONICS': return OrderItemDtoItemTypeEnum.ELECTRONICS;
        case r'FURNITURE': return OrderItemDtoItemTypeEnum.FURNITURE;
        case r'FRAGILE': return OrderItemDtoItemTypeEnum.FRAGILE;
        case r'PERISHABLE': return OrderItemDtoItemTypeEnum.PERISHABLE;
        case r'HEAVY_EQUIPMENT': return OrderItemDtoItemTypeEnum.HEAVY_EQUIPMENT;
        case r'CLOTHING': return OrderItemDtoItemTypeEnum.CLOTHING;
        case r'PHARMACEUTICAL': return OrderItemDtoItemTypeEnum.PHARMACEUTICAL;
        case r'AUTOPARTS': return OrderItemDtoItemTypeEnum.AUTOPARTS;
        case r'CONSUMER_GOODS': return OrderItemDtoItemTypeEnum.CONSUMER_GOODS;
        case r'BEVERAGE': return OrderItemDtoItemTypeEnum.BEVERAGE;
        case r'OTHERS': return OrderItemDtoItemTypeEnum.OTHERS;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [OrderItemDtoItemTypeEnumTypeTransformer] instance.
  static OrderItemDtoItemTypeEnumTypeTransformer? _instance;
}


