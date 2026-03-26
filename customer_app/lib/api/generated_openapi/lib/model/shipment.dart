//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Shipment {
  /// Returns a new [Shipment] instance.
  Shipment({
    this.id,
    this.order,
    this.trackingNumber,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
    this.shipmentStatus,
    this.assignedVehicle,
    this.assignedDriver,
    this.proofOfDelivery,
    this.loadingAddresses = const [],
    this.dropAddresses = const [],
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
  Order? order;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? trackingNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? estimatedDeliveryDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? actualDeliveryDate;

  ShipmentShipmentStatusEnum? shipmentStatus;

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

  List<LoadingAddress> loadingAddresses;

  List<DropAddress> dropAddresses;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Shipment &&
    other.id == id &&
    other.order == order &&
    other.trackingNumber == trackingNumber &&
    other.estimatedDeliveryDate == estimatedDeliveryDate &&
    other.actualDeliveryDate == actualDeliveryDate &&
    other.shipmentStatus == shipmentStatus &&
    other.assignedVehicle == assignedVehicle &&
    other.assignedDriver == assignedDriver &&
    other.proofOfDelivery == proofOfDelivery &&
    _deepEquality.equals(other.loadingAddresses, loadingAddresses) &&
    _deepEquality.equals(other.dropAddresses, dropAddresses);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (order == null ? 0 : order!.hashCode) +
    (trackingNumber == null ? 0 : trackingNumber!.hashCode) +
    (estimatedDeliveryDate == null ? 0 : estimatedDeliveryDate!.hashCode) +
    (actualDeliveryDate == null ? 0 : actualDeliveryDate!.hashCode) +
    (shipmentStatus == null ? 0 : shipmentStatus!.hashCode) +
    (assignedVehicle == null ? 0 : assignedVehicle!.hashCode) +
    (assignedDriver == null ? 0 : assignedDriver!.hashCode) +
    (proofOfDelivery == null ? 0 : proofOfDelivery!.hashCode) +
    (loadingAddresses.hashCode) +
    (dropAddresses.hashCode);

  @override
  String toString() => 'Shipment[id=$id, order=$order, trackingNumber=$trackingNumber, estimatedDeliveryDate=$estimatedDeliveryDate, actualDeliveryDate=$actualDeliveryDate, shipmentStatus=$shipmentStatus, assignedVehicle=$assignedVehicle, assignedDriver=$assignedDriver, proofOfDelivery=$proofOfDelivery, loadingAddresses=$loadingAddresses, dropAddresses=$dropAddresses]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.order != null) {
      json[r'order'] = this.order;
    } else {
      json[r'order'] = null;
    }
    if (this.trackingNumber != null) {
      json[r'trackingNumber'] = this.trackingNumber;
    } else {
      json[r'trackingNumber'] = null;
    }
    if (this.estimatedDeliveryDate != null) {
      json[r'estimatedDeliveryDate'] = this.estimatedDeliveryDate!.toUtc().toIso8601String();
    } else {
      json[r'estimatedDeliveryDate'] = null;
    }
    if (this.actualDeliveryDate != null) {
      json[r'actualDeliveryDate'] = this.actualDeliveryDate!.toUtc().toIso8601String();
    } else {
      json[r'actualDeliveryDate'] = null;
    }
    if (this.shipmentStatus != null) {
      json[r'shipmentStatus'] = this.shipmentStatus;
    } else {
      json[r'shipmentStatus'] = null;
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
      json[r'loadingAddresses'] = this.loadingAddresses;
      json[r'dropAddresses'] = this.dropAddresses;
    return json;
  }

  /// Returns a new [Shipment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Shipment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return Shipment(
        id: mapValueOfType<int>(json, r'id'),
        order: Order.fromJson(json[r'order']),
        trackingNumber: mapValueOfType<String>(json, r'trackingNumber'),
        estimatedDeliveryDate: mapDateTime(json, r'estimatedDeliveryDate', r''),
        actualDeliveryDate: mapDateTime(json, r'actualDeliveryDate', r''),
        shipmentStatus: ShipmentShipmentStatusEnum.fromJson(json[r'shipmentStatus']),
        assignedVehicle: mapValueOfType<String>(json, r'assignedVehicle'),
        assignedDriver: mapValueOfType<String>(json, r'assignedDriver'),
        proofOfDelivery: mapValueOfType<String>(json, r'proofOfDelivery'),
        loadingAddresses: LoadingAddress.listFromJson(json[r'loadingAddresses']),
        dropAddresses: DropAddress.listFromJson(json[r'dropAddresses']),
      );
    }
    return null;
  }

  static List<Shipment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Shipment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Shipment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Shipment> mapFromJson(dynamic json) {
    final map = <String, Shipment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Shipment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Shipment-objects as value to a dart map
  static Map<String, List<Shipment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Shipment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Shipment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class ShipmentShipmentStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const ShipmentShipmentStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = ShipmentShipmentStatusEnum._(r'PENDING');
  static const ASSIGNED = ShipmentShipmentStatusEnum._(r'ASSIGNED');
  static const DRIVER_CONFIRMED = ShipmentShipmentStatusEnum._(r'DRIVER_CONFIRMED');
  static const APPROVED = ShipmentShipmentStatusEnum._(r'APPROVED');
  static const REJECTED = ShipmentShipmentStatusEnum._(r'REJECTED');
  static const SCHEDULED = ShipmentShipmentStatusEnum._(r'SCHEDULED');
  static const ARRIVED_LOADING = ShipmentShipmentStatusEnum._(r'ARRIVED_LOADING');
  static const LOADING = ShipmentShipmentStatusEnum._(r'LOADING');
  static const LOADED = ShipmentShipmentStatusEnum._(r'LOADED');
  static const IN_TRANSIT = ShipmentShipmentStatusEnum._(r'IN_TRANSIT');
  static const ARRIVED_UNLOADING = ShipmentShipmentStatusEnum._(r'ARRIVED_UNLOADING');
  static const UNLOADING = ShipmentShipmentStatusEnum._(r'UNLOADING');
  static const UNLOADED = ShipmentShipmentStatusEnum._(r'UNLOADED');
  static const DELIVERED = ShipmentShipmentStatusEnum._(r'DELIVERED');
  static const COMPLETED = ShipmentShipmentStatusEnum._(r'COMPLETED');
  static const CANCELLED = ShipmentShipmentStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][ShipmentShipmentStatusEnum].
  static const values = <ShipmentShipmentStatusEnum>[
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

  static ShipmentShipmentStatusEnum? fromJson(dynamic value) => ShipmentShipmentStatusEnumTypeTransformer().decode(value);

  static List<ShipmentShipmentStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ShipmentShipmentStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ShipmentShipmentStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ShipmentShipmentStatusEnum] to String,
