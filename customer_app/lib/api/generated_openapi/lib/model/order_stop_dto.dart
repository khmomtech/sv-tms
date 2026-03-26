//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OrderStopDto {
  /// Returns a new [OrderStopDto] instance.
  OrderStopDto({
    this.id,
    this.type,
    this.transportOrderId,
    this.address,
    this.sequence,
    this.eta,
    this.arrivalTime,
    this.departureTime,
    this.remarks,
    this.proofImageUrl,
    this.confirmedBy,
    this.contactPhone,
    this.addressId,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  OrderStopDtoTypeEnum? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? transportOrderId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  OrderAddressDto? address;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? sequence;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? eta;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? arrivalTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? departureTime;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? remarks;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? proofImageUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? confirmedBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? contactPhone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? addressId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OrderStopDto &&
    other.id == id &&
    other.type == type &&
    other.transportOrderId == transportOrderId &&
    other.address == address &&
    other.sequence == sequence &&
    other.eta == eta &&
    other.arrivalTime == arrivalTime &&
    other.departureTime == departureTime &&
    other.remarks == remarks &&
    other.proofImageUrl == proofImageUrl &&
    other.confirmedBy == confirmedBy &&
    other.contactPhone == contactPhone &&
    other.addressId == addressId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (transportOrderId == null ? 0 : transportOrderId!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (sequence == null ? 0 : sequence!.hashCode) +
    (eta == null ? 0 : eta!.hashCode) +
    (arrivalTime == null ? 0 : arrivalTime!.hashCode) +
    (departureTime == null ? 0 : departureTime!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (proofImageUrl == null ? 0 : proofImageUrl!.hashCode) +
    (confirmedBy == null ? 0 : confirmedBy!.hashCode) +
    (contactPhone == null ? 0 : contactPhone!.hashCode) +
    (addressId == null ? 0 : addressId!.hashCode);

  @override
  String toString() => 'OrderStopDto[id=$id, type=$type, transportOrderId=$transportOrderId, address=$address, sequence=$sequence, eta=$eta, arrivalTime=$arrivalTime, departureTime=$departureTime, remarks=$remarks, proofImageUrl=$proofImageUrl, confirmedBy=$confirmedBy, contactPhone=$contactPhone, addressId=$addressId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.transportOrderId != null) {
      json[r'transportOrderId'] = this.transportOrderId;
    } else {
      json[r'transportOrderId'] = null;
    }
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.sequence != null) {
      json[r'sequence'] = this.sequence;
    } else {
      json[r'sequence'] = null;
    }
    if (this.eta != null) {
      json[r'eta'] = this.eta!.toUtc().toIso8601String();
    } else {
      json[r'eta'] = null;
    }
    if (this.arrivalTime != null) {
      json[r'arrivalTime'] = this.arrivalTime!.toUtc().toIso8601String();
    } else {
      json[r'arrivalTime'] = null;
    }
    if (this.departureTime != null) {
      json[r'departureTime'] = this.departureTime!.toUtc().toIso8601String();
    } else {
      json[r'departureTime'] = null;
    }
    if (this.remarks != null) {
      json[r'remarks'] = this.remarks;
    } else {
      json[r'remarks'] = null;
    }
    if (this.proofImageUrl != null) {
      json[r'proofImageUrl'] = this.proofImageUrl;
    } else {
      json[r'proofImageUrl'] = null;
    }
    if (this.confirmedBy != null) {
      json[r'confirmedBy'] = this.confirmedBy;
    } else {
      json[r'confirmedBy'] = null;
    }
    if (this.contactPhone != null) {
      json[r'contactPhone'] = this.contactPhone;
    } else {
      json[r'contactPhone'] = null;
    }
    if (this.addressId != null) {
      json[r'addressId'] = this.addressId;
    } else {
      json[r'addressId'] = null;
    }
    return json;
  }

  /// Returns a new [OrderStopDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OrderStopDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return OrderStopDto(
        id: mapValueOfType<int>(json, r'id'),
        type: OrderStopDtoTypeEnum.fromJson(json[r'type']),
        transportOrderId: mapValueOfType<int>(json, r'transportOrderId'),
        address: OrderAddressDto.fromJson(json[r'address']),
        sequence: mapValueOfType<int>(json, r'sequence'),
        eta: mapDateTime(json, r'eta', r''),
        arrivalTime: mapDateTime(json, r'arrivalTime', r''),
        departureTime: mapDateTime(json, r'departureTime', r''),
        remarks: mapValueOfType<String>(json, r'remarks'),
        proofImageUrl: mapValueOfType<String>(json, r'proofImageUrl'),
        confirmedBy: mapValueOfType<String>(json, r'confirmedBy'),
        contactPhone: mapValueOfType<String>(json, r'contactPhone'),
        addressId: mapValueOfType<int>(json, r'addressId'),
      );
    }
    return null;
  }

  static List<OrderStopDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderStopDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderStopDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OrderStopDto> mapFromJson(dynamic json) {
    final map = <String, OrderStopDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OrderStopDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OrderStopDto-objects as value to a dart map
  static Map<String, List<OrderStopDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OrderStopDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OrderStopDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class OrderStopDtoTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const OrderStopDtoTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PICKUP = OrderStopDtoTypeEnum._(r'PICKUP');
  static const DROP = OrderStopDtoTypeEnum._(r'DROP');

  /// List of all possible values in this [enum][OrderStopDtoTypeEnum].
  static const values = <OrderStopDtoTypeEnum>[
    PICKUP,
    DROP,
  ];

  static OrderStopDtoTypeEnum? fromJson(dynamic value) => OrderStopDtoTypeEnumTypeTransformer().decode(value);

  static List<OrderStopDtoTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderStopDtoTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderStopDtoTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [OrderStopDtoTypeEnum] to String,
/// and [decode] dynamic data back to [OrderStopDtoTypeEnum].
class OrderStopDtoTypeEnumTypeTransformer {
  factory OrderStopDtoTypeEnumTypeTransformer() => _instance ??= const OrderStopDtoTypeEnumTypeTransformer._();

  const OrderStopDtoTypeEnumTypeTransformer._();

  String encode(OrderStopDtoTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a OrderStopDtoTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  OrderStopDtoTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PICKUP': return OrderStopDtoTypeEnum.PICKUP;
        case r'DROP': return OrderStopDtoTypeEnum.DROP;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [OrderStopDtoTypeEnumTypeTransformer] instance.
  static OrderStopDtoTypeEnumTypeTransformer? _instance;
}


