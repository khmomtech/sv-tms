//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverDto {
  /// Returns a new [DriverDto] instance.
  DriverDto({
    this.id,
    this.firstName,
    this.lastName,
    this.name,
    this.licenseNumber,
    this.phone,
    this.rating,
    this.zone,
    this.vehicleType,
    this.status,
    this.lastLocationAt,
    this.partnerCompany,
    this.profilePicture,
    this.latitude,
    this.longitude,
    this.deviceToken,
    this.employeeId,
    this.assignedVehicleId,
    this.assignedVehicle,
    this.assignedVehiclePlate,
    this.assignedVehicleType,
    this.latestLocation,
    this.user,
    this.locationHistory = const [],
    this.isActive,
    this.isPartner,
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
  String? firstName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? lastName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? licenseNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? phone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? rating;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? zone;

  DriverDtoVehicleTypeEnum? vehicleType;

  DriverDtoStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastLocationAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? partnerCompany;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? profilePicture;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? latitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? longitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? deviceToken;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? employeeId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? assignedVehicleId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  VehicleDto? assignedVehicle;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? assignedVehiclePlate;

  DriverDtoAssignedVehicleTypeEnum? assignedVehicleType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  LocationHistoryDto? latestLocation;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  UserSimpleDto? user;

  List<LocationHistoryDto> locationHistory;

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
  bool? isPartner;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverDto &&
    other.id == id &&
    other.firstName == firstName &&
    other.lastName == lastName &&
    other.name == name &&
    other.licenseNumber == licenseNumber &&
    other.phone == phone &&
    other.rating == rating &&
    other.zone == zone &&
    other.vehicleType == vehicleType &&
    other.status == status &&
    other.lastLocationAt == lastLocationAt &&
    other.partnerCompany == partnerCompany &&
    other.profilePicture == profilePicture &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.deviceToken == deviceToken &&
    other.employeeId == employeeId &&
    other.assignedVehicleId == assignedVehicleId &&
    other.assignedVehicle == assignedVehicle &&
    other.assignedVehiclePlate == assignedVehiclePlate &&
    other.assignedVehicleType == assignedVehicleType &&
    other.latestLocation == latestLocation &&
    other.user == user &&
    _deepEquality.equals(other.locationHistory, locationHistory) &&
    other.isActive == isActive &&
    other.isPartner == isPartner;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (firstName == null ? 0 : firstName!.hashCode) +
    (lastName == null ? 0 : lastName!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (licenseNumber == null ? 0 : licenseNumber!.hashCode) +
    (phone == null ? 0 : phone!.hashCode) +
    (rating == null ? 0 : rating!.hashCode) +
    (zone == null ? 0 : zone!.hashCode) +
    (vehicleType == null ? 0 : vehicleType!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (lastLocationAt == null ? 0 : lastLocationAt!.hashCode) +
    (partnerCompany == null ? 0 : partnerCompany!.hashCode) +
    (profilePicture == null ? 0 : profilePicture!.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (deviceToken == null ? 0 : deviceToken!.hashCode) +
    (employeeId == null ? 0 : employeeId!.hashCode) +
    (assignedVehicleId == null ? 0 : assignedVehicleId!.hashCode) +
    (assignedVehicle == null ? 0 : assignedVehicle!.hashCode) +
    (assignedVehiclePlate == null ? 0 : assignedVehiclePlate!.hashCode) +
    (assignedVehicleType == null ? 0 : assignedVehicleType!.hashCode) +
    (latestLocation == null ? 0 : latestLocation!.hashCode) +
    (user == null ? 0 : user!.hashCode) +
    (locationHistory.hashCode) +
    (isActive == null ? 0 : isActive!.hashCode) +
    (isPartner == null ? 0 : isPartner!.hashCode);

  @override
  String toString() => 'DriverDto[id=$id, firstName=$firstName, lastName=$lastName, name=$name, licenseNumber=$licenseNumber, phone=$phone, rating=$rating, zone=$zone, vehicleType=$vehicleType, status=$status, lastLocationAt=$lastLocationAt, partnerCompany=$partnerCompany, profilePicture=$profilePicture, latitude=$latitude, longitude=$longitude, deviceToken=$deviceToken, employeeId=$employeeId, assignedVehicleId=$assignedVehicleId, assignedVehicle=$assignedVehicle, assignedVehiclePlate=$assignedVehiclePlate, assignedVehicleType=$assignedVehicleType, latestLocation=$latestLocation, user=$user, locationHistory=$locationHistory, isActive=$isActive, isPartner=$isPartner]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.firstName != null) {
      json[r'firstName'] = this.firstName;
    } else {
      json[r'firstName'] = null;
    }
    if (this.lastName != null) {
      json[r'lastName'] = this.lastName;
    } else {
      json[r'lastName'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.licenseNumber != null) {
      json[r'licenseNumber'] = this.licenseNumber;
    } else {
      json[r'licenseNumber'] = null;
    }
    if (this.phone != null) {
      json[r'phone'] = this.phone;
    } else {
      json[r'phone'] = null;
    }
    if (this.rating != null) {
      json[r'rating'] = this.rating;
    } else {
      json[r'rating'] = null;
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
    if (this.lastLocationAt != null) {
      json[r'lastLocationAt'] = this.lastLocationAt!.toUtc().toIso8601String();
    } else {
      json[r'lastLocationAt'] = null;
    }
    if (this.partnerCompany != null) {
      json[r'partnerCompany'] = this.partnerCompany;
    } else {
      json[r'partnerCompany'] = null;
    }
    if (this.profilePicture != null) {
      json[r'profilePicture'] = this.profilePicture;
    } else {
      json[r'profilePicture'] = null;
    }
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
    if (this.deviceToken != null) {
      json[r'deviceToken'] = this.deviceToken;
    } else {
      json[r'deviceToken'] = null;
    }
    if (this.employeeId != null) {
      json[r'employeeId'] = this.employeeId;
    } else {
      json[r'employeeId'] = null;
    }
    if (this.assignedVehicleId != null) {
      json[r'assignedVehicleId'] = this.assignedVehicleId;
    } else {
      json[r'assignedVehicleId'] = null;
    }
    if (this.assignedVehicle != null) {
      json[r'assignedVehicle'] = this.assignedVehicle;
    } else {
      json[r'assignedVehicle'] = null;
    }
    if (this.assignedVehiclePlate != null) {
      json[r'assignedVehiclePlate'] = this.assignedVehiclePlate;
    } else {
      json[r'assignedVehiclePlate'] = null;
    }
    if (this.assignedVehicleType != null) {
      json[r'assignedVehicleType'] = this.assignedVehicleType;
    } else {
      json[r'assignedVehicleType'] = null;
    }
    if (this.latestLocation != null) {
      json[r'latestLocation'] = this.latestLocation;
    } else {
      json[r'latestLocation'] = null;
    }
    if (this.user != null) {
      json[r'user'] = this.user;
    } else {
      json[r'user'] = null;
    }
      json[r'locationHistory'] = this.locationHistory;
    if (this.isActive != null) {
      json[r'isActive'] = this.isActive;
    } else {
      json[r'isActive'] = null;
    }
    if (this.isPartner != null) {
      json[r'isPartner'] = this.isPartner;
    } else {
      json[r'isPartner'] = null;
    }
    return json;
  }

  /// Returns a new [DriverDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DriverDto(
        id: mapValueOfType<int>(json, r'id'),
        firstName: mapValueOfType<String>(json, r'firstName'),
        lastName: mapValueOfType<String>(json, r'lastName'),
        name: mapValueOfType<String>(json, r'name'),
        licenseNumber: mapValueOfType<String>(json, r'licenseNumber'),
        phone: mapValueOfType<String>(json, r'phone'),
        rating: mapValueOfType<double>(json, r'rating'),
        zone: mapValueOfType<String>(json, r'zone'),
        vehicleType: DriverDtoVehicleTypeEnum.fromJson(json[r'vehicleType']),
        status: DriverDtoStatusEnum.fromJson(json[r'status']),
        lastLocationAt: mapDateTime(json, r'lastLocationAt', r''),
        partnerCompany: mapValueOfType<String>(json, r'partnerCompany'),
        profilePicture: mapValueOfType<String>(json, r'profilePicture'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        deviceToken: mapValueOfType<String>(json, r'deviceToken'),
        employeeId: mapValueOfType<int>(json, r'employeeId'),
        assignedVehicleId: mapValueOfType<int>(json, r'assignedVehicleId'),
        assignedVehicle: VehicleDto.fromJson(json[r'assignedVehicle']),
        assignedVehiclePlate: mapValueOfType<String>(json, r'assignedVehiclePlate'),
        assignedVehicleType: DriverDtoAssignedVehicleTypeEnum.fromJson(json[r'assignedVehicleType']),
        latestLocation: LocationHistoryDto.fromJson(json[r'latestLocation']),
        user: UserSimpleDto.fromJson(json[r'user']),
        locationHistory: LocationHistoryDto.listFromJson(json[r'locationHistory']),
        isActive: mapValueOfType<bool>(json, r'isActive'),
        isPartner: mapValueOfType<bool>(json, r'isPartner'),
      );
    }
    return null;
  }

  static List<DriverDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverDto> mapFromJson(dynamic json) {
    final map = <String, DriverDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverDto-objects as value to a dart map
  static Map<String, List<DriverDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class DriverDtoVehicleTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverDtoVehicleTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BIG_TRUCK = DriverDtoVehicleTypeEnum._(r'BIG_TRUCK');
  static const TRUCK = DriverDtoVehicleTypeEnum._(r'TRUCK');
  static const TRAILER = DriverDtoVehicleTypeEnum._(r'TRAILER');
  static const SMALL_VAN = DriverDtoVehicleTypeEnum._(r'SMALL_VAN');
  static const VAN = DriverDtoVehicleTypeEnum._(r'VAN');
  static const SUV = DriverDtoVehicleTypeEnum._(r'SUV');
  static const CAR = DriverDtoVehicleTypeEnum._(r'CAR');
  static const BUS = DriverDtoVehicleTypeEnum._(r'BUS');
  static const MOTORBIKE = DriverDtoVehicleTypeEnum._(r'MOTORBIKE');
  static const ELECTRIC = DriverDtoVehicleTypeEnum._(r'ELECTRIC');
  static const OTHER = DriverDtoVehicleTypeEnum._(r'OTHER');
  static const UNKNOWN = DriverDtoVehicleTypeEnum._(r'UNKNOWN');

  /// List of all possible values in this [enum][DriverDtoVehicleTypeEnum].
  static const values = <DriverDtoVehicleTypeEnum>[
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

  static DriverDtoVehicleTypeEnum? fromJson(dynamic value) => DriverDtoVehicleTypeEnumTypeTransformer().decode(value);

  static List<DriverDtoVehicleTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverDtoVehicleTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverDtoVehicleTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverDtoVehicleTypeEnum] to String,
/// and [decode] dynamic data back to [DriverDtoVehicleTypeEnum].
class DriverDtoVehicleTypeEnumTypeTransformer {
  factory DriverDtoVehicleTypeEnumTypeTransformer() => _instance ??= const DriverDtoVehicleTypeEnumTypeTransformer._();

  const DriverDtoVehicleTypeEnumTypeTransformer._();

  String encode(DriverDtoVehicleTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverDtoVehicleTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverDtoVehicleTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BIG_TRUCK': return DriverDtoVehicleTypeEnum.BIG_TRUCK;
        case r'TRUCK': return DriverDtoVehicleTypeEnum.TRUCK;
        case r'TRAILER': return DriverDtoVehicleTypeEnum.TRAILER;
        case r'SMALL_VAN': return DriverDtoVehicleTypeEnum.SMALL_VAN;
        case r'VAN': return DriverDtoVehicleTypeEnum.VAN;
        case r'SUV': return DriverDtoVehicleTypeEnum.SUV;
        case r'CAR': return DriverDtoVehicleTypeEnum.CAR;
        case r'BUS': return DriverDtoVehicleTypeEnum.BUS;
        case r'MOTORBIKE': return DriverDtoVehicleTypeEnum.MOTORBIKE;
        case r'ELECTRIC': return DriverDtoVehicleTypeEnum.ELECTRIC;
        case r'OTHER': return DriverDtoVehicleTypeEnum.OTHER;
        case r'UNKNOWN': return DriverDtoVehicleTypeEnum.UNKNOWN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverDtoVehicleTypeEnumTypeTransformer] instance.
  static DriverDtoVehicleTypeEnumTypeTransformer? _instance;
}



class DriverDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ONLINE = DriverDtoStatusEnum._(r'ONLINE');
  static const OFFLINE = DriverDtoStatusEnum._(r'OFFLINE');
  static const BUSY = DriverDtoStatusEnum._(r'BUSY');
  static const IDLE = DriverDtoStatusEnum._(r'IDLE');

  /// List of all possible values in this [enum][DriverDtoStatusEnum].
  static const values = <DriverDtoStatusEnum>[
    ONLINE,
    OFFLINE,
    BUSY,
    IDLE,
  ];

  static DriverDtoStatusEnum? fromJson(dynamic value) => DriverDtoStatusEnumTypeTransformer().decode(value);

  static List<DriverDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverDtoStatusEnum] to String,
/// and [decode] dynamic data back to [DriverDtoStatusEnum].
class DriverDtoStatusEnumTypeTransformer {
  factory DriverDtoStatusEnumTypeTransformer() => _instance ??= const DriverDtoStatusEnumTypeTransformer._();

  const DriverDtoStatusEnumTypeTransformer._();

  String encode(DriverDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ONLINE': return DriverDtoStatusEnum.ONLINE;
        case r'OFFLINE': return DriverDtoStatusEnum.OFFLINE;
        case r'BUSY': return DriverDtoStatusEnum.BUSY;
        case r'IDLE': return DriverDtoStatusEnum.IDLE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverDtoStatusEnumTypeTransformer] instance.
  static DriverDtoStatusEnumTypeTransformer? _instance;
}



class DriverDtoAssignedVehicleTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverDtoAssignedVehicleTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BIG_TRUCK = DriverDtoAssignedVehicleTypeEnum._(r'BIG_TRUCK');
  static const TRUCK = DriverDtoAssignedVehicleTypeEnum._(r'TRUCK');
  static const TRAILER = DriverDtoAssignedVehicleTypeEnum._(r'TRAILER');
  static const SMALL_VAN = DriverDtoAssignedVehicleTypeEnum._(r'SMALL_VAN');
  static const VAN = DriverDtoAssignedVehicleTypeEnum._(r'VAN');
  static const SUV = DriverDtoAssignedVehicleTypeEnum._(r'SUV');
  static const CAR = DriverDtoAssignedVehicleTypeEnum._(r'CAR');
  static const BUS = DriverDtoAssignedVehicleTypeEnum._(r'BUS');
  static const MOTORBIKE = DriverDtoAssignedVehicleTypeEnum._(r'MOTORBIKE');
  static const ELECTRIC = DriverDtoAssignedVehicleTypeEnum._(r'ELECTRIC');
  static const OTHER = DriverDtoAssignedVehicleTypeEnum._(r'OTHER');
  static const UNKNOWN = DriverDtoAssignedVehicleTypeEnum._(r'UNKNOWN');

  /// List of all possible values in this [enum][DriverDtoAssignedVehicleTypeEnum].
  static const values = <DriverDtoAssignedVehicleTypeEnum>[
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

  static DriverDtoAssignedVehicleTypeEnum? fromJson(dynamic value) => DriverDtoAssignedVehicleTypeEnumTypeTransformer().decode(value);

  static List<DriverDtoAssignedVehicleTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverDtoAssignedVehicleTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverDtoAssignedVehicleTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverDtoAssignedVehicleTypeEnum] to String,
/// and [decode] dynamic data back to [DriverDtoAssignedVehicleTypeEnum].
class DriverDtoAssignedVehicleTypeEnumTypeTransformer {
  factory DriverDtoAssignedVehicleTypeEnumTypeTransformer() => _instance ??= const DriverDtoAssignedVehicleTypeEnumTypeTransformer._();

  const DriverDtoAssignedVehicleTypeEnumTypeTransformer._();

  String encode(DriverDtoAssignedVehicleTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverDtoAssignedVehicleTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverDtoAssignedVehicleTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BIG_TRUCK': return DriverDtoAssignedVehicleTypeEnum.BIG_TRUCK;
        case r'TRUCK': return DriverDtoAssignedVehicleTypeEnum.TRUCK;
        case r'TRAILER': return DriverDtoAssignedVehicleTypeEnum.TRAILER;
        case r'SMALL_VAN': return DriverDtoAssignedVehicleTypeEnum.SMALL_VAN;
        case r'VAN': return DriverDtoAssignedVehicleTypeEnum.VAN;
        case r'SUV': return DriverDtoAssignedVehicleTypeEnum.SUV;
        case r'CAR': return DriverDtoAssignedVehicleTypeEnum.CAR;
        case r'BUS': return DriverDtoAssignedVehicleTypeEnum.BUS;
        case r'MOTORBIKE': return DriverDtoAssignedVehicleTypeEnum.MOTORBIKE;
        case r'ELECTRIC': return DriverDtoAssignedVehicleTypeEnum.ELECTRIC;
        case r'OTHER': return DriverDtoAssignedVehicleTypeEnum.OTHER;
        case r'UNKNOWN': return DriverDtoAssignedVehicleTypeEnum.UNKNOWN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverDtoAssignedVehicleTypeEnumTypeTransformer] instance.
  static DriverDtoAssignedVehicleTypeEnumTypeTransformer? _instance;
}