/// and [decode] dynamic data back to [ShipmentShipmentStatusEnum].
class ShipmentShipmentStatusEnumTypeTransformer {
  factory ShipmentShipmentStatusEnumTypeTransformer() => _instance ??= const ShipmentShipmentStatusEnumTypeTransformer._();

  const ShipmentShipmentStatusEnumTypeTransformer._();

  String encode(ShipmentShipmentStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ShipmentShipmentStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ShipmentShipmentStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return ShipmentShipmentStatusEnum.PENDING;
        case r'ASSIGNED': return ShipmentShipmentStatusEnum.ASSIGNED;
        case r'DRIVER_CONFIRMED': return ShipmentShipmentStatusEnum.DRIVER_CONFIRMED;
        case r'APPROVED': return ShipmentShipmentStatusEnum.APPROVED;
        case r'REJECTED': return ShipmentShipmentStatusEnum.REJECTED;
        case r'SCHEDULED': return ShipmentShipmentStatusEnum.SCHEDULED;
        case r'ARRIVED_LOADING': return ShipmentShipmentStatusEnum.ARRIVED_LOADING;
        case r'LOADING': return ShipmentShipmentStatusEnum.LOADING;
        case r'LOADED': return ShipmentShipmentStatusEnum.LOADED;
        case r'IN_TRANSIT': return ShipmentShipmentStatusEnum.IN_TRANSIT;
        case r'ARRIVED_UNLOADING': return ShipmentShipmentStatusEnum.ARRIVED_UNLOADING;
        case r'UNLOADING': return ShipmentShipmentStatusEnum.UNLOADING;
        case r'UNLOADED': return ShipmentShipmentStatusEnum.UNLOADED;
        case r'DELIVERED': return ShipmentShipmentStatusEnum.DELIVERED;
        case r'COMPLETED': return ShipmentShipmentStatusEnum.COMPLETED;
        case r'CANCELLED': return ShipmentShipmentStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ShipmentShipmentStatusEnumTypeTransformer] instance.
  static ShipmentShipmentStatusEnumTypeTransformer? _instance;
}


