//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Order {
  /// Returns a new [Order] instance.
  Order({
    this.id,
    this.orderNumber,
    this.customerName,
    this.deliveryAddress,
    this.pickupAddress,
    this.createdAt,
    this.status,
    this.assignedVehicle,
    this.assignedDriver,
    this.proofOfDelivery,
    this.shipments = const [],
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
  String? orderNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? customerName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? deliveryAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? pickupAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  OrderStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? assignedVehicle;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? assignedDriver;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? proofOfDelivery;

  List<Shipment> shipments;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Order &&
    other.id == id &&
    other.orderNumber == orderNumber &&
    other.customerName == customerName &&
    other.deliveryAddress == deliveryAddress &&
    other.pickupAddress == pickupAddress &&
    other.createdAt == createdAt &&
    other.status == status &&
    other.assignedVehicle == assignedVehicle &&
    other.assignedDriver == assignedDriver &&
    other.proofOfDelivery == proofOfDelivery &&
    _deepEquality.equals(other.shipments, shipments);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (orderNumber == null ? 0 : orderNumber!.hashCode) +
    (customerName == null ? 0 : customerName!.hashCode) +
    (deliveryAddress == null ? 0 : deliveryAddress!.hashCode) +
    (pickupAddress == null ? 0 : pickupAddress!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (assignedVehicle == null ? 0 : assignedVehicle!.hashCode) +
    (assignedDriver == null ? 0 : assignedDriver!.hashCode) +
    (proofOfDelivery == null ? 0 : proofOfDelivery!.hashCode) +
    (shipments.hashCode);

  @override
  String toString() => 'Order[id=$id, orderNumber=$orderNumber, customerName=$customerName, deliveryAddress=$deliveryAddress, pickupAddress=$pickupAddress, createdAt=$createdAt, status=$status, assignedVehicle=$assignedVehicle, assignedDriver=$assignedDriver, proofOfDelivery=$proofOfDelivery, shipments=$shipments]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.orderNumber != null) {
      json[r'orderNumber'] = this.orderNumber;
    } else {
      json[r'orderNumber'] = null;
    }
    if (this.customerName != null) {
      json[r'customerName'] = this.customerName;
    } else {
      json[r'customerName'] = null;
    }
    if (this.deliveryAddress != null) {
      json[r'deliveryAddress'] = this.deliveryAddress;
    } else {
      json[r'deliveryAddress'] = null;
    }
    if (this.pickupAddress != null) {
      json[r'pickupAddress'] = this.pickupAddress;
    } else {
      json[r'pickupAddress'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.assignedVehicle != null) {
      json[r'assignedVehicle'] = this.assignedVehicle;
    } else {
      json[r'assignedVehicle'] = null;
    }
    if (this.assignedDriver != null) {
      json[r'assignedDriver'] = this.assignedDriver;
    } else {
      json[r'assignedDriver'] = null;
    }
    if (this.proofOfDelivery != null) {
      json[r'proofOfDelivery'] = this.proofOfDelivery;
    } else {
      json[r'proofOfDelivery'] = null;
    }
      json[r'shipments'] = this.shipments;
    return json;
  }

  /// Returns a new [Order] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Order? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return Order(
        id: mapValueOfType<int>(json, r'id'),
        orderNumber: mapValueOfType<String>(json, r'orderNumber'),
        customerName: mapValueOfType<String>(json, r'customerName'),
        deliveryAddress: mapValueOfType<String>(json, r'deliveryAddress'),
        pickupAddress: mapValueOfType<String>(json, r'pickupAddress'),
        createdAt: mapDateTime(json, r'createdAt', r''),
        status: OrderStatusEnum.fromJson(json[r'status']),
        assignedVehicle: mapValueOfType<String>(json, r'assignedVehicle'),
        assignedDriver: mapValueOfType<String>(json, r'assignedDriver'),
        proofOfDelivery: mapValueOfType<String>(json, r'proofOfDelivery'),
        shipments: Shipment.listFromJson(json[r'shipments']),
      );
    }
    return null;
  }

  static List<Order> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Order>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Order.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Order> mapFromJson(dynamic json) {
    final map = <String, Order>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Order.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Order-objects as value to a dart map
  static Map<String, List<Order>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Order>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Order.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class OrderStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const OrderStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = OrderStatusEnum._(r'PENDING');
  static const ASSIGNED = OrderStatusEnum._(r'ASSIGNED');
  static const DRIVER_CONFIRMED = OrderStatusEnum._(r'DRIVER_CONFIRMED');
  static const APPROVED = OrderStatusEnum._(r'APPROVED');
  static const REJECTED = OrderStatusEnum._(r'REJECTED');
  static const SCHEDULED = OrderStatusEnum._(r'SCHEDULED');
  static const ARRIVED_LOADING = OrderStatusEnum._(r'ARRIVED_LOADING');
  static const LOADING = OrderStatusEnum._(r'LOADING');
  static const LOADED = OrderStatusEnum._(r'LOADED');
  static const IN_TRANSIT = OrderStatusEnum._(r'IN_TRANSIT');
  static const ARRIVED_UNLOADING = OrderStatusEnum._(r'ARRIVED_UNLOADING');
  static const UNLOADING = OrderStatusEnum._(r'UNLOADING');
  static const UNLOADED = OrderStatusEnum._(r'UNLOADED');
  static const DELIVERED = OrderStatusEnum._(r'DELIVERED');
  static const COMPLETED = OrderStatusEnum._(r'COMPLETED');
  static const CANCELLED = OrderStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][OrderStatusEnum].
  static const values = <OrderStatusEnum>[
    PENDING,
    ASSIGNED,
    DRIVER_CONFIRMED,
    APPROVED,
    REJECTED,
    SCHEDULED,
    ARRIVED_LOADING,
    LOADING,
    LOADED,
    IN_TRANSIT,
    ARRIVED_UNLOADING,
    UNLOADING,
    UNLOADED,
    DELIVERED,
    COMPLETED,
    CANCELLED,
  ];

  static OrderStatusEnum? fromJson(dynamic value) => OrderStatusEnumTypeTransformer().decode(value);

  static List<OrderStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [OrderStatusEnum] to String,
