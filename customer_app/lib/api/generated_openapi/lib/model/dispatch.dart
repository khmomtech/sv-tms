//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Dispatch {
  /// Returns a new [Dispatch] instance.
  Dispatch({
    this.id,
    this.routeCode,
    this.trackingNo,
    this.truckTrip,
    this.fromLocation,
    this.toLocation,
    this.deliveryDate,
    this.customer,
    this.startTime,
    this.estimatedArrival,
    this.status,
    this.transportOrder,
    this.driver,
    this.vehicle,
    this.createdBy,
    this.tripType,
    this.createdDate,
    this.updatedDate,
    this.stops = const [],
    this.items = const [],
    this.cancelReason,
    this.loadProof,
    this.unloadProof,
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
  String? routeCode;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? trackingNo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? truckTrip;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fromLocation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? toLocation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? deliveryDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Customer? customer;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? startTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? estimatedArrival;

  DispatchStatusEnum? status;

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
  Driver? driver;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Vehicle? vehicle;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  User? createdBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tripType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedDate;

  List<DispatchStop> stops;

  List<DispatchItem> items;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? cancelReason;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  LoadProof? loadProof;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UnloadProof? unloadProof;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Dispatch &&
    other.id == id &&
    other.routeCode == routeCode &&
    other.trackingNo == trackingNo &&
    other.truckTrip == truckTrip &&
    other.fromLocation == fromLocation &&
    other.toLocation == toLocation &&
    other.deliveryDate == deliveryDate &&
    other.customer == customer &&
    other.startTime == startTime &&
    other.estimatedArrival == estimatedArrival &&
    other.status == status &&
    other.transportOrder == transportOrder &&
    other.driver == driver &&
    other.vehicle == vehicle &&
    other.createdBy == createdBy &&
    other.tripType == tripType &&
    other.createdDate == createdDate &&
    other.updatedDate == updatedDate &&
    _deepEquality.equals(other.stops, stops) &&
    _deepEquality.equals(other.items, items) &&
    other.cancelReason == cancelReason &&
    other.loadProof == loadProof &&
    other.unloadProof == unloadProof;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (routeCode == null ? 0 : routeCode!.hashCode) +
    (trackingNo == null ? 0 : trackingNo!.hashCode) +
    (truckTrip == null ? 0 : truckTrip!.hashCode) +
    (fromLocation == null ? 0 : fromLocation!.hashCode) +
    (toLocation == null ? 0 : toLocation!.hashCode) +
    (deliveryDate == null ? 0 : deliveryDate!.hashCode) +
    (customer == null ? 0 : customer!.hashCode) +
    (startTime == null ? 0 : startTime!.hashCode) +
    (estimatedArrival == null ? 0 : estimatedArrival!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (transportOrder == null ? 0 : transportOrder!.hashCode) +
    (driver == null ? 0 : driver!.hashCode) +
    (vehicle == null ? 0 : vehicle!.hashCode) +
    (createdBy == null ? 0 : createdBy!.hashCode) +
    (tripType == null ? 0 : tripType!.hashCode) +
    (createdDate == null ? 0 : createdDate!.hashCode) +
    (updatedDate == null ? 0 : updatedDate!.hashCode) +
    (stops.hashCode) +
    (items.hashCode) +
    (cancelReason == null ? 0 : cancelReason!.hashCode) +
    (loadProof == null ? 0 : loadProof!.hashCode) +
    (unloadProof == null ? 0 : unloadProof!.hashCode);

  @override
  String toString() => 'Dispatch[id=$id, routeCode=$routeCode, trackingNo=$trackingNo, truckTrip=$truckTrip, fromLocation=$fromLocation, toLocation=$toLocation, deliveryDate=$deliveryDate, customer=$customer, startTime=$startTime, estimatedArrival=$estimatedArrival, status=$status, transportOrder=$transportOrder, driver=$driver, vehicle=$vehicle, createdBy=$createdBy, tripType=$tripType, createdDate=$createdDate, updatedDate=$updatedDate, stops=$stops, items=$items, cancelReason=$cancelReason, loadProof=$loadProof, unloadProof=$unloadProof]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.routeCode != null) {
      json[r'routeCode'] = this.routeCode;
    } else {
      json[r'routeCode'] = null;
    }
    if (this.trackingNo != null) {
      json[r'trackingNo'] = this.trackingNo;
    } else {
      json[r'trackingNo'] = null;
    }
    if (this.truckTrip != null) {
      json[r'truckTrip'] = this.truckTrip;
    } else {
      json[r'truckTrip'] = null;
    }
    if (this.fromLocation != null) {
      json[r'fromLocation'] = this.fromLocation;
    } else {
      json[r'fromLocation'] = null;
    }
    if (this.toLocation != null) {
      json[r'toLocation'] = this.toLocation;
    } else {
      json[r'toLocation'] = null;
    }
    if (this.deliveryDate != null) {
      json[r'deliveryDate'] = _dateFormatter.format(this.deliveryDate!.toUtc());
    } else {
      json[r'deliveryDate'] = null;
    }
    if (this.customer != null) {
      json[r'customer'] = this.customer;
    } else {
      json[r'customer'] = null;
    }
    if (this.startTime != null) {
      json[r'startTime'] = this.startTime!.toUtc().toIso8601String();
    } else {
      json[r'startTime'] = null;
    }
    if (this.estimatedArrival != null) {
      json[r'estimatedArrival'] = this.estimatedArrival!.toUtc().toIso8601String();
    } else {
      json[r'estimatedArrival'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.transportOrder != null) {
      json[r'transportOrder'] = this.transportOrder;
    } else {
      json[r'transportOrder'] = null;
    }
    if (this.driver != null) {
      json[r'driver'] = this.driver;
    } else {
      json[r'driver'] = null;
    }
    if (this.vehicle != null) {
      json[r'vehicle'] = this.vehicle;
    } else {
      json[r'vehicle'] = null;
    }
    if (this.createdBy != null) {
      json[r'createdBy'] = this.createdBy;
    } else {
      json[r'createdBy'] = null;
    }
    if (this.tripType != null) {
      json[r'tripType'] = this.tripType;
    } else {
      json[r'tripType'] = null;
    }
    if (this.createdDate != null) {
      json[r'createdDate'] = this.createdDate!.toUtc().toIso8601String();
    } else {
      json[r'createdDate'] = null;
    }
    if (this.updatedDate != null) {
      json[r'updatedDate'] = this.updatedDate!.toUtc().toIso8601String();
    } else {
      json[r'updatedDate'] = null;
    }
      json[r'stops'] = this.stops;
      json[r'items'] = this.items;
    if (this.cancelReason != null) {
      json[r'cancelReason'] = this.cancelReason;
    } else {
      json[r'cancelReason'] = null;
    }
    if (this.loadProof != null) {
      json[r'loadProof'] = this.loadProof;
    } else {
      json[r'loadProof'] = null;
    }
    if (this.unloadProof != null) {
      json[r'unloadProof'] = this.unloadProof;
    } else {
      json[r'unloadProof'] = null;
    }
    return json;
  }

  /// Returns a new [Dispatch] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Dispatch? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return Dispatch(
        id: mapValueOfType<int>(json, r'id'),
        routeCode: mapValueOfType<String>(json, r'routeCode'),
        trackingNo: mapValueOfType<String>(json, r'trackingNo'),
        truckTrip: mapValueOfType<String>(json, r'truckTrip'),
        fromLocation: mapValueOfType<String>(json, r'fromLocation'),
        toLocation: mapValueOfType<String>(json, r'toLocation'),
        deliveryDate: mapDateTime(json, r'deliveryDate', r''),
        customer: Customer.fromJson(json[r'customer']),
        startTime: mapDateTime(json, r'startTime', r''),
        estimatedArrival: mapDateTime(json, r'estimatedArrival', r''),
        status: DispatchStatusEnum.fromJson(json[r'status']),
        transportOrder: TransportOrder.fromJson(json[r'transportOrder']),
        driver: Driver.fromJson(json[r'driver']),
        vehicle: Vehicle.fromJson(json[r'vehicle']),
        createdBy: User.fromJson(json[r'createdBy']),
        tripType: mapValueOfType<String>(json, r'tripType'),
        createdDate: mapDateTime(json, r'createdDate', r''),
        updatedDate: mapDateTime(json, r'updatedDate', r''),
        stops: DispatchStop.listFromJson(json[r'stops']),
        items: DispatchItem.listFromJson(json[r'items']),
        cancelReason: mapValueOfType<String>(json, r'cancelReason'),
        loadProof: LoadProof.fromJson(json[r'loadProof']),
        unloadProof: UnloadProof.fromJson(json[r'unloadProof']),
      );
    }
    return null;
  }

  static List<Dispatch> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Dispatch>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Dispatch.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Dispatch> mapFromJson(dynamic json) {
    final map = <String, Dispatch>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Dispatch.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Dispatch-objects as value to a dart map
  static Map<String, List<Dispatch>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Dispatch>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Dispatch.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class DispatchStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DispatchStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = DispatchStatusEnum._(r'PENDING');
  static const ASSIGNED = DispatchStatusEnum._(r'ASSIGNED');
  static const DRIVER_CONFIRMED = DispatchStatusEnum._(r'DRIVER_CONFIRMED');
  static const APPROVED = DispatchStatusEnum._(r'APPROVED');
  static const REJECTED = DispatchStatusEnum._(r'REJECTED');
  static const SCHEDULED = DispatchStatusEnum._(r'SCHEDULED');
  static const ARRIVED_LOADING = DispatchStatusEnum._(r'ARRIVED_LOADING');
  static const LOADING = DispatchStatusEnum._(r'LOADING');
  static const LOADED = DispatchStatusEnum._(r'LOADED');
  static const IN_TRANSIT = DispatchStatusEnum._(r'IN_TRANSIT');
  static const ARRIVED_UNLOADING = DispatchStatusEnum._(r'ARRIVED_UNLOADING');
  static const UNLOADING = DispatchStatusEnum._(r'UNLOADING');
  static const UNLOADED = DispatchStatusEnum._(r'UNLOADED');
  static const DELIVERED = DispatchStatusEnum._(r'DELIVERED');
  static const COMPLETED = DispatchStatusEnum._(r'COMPLETED');
  static const CANCELLED = DispatchStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][DispatchStatusEnum].
  static const values = <DispatchStatusEnum>[
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

  static DispatchStatusEnum? fromJson(dynamic value) => DispatchStatusEnumTypeTransformer().decode(value);

  static List<DispatchStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DispatchStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DispatchStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DispatchStatusEnum] to String,
