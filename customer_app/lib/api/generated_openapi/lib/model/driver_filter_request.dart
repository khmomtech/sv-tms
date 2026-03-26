//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverFilterRequest {
  /// Returns a new [DriverFilterRequest] instance.
  DriverFilterRequest({
    this.query,
    this.isActive,
    this.minRating,
    this.maxRating,
    this.zone,
    this.vehicleType,
    this.status,
    this.isPartner,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? query;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isActive;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? minRating;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? maxRating;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? zone;

  DriverFilterRequestVehicleTypeEnum? vehicleType;

  DriverFilterRequestStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isPartner;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverFilterRequest &&
    other.query == query &&
    other.isActive == isActive &&
    other.minRating == minRating &&
    other.maxRating == maxRating &&
    other.zone == zone &&
    other.vehicleType == vehicleType &&
    other.status == status &&
    other.isPartner == isPartner;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (query == null ? 0 : query!.hashCode) +
    (isActive == null ? 0 : isActive!.hashCode) +
    (minRating == null ? 0 : minRating!.hashCode) +
    (maxRating == null ? 0 : maxRating!.hashCode) +
    (zone == null ? 0 : zone!.hashCode) +
    (vehicleType == null ? 0 : vehicleType!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (isPartner == null ? 0 : isPartner!.hashCode);

  @override
  String toString() => 'DriverFilterRequest[query=$query, isActive=$isActive, minRating=$minRating, maxRating=$maxRating, zone=$zone, vehicleType=$vehicleType, status=$status, isPartner=$isPartner]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.query != null) {
      json[r'query'] = this.query;
    } else {
      json[r'query'] = null;
    }
    if (this.isActive != null) {
      json[r'isActive'] = this.isActive;
    } else {
      json[r'isActive'] = null;
    }
    if (this.minRating != null) {
      json[r'minRating'] = this.minRating;
    } else {
      json[r'minRating'] = null;
    }
    if (this.maxRating != null) {
      json[r'maxRating'] = this.maxRating;
    } else {
      json[r'maxRating'] = null;
    }
    if (this.zone != null) {
      json[r'zone'] = this.zone;
    } else {
      json[r'zone'] = null;
    }
    if (this.vehicleType != null) {
      json[r'vehicleType'] = this.vehicleType;
    } else {
      json[r'vehicleType'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.isPartner != null) {
      json[r'isPartner'] = this.isPartner;
    } else {
      json[r'isPartner'] = null;
    }
    return json;
  }

  /// Returns a new [DriverFilterRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverFilterRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DriverFilterRequest(
        query: mapValueOfType<String>(json, r'query'),
        isActive: mapValueOfType<bool>(json, r'isActive'),
        minRating: mapValueOfType<int>(json, r'minRating'),
        maxRating: mapValueOfType<int>(json, r'maxRating'),
        zone: mapValueOfType<String>(json, r'zone'),
        vehicleType: DriverFilterRequestVehicleTypeEnum.fromJson(json[r'vehicleType']),
        status: DriverFilterRequestStatusEnum.fromJson(json[r'status']),
        isPartner: mapValueOfType<bool>(json, r'isPartner'),
      );
    }
    return null;
  }

  static List<DriverFilterRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverFilterRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverFilterRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverFilterRequest> mapFromJson(dynamic json) {
    final map = <String, DriverFilterRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverFilterRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverFilterRequest-objects as value to a dart map
  static Map<String, List<DriverFilterRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverFilterRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverFilterRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class DriverFilterRequestVehicleTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverFilterRequestVehicleTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BIG_TRUCK = DriverFilterRequestVehicleTypeEnum._(r'BIG_TRUCK');
  static const TRUCK = DriverFilterRequestVehicleTypeEnum._(r'TRUCK');
  static const TRAILER = DriverFilterRequestVehicleTypeEnum._(r'TRAILER');
  static const SMALL_VAN = DriverFilterRequestVehicleTypeEnum._(r'SMALL_VAN');
  static const VAN = DriverFilterRequestVehicleTypeEnum._(r'VAN');
  static const SUV = DriverFilterRequestVehicleTypeEnum._(r'SUV');
  static const CAR = DriverFilterRequestVehicleTypeEnum._(r'CAR');
  static const BUS = DriverFilterRequestVehicleTypeEnum._(r'BUS');
  static const MOTORBIKE = DriverFilterRequestVehicleTypeEnum._(r'MOTORBIKE');
  static const ELECTRIC = DriverFilterRequestVehicleTypeEnum._(r'ELECTRIC');
  static const OTHER = DriverFilterRequestVehicleTypeEnum._(r'OTHER');
  static const UNKNOWN = DriverFilterRequestVehicleTypeEnum._(r'UNKNOWN');

  /// List of all possible values in this [enum][DriverFilterRequestVehicleTypeEnum].
  static const values = <DriverFilterRequestVehicleTypeEnum>[
    BIG_TRUCK,
    TRUCK,
    TRAILER,
    SMALL_VAN,
    VAN,
    SUV,
    CAR,
    BUS,
    MOTORBIKE,
    ELECTRIC,
    OTHER,
    UNKNOWN,
  ];

  static DriverFilterRequestVehicleTypeEnum? fromJson(dynamic value) => DriverFilterRequestVehicleTypeEnumTypeTransformer().decode(value);

  static List<DriverFilterRequestVehicleTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverFilterRequestVehicleTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverFilterRequestVehicleTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverFilterRequestVehicleTypeEnum] to String,
