//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TransportOrder {
  /// Returns a new [TransportOrder] instance.
  TransportOrder({
    this.id,
    this.version,
    this.orderReference,
    this.customer,
    this.billTo,
    this.orderDate,
    this.deliveryDate,
    this.shipmentType,
    this.courierAssigned,
    this.tripNo,
    this.truckNumber,
    this.truckTripCount,
    this.status,
    this.createdBy,
    this.seller,
    this.items = const [],
    this.pickupAddress,
    this.dropAddress,
    this.pickupAddresses = const [],
    this.dropAddresses = const [],
    this.dispatches = const [],
    this.invoice,
    this.stops = const [],
    this.remark,
    this.createdAt,
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
  int? version;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? orderReference;

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
  String? billTo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? orderDate;

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
  String? shipmentType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? courierAssigned;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? tripNo;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? truckNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? truckTripCount;

  TransportOrderStatusEnum? status;

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
  Employee? seller;

  List<OrderItem> items;

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

  List<OrderAddress> pickupAddresses;

  List<OrderAddress> dropAddresses;

  List<Dispatch> dispatches;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Invoice? invoice;

  List<OrderStop> stops;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? remark;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TransportOrder &&
    other.id == id &&
    other.version == version &&
    other.orderReference == orderReference &&
    other.customer == customer &&
    other.billTo == billTo &&
    other.orderDate == orderDate &&
    other.deliveryDate == deliveryDate &&
    other.shipmentType == shipmentType &&
    other.courierAssigned == courierAssigned &&
    other.tripNo == tripNo &&
    other.truckNumber == truckNumber &&
    other.truckTripCount == truckTripCount &&
    other.status == status &&
    other.createdBy == createdBy &&
    other.seller == seller &&
    _deepEquality.equals(other.items, items) &&
    other.pickupAddress == pickupAddress &&
    other.dropAddress == dropAddress &&
    _deepEquality.equals(other.pickupAddresses, pickupAddresses) &&
    _deepEquality.equals(other.dropAddresses, dropAddresses) &&
    _deepEquality.equals(other.dispatches, dispatches) &&
    other.invoice == invoice &&
    _deepEquality.equals(other.stops, stops) &&
    other.remark == remark &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (version == null ? 0 : version!.hashCode) +
    (orderReference == null ? 0 : orderReference!.hashCode) +
    (customer == null ? 0 : customer!.hashCode) +
    (billTo == null ? 0 : billTo!.hashCode) +
    (orderDate == null ? 0 : orderDate!.hashCode) +
    (deliveryDate == null ? 0 : deliveryDate!.hashCode) +
    (shipmentType == null ? 0 : shipmentType!.hashCode) +
    (courierAssigned == null ? 0 : courierAssigned!.hashCode) +
    (tripNo == null ? 0 : tripNo!.hashCode) +
    (truckNumber == null ? 0 : truckNumber!.hashCode) +
    (truckTripCount == null ? 0 : truckTripCount!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (createdBy == null ? 0 : createdBy!.hashCode) +
    (seller == null ? 0 : seller!.hashCode) +
    (items.hashCode) +
    (pickupAddress == null ? 0 : pickupAddress!.hashCode) +
    (dropAddress == null ? 0 : dropAddress!.hashCode) +
    (pickupAddresses.hashCode) +
    (dropAddresses.hashCode) +
    (dispatches.hashCode) +
    (invoice == null ? 0 : invoice!.hashCode) +
    (stops.hashCode) +
    (remark == null ? 0 : remark!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode);

  @override
  String toString() => 'TransportOrder[id=$id, version=$version, orderReference=$orderReference, customer=$customer, billTo=$billTo, orderDate=$orderDate, deliveryDate=$deliveryDate, shipmentType=$shipmentType, courierAssigned=$courierAssigned, tripNo=$tripNo, truckNumber=$truckNumber, truckTripCount=$truckTripCount, status=$status, createdBy=$createdBy, seller=$seller, items=$items, pickupAddress=$pickupAddress, dropAddress=$dropAddress, pickupAddresses=$pickupAddresses, dropAddresses=$dropAddresses, dispatches=$dispatches, invoice=$invoice, stops=$stops, remark=$remark, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.version != null) {
      json[r'version'] = this.version;
    } else {
      json[r'version'] = null;
    }
    if (this.orderReference != null) {
      json[r'orderReference'] = this.orderReference;
    } else {
      json[r'orderReference'] = null;
    }
    if (this.customer != null) {
      json[r'customer'] = this.customer;
    } else {
      json[r'customer'] = null;
    }
    if (this.billTo != null) {
      json[r'billTo'] = this.billTo;
    } else {
      json[r'billTo'] = null;
    }
    if (this.orderDate != null) {
      json[r'orderDate'] = _dateFormatter.format(this.orderDate!.toUtc());
    } else {
      json[r'orderDate'] = null;
    }
    if (this.deliveryDate != null) {
      json[r'deliveryDate'] = _dateFormatter.format(this.deliveryDate!.toUtc());
    } else {
      json[r'deliveryDate'] = null;
    }
    if (this.shipmentType != null) {
      json[r'shipmentType'] = this.shipmentType;
    } else {
      json[r'shipmentType'] = null;
    }
    if (this.courierAssigned != null) {
      json[r'courierAssigned'] = this.courierAssigned;
    } else {
      json[r'courierAssigned'] = null;
    }
    if (this.tripNo != null) {
      json[r'tripNo'] = this.tripNo;
    } else {
      json[r'tripNo'] = null;
    }
    if (this.truckNumber != null) {
      json[r'truckNumber'] = this.truckNumber;
    } else {
      json[r'truckNumber'] = null;
    }
    if (this.truckTripCount != null) {
      json[r'truckTripCount'] = this.truckTripCount;
    } else {
      json[r'truckTripCount'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.createdBy != null) {
      json[r'createdBy'] = this.createdBy;
    } else {
      json[r'createdBy'] = null;
    }
    if (this.seller != null) {
      json[r'seller'] = this.seller;
    } else {
      json[r'seller'] = null;
    }
      json[r'items'] = this.items;
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
      json[r'pickupAddresses'] = this.pickupAddresses;
      json[r'dropAddresses'] = this.dropAddresses;
      json[r'dispatches'] = this.dispatches;
    if (this.invoice != null) {
      json[r'invoice'] = this.invoice;
    } else {
      json[r'invoice'] = null;
    }
      json[r'stops'] = this.stops;
    if (this.remark != null) {
      json[r'remark'] = this.remark;
    } else {
      json[r'remark'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    return json;
  }

  /// Returns a new [TransportOrder] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TransportOrder? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TransportOrder(
        id: mapValueOfType<int>(json, r'id'),
        version: mapValueOfType<int>(json, r'version'),
        orderReference: mapValueOfType<String>(json, r'orderReference'),
        customer: Customer.fromJson(json[r'customer']),
        billTo: mapValueOfType<String>(json, r'billTo'),
        orderDate: mapDateTime(json, r'orderDate', r''),
        deliveryDate: mapDateTime(json, r'deliveryDate', r''),
        shipmentType: mapValueOfType<String>(json, r'shipmentType'),
        courierAssigned: mapValueOfType<String>(json, r'courierAssigned'),
        tripNo: mapValueOfType<String>(json, r'tripNo'),
        truckNumber: mapValueOfType<String>(json, r'truckNumber'),
        truckTripCount: mapValueOfType<int>(json, r'truckTripCount'),
        status: TransportOrderStatusEnum.fromJson(json[r'status']),
        createdBy: User.fromJson(json[r'createdBy']),
        seller: Employee.fromJson(json[r'seller']),
        items: OrderItem.listFromJson(json[r'items']),
        pickupAddress: OrderAddress.fromJson(json[r'pickupAddress']),
        dropAddress: OrderAddress.fromJson(json[r'dropAddress']),
        pickupAddresses: OrderAddress.listFromJson(json[r'pickupAddresses']),
        dropAddresses: OrderAddress.listFromJson(json[r'dropAddresses']),
        dispatches: Dispatch.listFromJson(json[r'dispatches']),
        invoice: Invoice.fromJson(json[r'invoice']),
        stops: OrderStop.listFromJson(json[r'stops']),
        remark: mapValueOfType<String>(json, r'remark'),
        createdAt: mapDateTime(json, r'createdAt', r''),
      );
    }
    return null;
  }

  static List<TransportOrder> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TransportOrder>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TransportOrder.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TransportOrder> mapFromJson(dynamic json) {
    final map = <String, TransportOrder>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TransportOrder.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TransportOrder-objects as value to a dart map
  static Map<String, List<TransportOrder>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TransportOrder>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TransportOrder.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class TransportOrderStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const TransportOrderStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = TransportOrderStatusEnum._(r'PENDING');
  static const ASSIGNED = TransportOrderStatusEnum._(r'ASSIGNED');
  static const DRIVER_CONFIRMED = TransportOrderStatusEnum._(r'DRIVER_CONFIRMED');
  static const APPROVED = TransportOrderStatusEnum._(r'APPROVED');
  static const REJECTED = TransportOrderStatusEnum._(r'REJECTED');
  static const SCHEDULED = TransportOrderStatusEnum._(r'SCHEDULED');
  static const ARRIVED_LOADING = TransportOrderStatusEnum._(r'ARRIVED_LOADING');
  static const LOADING = TransportOrderStatusEnum._(r'LOADING');
  static const LOADED = TransportOrderStatusEnum._(r'LOADED');
  static const IN_TRANSIT = TransportOrderStatusEnum._(r'IN_TRANSIT');
  static const ARRIVED_UNLOADING = TransportOrderStatusEnum._(r'ARRIVED_UNLOADING');
  static const UNLOADING = TransportOrderStatusEnum._(r'UNLOADING');
  static const UNLOADED = TransportOrderStatusEnum._(r'UNLOADED');
  static const DELIVERED = TransportOrderStatusEnum._(r'DELIVERED');
  static const COMPLETED = TransportOrderStatusEnum._(r'COMPLETED');
  static const CANCELLED = TransportOrderStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][TransportOrderStatusEnum].
  static const values = <TransportOrderStatusEnum>[
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

  static TransportOrderStatusEnum? fromJson(dynamic value) => TransportOrderStatusEnumTypeTransformer().decode(value);

  static List<TransportOrderStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TransportOrderStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TransportOrderStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TransportOrderStatusEnum] to String,
/// and [decode] dynamic data back to [TransportOrderStatusEnum].
class TransportOrderStatusEnumTypeTransformer {
  factory TransportOrderStatusEnumTypeTransformer() => _instance ??= const TransportOrderStatusEnumTypeTransformer._();

  const TransportOrderStatusEnumTypeTransformer._();

  String encode(TransportOrderStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a TransportOrderStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TransportOrderStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return TransportOrderStatusEnum.PENDING;
        case r'ASSIGNED': return TransportOrderStatusEnum.ASSIGNED;
        case r'DRIVER_CONFIRMED': return TransportOrderStatusEnum.DRIVER_CONFIRMED;
        case r'APPROVED': return TransportOrderStatusEnum.APPROVED;
        case r'REJECTED': return TransportOrderStatusEnum.REJECTED;
        case r'SCHEDULED': return TransportOrderStatusEnum.SCHEDULED;
        case r'ARRIVED_LOADING': return TransportOrderStatusEnum.ARRIVED_LOADING;
        case r'LOADING': return TransportOrderStatusEnum.LOADING;
        case r'LOADED': return TransportOrderStatusEnum.LOADED;
        case r'IN_TRANSIT': return TransportOrderStatusEnum.IN_TRANSIT;
        case r'ARRIVED_UNLOADING': return TransportOrderStatusEnum.ARRIVED_UNLOADING;
        case r'UNLOADING': return TransportOrderStatusEnum.UNLOADING;
        case r'UNLOADED': return TransportOrderStatusEnum.UNLOADED;
        case r'DELIVERED': return TransportOrderStatusEnum.DELIVERED;
        case r'COMPLETED': return TransportOrderStatusEnum.COMPLETED;
        case r'CANCELLED': return TransportOrderStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [TransportOrderStatusEnumTypeTransformer] instance.
  static TransportOrderStatusEnumTypeTransformer? _instance;
}