/// and [decode] dynamic data back to [DispatchStatusEnum].
class DispatchStatusEnumTypeTransformer {
  factory DispatchStatusEnumTypeTransformer() => _instance ??= const DispatchStatusEnumTypeTransformer._();

  const DispatchStatusEnumTypeTransformer._();

  String encode(DispatchStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DispatchStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DispatchStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return DispatchStatusEnum.PENDING;
        case r'ASSIGNED': return DispatchStatusEnum.ASSIGNED;
        case r'DRIVER_CONFIRMED': return DispatchStatusEnum.DRIVER_CONFIRMED;
        case r'APPROVED': return DispatchStatusEnum.APPROVED;
        case r'REJECTED': return DispatchStatusEnum.REJECTED;
        case r'SCHEDULED': return DispatchStatusEnum.SCHEDULED;
        case r'ARRIVED_LOADING': return DispatchStatusEnum.ARRIVED_LOADING;
        case r'LOADING': return DispatchStatusEnum.LOADING;
        case r'LOADED': return DispatchStatusEnum.LOADED;
        case r'IN_TRANSIT': return DispatchStatusEnum.IN_TRANSIT;
        case r'ARRIVED_UNLOADING': return DispatchStatusEnum.ARRIVED_UNLOADING;
        case r'UNLOADING': return DispatchStatusEnum.UNLOADING;
        case r'UNLOADED': return DispatchStatusEnum.UNLOADED;
        case r'DELIVERED': return DispatchStatusEnum.DELIVERED;
        case r'COMPLETED': return DispatchStatusEnum.COMPLETED;
        case r'CANCELLED': return DispatchStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DispatchStatusEnumTypeTransformer] instance.
  static DispatchStatusEnumTypeTransformer? _instance;
}


