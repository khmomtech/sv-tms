//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TransportOrderDto {
  /// Returns a new [TransportOrderDto] instance.
  TransportOrderDto({
    this.id,
    this.orderReference,
    this.customerId,
    this.customerName,
    this.billTo,
    this.orderDate,
    this.deliveryDate,
    this.createDate,
    this.shipmentType,
    this.courierAssigned,
    this.tripNo,
    this.truckNumber,
    this.truckTripCount,
    this.status,
    this.remark,
    this.createdById,
    this.createdByUsername,
    this.seller,
    this.items = const [],
    this.pickupAddress,
    this.dropAddress,
    this.pickupAddresses = const [],
    this.dropAddresses = const [],
    this.dispatches = const [],
    this.invoice,
    this.stops = const [],
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
  String? orderReference;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? customerId;

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
  DateTime? createDate;

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

  TransportOrderDtoStatusEnum? status;

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
  int? createdById;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? createdByUsername;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  EmployeeDto? seller;

  List<OrderItemDto> items;

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

  List<OrderAddressDto> pickupAddresses;

  List<OrderAddressDto> dropAddresses;

  List<DispatchDto> dispatches;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  InvoiceDto? invoice;

  List<OrderStopDto> stops;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TransportOrderDto &&
    other.id == id &&
    other.orderReference == orderReference &&
    other.customerId == customerId &&
    other.customerName == customerName &&
    other.billTo == billTo &&
    other.orderDate == orderDate &&
    other.deliveryDate == deliveryDate &&
    other.createDate == createDate &&
    other.shipmentType == shipmentType &&
    other.courierAssigned == courierAssigned &&
    other.tripNo == tripNo &&
    other.truckNumber == truckNumber &&
    other.truckTripCount == truckTripCount &&
    other.status == status &&
    other.remark == remark &&
    other.createdById == createdById &&
    other.createdByUsername == createdByUsername &&
    other.seller == seller &&
    _deepEquality.equals(other.items, items) &&
    other.pickupAddress == pickupAddress &&
    other.dropAddress == dropAddress &&
    _deepEquality.equals(other.pickupAddresses, pickupAddresses) &&
    _deepEquality.equals(other.dropAddresses, dropAddresses) &&
    _deepEquality.equals(other.dispatches, dispatches) &&
    other.invoice == invoice &&
    _deepEquality.equals(other.stops, stops);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (orderReference == null ? 0 : orderReference!.hashCode) +
    (customerId == null ? 0 : customerId!.hashCode) +
    (customerName == null ? 0 : customerName!.hashCode) +
    (billTo == null ? 0 : billTo!.hashCode) +
    (orderDate == null ? 0 : orderDate!.hashCode) +
    (deliveryDate == null ? 0 : deliveryDate!.hashCode) +
    (createDate == null ? 0 : createDate!.hashCode) +
    (shipmentType == null ? 0 : shipmentType!.hashCode) +
    (courierAssigned == null ? 0 : courierAssigned!.hashCode) +
    (tripNo == null ? 0 : tripNo!.hashCode) +
    (truckNumber == null ? 0 : truckNumber!.hashCode) +
    (truckTripCount == null ? 0 : truckTripCount!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (remark == null ? 0 : remark!.hashCode) +
    (createdById == null ? 0 : createdById!.hashCode) +
    (createdByUsername == null ? 0 : createdByUsername!.hashCode) +
    (seller == null ? 0 : seller!.hashCode) +
    (items.hashCode) +
    (pickupAddress == null ? 0 : pickupAddress!.hashCode) +
    (dropAddress == null ? 0 : dropAddress!.hashCode) +
    (pickupAddresses.hashCode) +
    (dropAddresses.hashCode) +
    (dispatches.hashCode) +
    (invoice == null ? 0 : invoice!.hashCode) +
    (stops.hashCode);

  @override
  String toString() => 'TransportOrderDto[id=$id, orderReference=$orderReference, customerId=$customerId, customerName=$customerName, billTo=$billTo, orderDate=$orderDate, deliveryDate=$deliveryDate, createDate=$createDate, shipmentType=$shipmentType, courierAssigned=$courierAssigned, tripNo=$tripNo, truckNumber=$truckNumber, truckTripCount=$truckTripCount, status=$status, remark=$remark, createdById=$createdById, createdByUsername=$createdByUsername, seller=$seller, items=$items, pickupAddress=$pickupAddress, dropAddress=$dropAddress, pickupAddresses=$pickupAddresses, dropAddresses=$dropAddresses, dispatches=$dispatches, invoice=$invoice, stops=$stops]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.orderReference != null) {
      json[r'orderReference'] = this.orderReference;
    } else {
      json[r'orderReference'] = null;
    }
    if (this.customerId != null) {
      json[r'customerId'] = this.customerId;
    } else {
      json[r'customerId'] = null;
    }
    if (this.customerName != null) {
      json[r'customerName'] = this.customerName;
    } else {
      json[r'customerName'] = null;
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
    if (this.createDate != null) {
      json[r'createDate'] = this.createDate!.toUtc().toIso8601String();
    } else {
      json[r'createDate'] = null;
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
    if (this.remark != null) {
      json[r'remark'] = this.remark;
    } else {
      json[r'remark'] = null;
    }
    if (this.createdById != null) {
      json[r'createdById'] = this.createdById;
    } else {
      json[r'createdById'] = null;
    }
    if (this.createdByUsername != null) {
      json[r'createdByUsername'] = this.createdByUsername;
    } else {
      json[r'createdByUsername'] = null;
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
    return json;
  }

  /// Returns a new [TransportOrderDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TransportOrderDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return TransportOrderDto(
        id: mapValueOfType<int>(json, r'id'),
        orderReference: mapValueOfType<String>(json, r'orderReference'),
        customerId: mapValueOfType<int>(json, r'customerId'),
        customerName: mapValueOfType<String>(json, r'customerName'),
        billTo: mapValueOfType<String>(json, r'billTo'),
        orderDate: mapDateTime(json, r'orderDate', r''),
        deliveryDate: mapDateTime(json, r'deliveryDate', r''),
        createDate: mapDateTime(json, r'createDate', r''),
        shipmentType: mapValueOfType<String>(json, r'shipmentType'),
        courierAssigned: mapValueOfType<String>(json, r'courierAssigned'),
        tripNo: mapValueOfType<String>(json, r'tripNo'),
        truckNumber: mapValueOfType<String>(json, r'truckNumber'),
        truckTripCount: mapValueOfType<int>(json, r'truckTripCount'),
        status: TransportOrderDtoStatusEnum.fromJson(json[r'status']),
        remark: mapValueOfType<String>(json, r'remark'),
        createdById: mapValueOfType<int>(json, r'createdById'),
        createdByUsername: mapValueOfType<String>(json, r'createdByUsername'),
        seller: EmployeeDto.fromJson(json[r'seller']),
        items: OrderItemDto.listFromJson(json[r'items']),
        pickupAddress: OrderAddressDto.fromJson(json[r'pickupAddress']),
        dropAddress: OrderAddressDto.fromJson(json[r'dropAddress']),
        pickupAddresses: OrderAddressDto.listFromJson(json[r'pickupAddresses']),
        dropAddresses: OrderAddressDto.listFromJson(json[r'dropAddresses']),
        dispatches: DispatchDto.listFromJson(json[r'dispatches']),
        invoice: InvoiceDto.fromJson(json[r'invoice']),
        stops: OrderStopDto.listFromJson(json[r'stops']),
      );
    }
    return null;
  }

  static List<TransportOrderDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TransportOrderDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TransportOrderDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TransportOrderDto> mapFromJson(dynamic json) {
    final map = <String, TransportOrderDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TransportOrderDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TransportOrderDto-objects as value to a dart map
  static Map<String, List<TransportOrderDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TransportOrderDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TransportOrderDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class TransportOrderDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const TransportOrderDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = TransportOrderDtoStatusEnum._(r'PENDING');
  static const ASSIGNED = TransportOrderDtoStatusEnum._(r'ASSIGNED');
  static const DRIVER_CONFIRMED = TransportOrderDtoStatusEnum._(r'DRIVER_CONFIRMED');
  static const APPROVED = TransportOrderDtoStatusEnum._(r'APPROVED');
  static const REJECTED = TransportOrderDtoStatusEnum._(r'REJECTED');
  static const SCHEDULED = TransportOrderDtoStatusEnum._(r'SCHEDULED');
  static const ARRIVED_LOADING = TransportOrderDtoStatusEnum._(r'ARRIVED_LOADING');
  static const LOADING = TransportOrderDtoStatusEnum._(r'LOADING');
  static const LOADED = TransportOrderDtoStatusEnum._(r'LOADED');
  static const IN_TRANSIT = TransportOrderDtoStatusEnum._(r'IN_TRANSIT');
  static const ARRIVED_UNLOADING = TransportOrderDtoStatusEnum._(r'ARRIVED_UNLOADING');
  static const UNLOADING = TransportOrderDtoStatusEnum._(r'UNLOADING');
  static const UNLOADED = TransportOrderDtoStatusEnum._(r'UNLOADED');
  static const DELIVERED = TransportOrderDtoStatusEnum._(r'DELIVERED');
  static const COMPLETED = TransportOrderDtoStatusEnum._(r'COMPLETED');
  static const CANCELLED = TransportOrderDtoStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][TransportOrderDtoStatusEnum].
  static const values = <TransportOrderDtoStatusEnum>[
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

  static TransportOrderDtoStatusEnum? fromJson(dynamic value) => TransportOrderDtoStatusEnumTypeTransformer().decode(value);

  static List<TransportOrderDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TransportOrderDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TransportOrderDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [TransportOrderDtoStatusEnum] to String,
/// and [decode] dynamic data back to [TransportOrderDtoStatusEnum].
class TransportOrderDtoStatusEnumTypeTransformer {
  factory TransportOrderDtoStatusEnumTypeTransformer() => _instance ??= const TransportOrderDtoStatusEnumTypeTransformer._();

  const TransportOrderDtoStatusEnumTypeTransformer._();

  String encode(TransportOrderDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a TransportOrderDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  TransportOrderDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return TransportOrderDtoStatusEnum.PENDING;
        case r'ASSIGNED': return TransportOrderDtoStatusEnum.ASSIGNED;
        case r'DRIVER_CONFIRMED': return TransportOrderDtoStatusEnum.DRIVER_CONFIRMED;
        case r'APPROVED': return TransportOrderDtoStatusEnum.APPROVED;
        case r'REJECTED': return TransportOrderDtoStatusEnum.REJECTED;
        case r'SCHEDULED': return TransportOrderDtoStatusEnum.SCHEDULED;
        case r'ARRIVED_LOADING': return TransportOrderDtoStatusEnum.ARRIVED_LOADING;
        case r'LOADING': return TransportOrderDtoStatusEnum.LOADING;
        case r'LOADED': return TransportOrderDtoStatusEnum.LOADED;
        case r'IN_TRANSIT': return TransportOrderDtoStatusEnum.IN_TRANSIT;
        case r'ARRIVED_UNLOADING': return TransportOrderDtoStatusEnum.ARRIVED_UNLOADING;
        case r'UNLOADING': return TransportOrderDtoStatusEnum.UNLOADING;
        case r'UNLOADED': return TransportOrderDtoStatusEnum.UNLOADED;
        case r'DELIVERED': return TransportOrderDtoStatusEnum.DELIVERED;
        case r'COMPLETED': return TransportOrderDtoStatusEnum.COMPLETED;
        case r'CANCELLED': return TransportOrderDtoStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [TransportOrderDtoStatusEnumTypeTransformer] instance.
  static TransportOrderDtoStatusEnumTypeTransformer? _instance;
}