/// and [decode] dynamic data back to [DriverFilterRequestVehicleTypeEnum].
class DriverFilterRequestVehicleTypeEnumTypeTransformer {
  factory DriverFilterRequestVehicleTypeEnumTypeTransformer() => _instance ??= const DriverFilterRequestVehicleTypeEnumTypeTransformer._();

  const DriverFilterRequestVehicleTypeEnumTypeTransformer._();

  String encode(DriverFilterRequestVehicleTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverFilterRequestVehicleTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverFilterRequestVehicleTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BIG_TRUCK': return DriverFilterRequestVehicleTypeEnum.BIG_TRUCK;
        case r'TRUCK': return DriverFilterRequestVehicleTypeEnum.TRUCK;
        case r'TRAILER': return DriverFilterRequestVehicleTypeEnum.TRAILER;
        case r'SMALL_VAN': return DriverFilterRequestVehicleTypeEnum.SMALL_VAN;
        case r'VAN': return DriverFilterRequestVehicleTypeEnum.VAN;
        case r'SUV': return DriverFilterRequestVehicleTypeEnum.SUV;
        case r'CAR': return DriverFilterRequestVehicleTypeEnum.CAR;
        case r'BUS': return DriverFilterRequestVehicleTypeEnum.BUS;
        case r'MOTORBIKE': return DriverFilterRequestVehicleTypeEnum.MOTORBIKE;
        case r'ELECTRIC': return DriverFilterRequestVehicleTypeEnum.ELECTRIC;
        case r'OTHER': return DriverFilterRequestVehicleTypeEnum.OTHER;
        case r'UNKNOWN': return DriverFilterRequestVehicleTypeEnum.UNKNOWN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverFilterRequestVehicleTypeEnumTypeTransformer] instance.
  static DriverFilterRequestVehicleTypeEnumTypeTransformer? _instance;
}



class DriverFilterRequestStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverFilterRequestStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ONLINE = DriverFilterRequestStatusEnum._(r'ONLINE');
  static const OFFLINE = DriverFilterRequestStatusEnum._(r'OFFLINE');
  static const BUSY = DriverFilterRequestStatusEnum._(r'BUSY');
  static const IDLE = DriverFilterRequestStatusEnum._(r'IDLE');

  /// List of all possible values in this [enum][DriverFilterRequestStatusEnum].
  static const values = <DriverFilterRequestStatusEnum>[
    ONLINE,
    OFFLINE,
    BUSY,
    IDLE,
  ];

  static DriverFilterRequestStatusEnum? fromJson(dynamic value) => DriverFilterRequestStatusEnumTypeTransformer().decode(value);

  static List<DriverFilterRequestStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverFilterRequestStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverFilterRequestStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverFilterRequestStatusEnum] to String,
/// and [decode] dynamic data back to [DriverFilterRequestStatusEnum].
class DriverFilterRequestStatusEnumTypeTransformer {
  factory DriverFilterRequestStatusEnumTypeTransformer() => _instance ??= const DriverFilterRequestStatusEnumTypeTransformer._();

  const DriverFilterRequestStatusEnumTypeTransformer._();

  String encode(DriverFilterRequestStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverFilterRequestStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverFilterRequestStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ONLINE': return DriverFilterRequestStatusEnum.ONLINE;
        case r'OFFLINE': return DriverFilterRequestStatusEnum.OFFLINE;
        case r'BUSY': return DriverFilterRequestStatusEnum.BUSY;
        case r'IDLE': return DriverFilterRequestStatusEnum.IDLE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverFilterRequestStatusEnumTypeTransformer] instance.
  static DriverFilterRequestStatusEnumTypeTransformer? _instance;
}


