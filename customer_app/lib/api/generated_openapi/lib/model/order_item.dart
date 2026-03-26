//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OrderItem {
  /// Returns a new [OrderItem] instance.
  OrderItem({
    this.id,
    this.item,
    this.quantity,
    this.unitOfMeasurement,
    this.palletType,
    this.dimensions,
    this.weight,
    this.fromDestination,
    this.toDestination,
    this.warehouse,
    this.department,
    this.transportOrder,
    this.pickupAddress,
    this.dropAddress,
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
  Item? item;

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

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  TransportOrder? transportOrder;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  OrderAddress? pickupAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  OrderAddress? dropAddress;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OrderItem &&
    other.id == id &&
    other.item == item &&
    other.quantity == quantity &&
    other.unitOfMeasurement == unitOfMeasurement &&
    other.palletType == palletType &&
    other.dimensions == dimensions &&
    other.weight == weight &&
    other.fromDestination == fromDestination &&
    other.toDestination == toDestination &&
    other.warehouse == warehouse &&
    other.department == department &&
    other.transportOrder == transportOrder &&
    other.pickupAddress == pickupAddress &&
    other.dropAddress == dropAddress;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (item == null ? 0 : item!.hashCode) +
    (quantity == null ? 0 : quantity!.hashCode) +
    (unitOfMeasurement == null ? 0 : unitOfMeasurement!.hashCode) +
    (palletType == null ? 0 : palletType!.hashCode) +
    (dimensions == null ? 0 : dimensions!.hashCode) +
    (weight == null ? 0 : weight!.hashCode) +
    (fromDestination == null ? 0 : fromDestination!.hashCode) +
    (toDestination == null ? 0 : toDestination!.hashCode) +
    (warehouse == null ? 0 : warehouse!.hashCode) +
    (department == null ? 0 : department!.hashCode) +
    (transportOrder == null ? 0 : transportOrder!.hashCode) +
    (pickupAddress == null ? 0 : pickupAddress!.hashCode) +
    (dropAddress == null ? 0 : dropAddress!.hashCode);

  @override
  String toString() => 'OrderItem[id=$id, item=$item, quantity=$quantity, unitOfMeasurement=$unitOfMeasurement, palletType=$palletType, dimensions=$dimensions, weight=$weight, fromDestination=$fromDestination, toDestination=$toDestination, warehouse=$warehouse, department=$department, transportOrder=$transportOrder, pickupAddress=$pickupAddress, dropAddress=$dropAddress]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.item != null) {
      json[r'item'] = this.item;
    } else {
      json[r'item'] = null;
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
    if (this.transportOrder != null) {
      json[r'transportOrder'] = this.transportOrder;
    } else {
      json[r'transportOrder'] = null;
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
    return json;
  }

  /// Returns a new [OrderItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OrderItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return OrderItem(
        id: mapValueOfType<int>(json, r'id'),
        item: Item.fromJson(json[r'item']),
        quantity: mapValueOfType<double>(json, r'quantity'),
        unitOfMeasurement: mapValueOfType<String>(json, r'unitOfMeasurement'),
        palletType: mapValueOfType<double>(json, r'palletType'),
        dimensions: mapValueOfType<String>(json, r'dimensions'),
        weight: mapValueOfType<double>(json, r'weight'),
        fromDestination: mapValueOfType<String>(json, r'fromDestination'),
        toDestination: mapValueOfType<String>(json, r'toDestination'),
        warehouse: mapValueOfType<String>(json, r'warehouse'),
        department: mapValueOfType<String>(json, r'department'),
        transportOrder: TransportOrder.fromJson(json[r'transportOrder']),
        pickupAddress: OrderAddress.fromJson(json[r'pickupAddress']),
        dropAddress: OrderAddress.fromJson(json[r'dropAddress']),
      );
    }
    return null;
  }

  static List<OrderItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OrderItem> mapFromJson(dynamic json) {
    final map = <String, OrderItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OrderItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OrderItem-objects as value to a dart map
  static Map<String, List<OrderItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OrderItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OrderItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

