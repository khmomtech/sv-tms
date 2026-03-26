//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OrderStop {
  /// Returns a new [OrderStop] instance.
  OrderStop({
    this.id,
    this.type,
    this.transportOrder,
    this.address,
    this.sequence,
    this.eta,
    this.arrivalTime,
    this.departureTime,
    this.remarks,
    this.proofImageUrl,
    this.confirmedBy,
    this.contactPhone,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  OrderStopTypeEnum? type;

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
  OrderAddress? address;

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

  @override
  bool operator ==(Object other) => identical(this, other) || other is OrderStop &&
    other.id == id &&
    other.type == type &&
    other.transportOrder == transportOrder &&
    other.address == address &&
    other.sequence == sequence &&
    other.eta == eta &&
    other.arrivalTime == arrivalTime &&
    other.departureTime == departureTime &&
    other.remarks == remarks &&
    other.proofImageUrl == proofImageUrl &&
    other.confirmedBy == confirmedBy &&
    other.contactPhone == contactPhone;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (transportOrder == null ? 0 : transportOrder!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (sequence == null ? 0 : sequence!.hashCode) +
    (eta == null ? 0 : eta!.hashCode) +
    (arrivalTime == null ? 0 : arrivalTime!.hashCode) +
    (departureTime == null ? 0 : departureTime!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (proofImageUrl == null ? 0 : proofImageUrl!.hashCode) +
    (confirmedBy == null ? 0 : confirmedBy!.hashCode) +
    (contactPhone == null ? 0 : contactPhone!.hashCode);

  @override
  String toString() => 'OrderStop[id=$id, type=$type, transportOrder=$transportOrder, address=$address, sequence=$sequence, eta=$eta, arrivalTime=$arrivalTime, departureTime=$departureTime, remarks=$remarks, proofImageUrl=$proofImageUrl, confirmedBy=$confirmedBy, contactPhone=$contactPhone]';

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
    if (this.transportOrder != null) {
      json[r'transportOrder'] = this.transportOrder;
    } else {
      json[r'transportOrder'] = null;
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
    return json;
  }

  /// Returns a new [OrderStop] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OrderStop? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return OrderStop(
        id: mapValueOfType<int>(json, r'id'),
        type: OrderStopTypeEnum.fromJson(json[r'type']),
        transportOrder: TransportOrder.fromJson(json[r'transportOrder']),
        address: OrderAddress.fromJson(json[r'address']),
        sequence: mapValueOfType<int>(json, r'sequence'),
        eta: mapDateTime(json, r'eta', r''),
        arrivalTime: mapDateTime(json, r'arrivalTime', r''),
        departureTime: mapDateTime(json, r'departureTime', r''),
        remarks: mapValueOfType<String>(json, r'remarks'),
        proofImageUrl: mapValueOfType<String>(json, r'proofImageUrl'),
        confirmedBy: mapValueOfType<String>(json, r'confirmedBy'),
        contactPhone: mapValueOfType<String>(json, r'contactPhone'),
      );
    }
    return null;
  }

  static List<OrderStop> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderStop>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderStop.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OrderStop> mapFromJson(dynamic json) {
    final map = <String, OrderStop>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OrderStop.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OrderStop-objects as value to a dart map
  static Map<String, List<OrderStop>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OrderStop>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OrderStop.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class OrderStopTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const OrderStopTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PICKUP = OrderStopTypeEnum._(r'PICKUP');
  static const DROP = OrderStopTypeEnum._(r'DROP');

  /// List of all possible values in this [enum][OrderStopTypeEnum].
  static const values = <OrderStopTypeEnum>[
    PICKUP,
    DROP,
  ];

  static OrderStopTypeEnum? fromJson(dynamic value) => OrderStopTypeEnumTypeTransformer().decode(value);

  static List<OrderStopTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OrderStopTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OrderStopTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [OrderStopTypeEnum] to String,
/// and [decode] dynamic data back to [OrderStopTypeEnum].
class OrderStopTypeEnumTypeTransformer {
  factory OrderStopTypeEnumTypeTransformer() => _instance ??= const OrderStopTypeEnumTypeTransformer._();

  const OrderStopTypeEnumTypeTransformer._();

  String encode(OrderStopTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a OrderStopTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  OrderStopTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PICKUP': return OrderStopTypeEnum.PICKUP;
        case r'DROP': return OrderStopTypeEnum.DROP;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [OrderStopTypeEnumTypeTransformer] instance.
  static OrderStopTypeEnumTypeTransformer? _instance;
}


