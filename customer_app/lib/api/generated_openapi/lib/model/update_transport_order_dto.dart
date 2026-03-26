//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UpdateTransportOrderDto {
  /// Returns a new [UpdateTransportOrderDto] instance.
  UpdateTransportOrderDto({
    this.id,
    this.orderReference,
    this.customerId,
    this.billTo,
    this.orderDate,
    this.deliveryDate,
    this.shipmentType,
    this.courierAssigned,
    this.status,
    this.remark,
    this.createdById,
    this.sellerId,
    this.pickupAddress,
    this.dropAddress,
    this.pickupLocations = const [],
    this.dropLocations = const [],
    this.items = const [],
    this.stops = const [],
    this.customer,
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

  UpdateTransportOrderDtoStatusEnum? status;

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
  int? sellerId;

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

  List<OrderAddressDto> pickupLocations;

  List<OrderAddressDto> dropLocations;

  List<OrderItemDto> items;

  List<OrderStopDto> stops;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  CustomerDto? customer;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UpdateTransportOrderDto &&
    other.id == id &&
    other.orderReference == orderReference &&
    other.customerId == customerId &&
    other.billTo == billTo &&
    other.orderDate == orderDate &&
    other.deliveryDate == deliveryDate &&
    other.shipmentType == shipmentType &&
    other.courierAssigned == courierAssigned &&
    other.status == status &&
    other.remark == remark &&
    other.createdById == createdById &&
    other.sellerId == sellerId &&
    other.pickupAddress == pickupAddress &&
    other.dropAddress == dropAddress &&
    _deepEquality.equals(other.pickupLocations, pickupLocations) &&
    _deepEquality.equals(other.dropLocations, dropLocations) &&
    _deepEquality.equals(other.items, items) &&
    _deepEquality.equals(other.stops, stops) &&
    other.customer == customer;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (orderReference == null ? 0 : orderReference!.hashCode) +
    (customerId == null ? 0 : customerId!.hashCode) +
    (billTo == null ? 0 : billTo!.hashCode) +
    (orderDate == null ? 0 : orderDate!.hashCode) +
    (deliveryDate == null ? 0 : deliveryDate!.hashCode) +
    (shipmentType == null ? 0 : shipmentType!.hashCode) +
    (courierAssigned == null ? 0 : courierAssigned!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (remark == null ? 0 : remark!.hashCode) +
    (createdById == null ? 0 : createdById!.hashCode) +
    (sellerId == null ? 0 : sellerId!.hashCode) +
    (pickupAddress == null ? 0 : pickupAddress!.hashCode) +
    (dropAddress == null ? 0 : dropAddress!.hashCode) +
    (pickupLocations.hashCode) +
    (dropLocations.hashCode) +
    (items.hashCode) +
    (stops.hashCode) +
    (customer == null ? 0 : customer!.hashCode);

  @override
  String toString() => 'UpdateTransportOrderDto[id=$id, orderReference=$orderReference, customerId=$customerId, billTo=$billTo, orderDate=$orderDate, deliveryDate=$deliveryDate, shipmentType=$shipmentType, courierAssigned=$courierAssigned, status=$status, remark=$remark, createdById=$createdById, sellerId=$sellerId, pickupAddress=$pickupAddress, dropAddress=$dropAddress, pickupLocations=$pickupLocations, dropLocations=$dropLocations, items=$items, stops=$stops, customer=$customer]';

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
    if (this.sellerId != null) {
      json[r'sellerId'] = this.sellerId;
    } else {
      json[r'sellerId'] = null;
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
      json[r'pickupLocations'] = this.pickupLocations;
      json[r'dropLocations'] = this.dropLocations;
      json[r'items'] = this.items;
      json[r'stops'] = this.stops;
    if (this.customer != null) {
      json[r'customer'] = this.customer;
    } else {
      json[r'customer'] = null;
    }
    return json;
  }

  /// Returns a new [UpdateTransportOrderDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UpdateTransportOrderDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UpdateTransportOrderDto(
        id: mapValueOfType<int>(json, r'id'),
        orderReference: mapValueOfType<String>(json, r'orderReference'),
        customerId: mapValueOfType<int>(json, r'customerId'),
        billTo: mapValueOfType<String>(json, r'billTo'),
        orderDate: mapDateTime(json, r'orderDate', r''),
        deliveryDate: mapDateTime(json, r'deliveryDate', r''),
        shipmentType: mapValueOfType<String>(json, r'shipmentType'),
        courierAssigned: mapValueOfType<String>(json, r'courierAssigned'),
        status: UpdateTransportOrderDtoStatusEnum.fromJson(json[r'status']),
        remark: mapValueOfType<String>(json, r'remark'),
        createdById: mapValueOfType<int>(json, r'createdById'),
        sellerId: mapValueOfType<int>(json, r'sellerId'),
        pickupAddress: OrderAddressDto.fromJson(json[r'pickupAddress']),
        dropAddress: OrderAddressDto.fromJson(json[r'dropAddress']),
        pickupLocations: OrderAddressDto.listFromJson(json[r'pickupLocations']),
        dropLocations: OrderAddressDto.listFromJson(json[r'dropLocations']),
        items: OrderItemDto.listFromJson(json[r'items']),
        stops: OrderStopDto.listFromJson(json[r'stops']),
        customer: CustomerDto.fromJson(json[r'customer']),
      );
    }
    return null;
  }

  static List<UpdateTransportOrderDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateTransportOrderDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateTransportOrderDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UpdateTransportOrderDto> mapFromJson(dynamic json) {
    final map = <String, UpdateTransportOrderDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UpdateTransportOrderDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UpdateTransportOrderDto-objects as value to a dart map
  static Map<String, List<UpdateTransportOrderDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UpdateTransportOrderDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UpdateTransportOrderDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class UpdateTransportOrderDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const UpdateTransportOrderDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = UpdateTransportOrderDtoStatusEnum._(r'PENDING');
  static const ASSIGNED = UpdateTransportOrderDtoStatusEnum._(r'ASSIGNED');
  static const DRIVER_CONFIRMED = UpdateTransportOrderDtoStatusEnum._(r'DRIVER_CONFIRMED');
  static const APPROVED = UpdateTransportOrderDtoStatusEnum._(r'APPROVED');
  static const REJECTED = UpdateTransportOrderDtoStatusEnum._(r'REJECTED');
  static const SCHEDULED = UpdateTransportOrderDtoStatusEnum._(r'SCHEDULED');
  static const ARRIVED_LOADING = UpdateTransportOrderDtoStatusEnum._(r'ARRIVED_LOADING');
  static const LOADING = UpdateTransportOrderDtoStatusEnum._(r'LOADING');
  static const LOADED = UpdateTransportOrderDtoStatusEnum._(r'LOADED');
  static const IN_TRANSIT = UpdateTransportOrderDtoStatusEnum._(r'IN_TRANSIT');
  static const ARRIVED_UNLOADING = UpdateTransportOrderDtoStatusEnum._(r'ARRIVED_UNLOADING');
  static const UNLOADING = UpdateTransportOrderDtoStatusEnum._(r'UNLOADING');
  static const UNLOADED = UpdateTransportOrderDtoStatusEnum._(r'UNLOADED');
  static const DELIVERED = UpdateTransportOrderDtoStatusEnum._(r'DELIVERED');
  static const COMPLETED = UpdateTransportOrderDtoStatusEnum._(r'COMPLETED');
  static const CANCELLED = UpdateTransportOrderDtoStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][UpdateTransportOrderDtoStatusEnum].
  static const values = <UpdateTransportOrderDtoStatusEnum>[
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

  static UpdateTransportOrderDtoStatusEnum? fromJson(dynamic value) => UpdateTransportOrderDtoStatusEnumTypeTransformer().decode(value);

  static List<UpdateTransportOrderDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UpdateTransportOrderDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UpdateTransportOrderDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [UpdateTransportOrderDtoStatusEnum] to String,
/// and [decode] dynamic data back to [UpdateTransportOrderDtoStatusEnum].
class UpdateTransportOrderDtoStatusEnumTypeTransformer {
  factory UpdateTransportOrderDtoStatusEnumTypeTransformer() => _instance ??= const UpdateTransportOrderDtoStatusEnumTypeTransformer._();

  const UpdateTransportOrderDtoStatusEnumTypeTransformer._();

  String encode(UpdateTransportOrderDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a UpdateTransportOrderDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  UpdateTransportOrderDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return UpdateTransportOrderDtoStatusEnum.PENDING;
        case r'ASSIGNED': return UpdateTransportOrderDtoStatusEnum.ASSIGNED;
        case r'DRIVER_CONFIRMED': return UpdateTransportOrderDtoStatusEnum.DRIVER_CONFIRMED;
        case r'APPROVED': return UpdateTransportOrderDtoStatusEnum.APPROVED;
        case r'REJECTED': return UpdateTransportOrderDtoStatusEnum.REJECTED;
        case r'SCHEDULED': return UpdateTransportOrderDtoStatusEnum.SCHEDULED;
        case r'ARRIVED_LOADING': return UpdateTransportOrderDtoStatusEnum.ARRIVED_LOADING;
        case r'LOADING': return UpdateTransportOrderDtoStatusEnum.LOADING;
        case r'LOADED': return UpdateTransportOrderDtoStatusEnum.LOADED;
        case r'IN_TRANSIT': return UpdateTransportOrderDtoStatusEnum.IN_TRANSIT;
        case r'ARRIVED_UNLOADING': return UpdateTransportOrderDtoStatusEnum.ARRIVED_UNLOADING;
        case r'UNLOADING': return UpdateTransportOrderDtoStatusEnum.UNLOADING;
        case r'UNLOADED': return UpdateTransportOrderDtoStatusEnum.UNLOADED;
        case r'DELIVERED': return UpdateTransportOrderDtoStatusEnum.DELIVERED;
        case r'COMPLETED': return UpdateTransportOrderDtoStatusEnum.COMPLETED;
        case r'CANCELLED': return UpdateTransportOrderDtoStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [UpdateTransportOrderDtoStatusEnumTypeTransformer] instance.
  static UpdateTransportOrderDtoStatusEnumTypeTransformer? _instance;
}