/// and [decode] dynamic data back to [OrderStatusEnum].
class OrderStatusEnumTypeTransformer {
  factory OrderStatusEnumTypeTransformer() => _instance ??= const OrderStatusEnumTypeTransformer._();

  const OrderStatusEnumTypeTransformer._();

  String encode(OrderStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a OrderStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  OrderStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return OrderStatusEnum.PENDING;
        case r'ASSIGNED': return OrderStatusEnum.ASSIGNED;
        case r'DRIVER_CONFIRMED': return OrderStatusEnum.DRIVER_CONFIRMED;
        case r'APPROVED': return OrderStatusEnum.APPROVED;
        case r'REJECTED': return OrderStatusEnum.REJECTED;
        case r'SCHEDULED': return OrderStatusEnum.SCHEDULED;
        case r'ARRIVED_LOADING': return OrderStatusEnum.ARRIVED_LOADING;
        case r'LOADING': return OrderStatusEnum.LOADING;
        case r'LOADED': return OrderStatusEnum.LOADED;
        case r'IN_TRANSIT': return OrderStatusEnum.IN_TRANSIT;
        case r'ARRIVED_UNLOADING': return OrderStatusEnum.ARRIVED_UNLOADING;
        case r'UNLOADING': return OrderStatusEnum.UNLOADING;
        case r'UNLOADED': return OrderStatusEnum.UNLOADED;
        case r'DELIVERED': return OrderStatusEnum.DELIVERED;
        case r'COMPLETED': return OrderStatusEnum.COMPLETED;
        case r'CANCELLED': return OrderStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [OrderStatusEnumTypeTransformer] instance.
  static OrderStatusEnumTypeTransformer? _instance;
}


