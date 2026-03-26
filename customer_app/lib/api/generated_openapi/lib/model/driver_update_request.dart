//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverUpdateRequest {
  /// Returns a new [DriverUpdateRequest] instance.
  DriverUpdateRequest({
    this.name,
    required this.firstName,
    required this.lastName,
    this.licenseNumber,
    required this.phone,
    required this.rating,
    required this.isActive,
    this.zone,
    required this.vehicleType,
    required this.status,
    this.profilePicture,
    this.latitude,
    this.longitude,
    this.deviceToken,
    this.isPartner,
    this.partnerCompany,
    this.employeeId,
    this.vehicleId,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  String firstName;

  String lastName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? licenseNumber;

  String phone;

  double rating;

  bool isActive;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? zone;

  DriverUpdateRequestVehicleTypeEnum vehicleType;

  DriverUpdateRequestStatusEnum status;

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
  bool? isPartner;

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
  int? employeeId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vehicleId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverUpdateRequest &&
    other.name == name &&
    other.firstName == firstName &&
    other.lastName == lastName &&
    other.licenseNumber == licenseNumber &&
    other.phone == phone &&
    other.rating == rating &&
    other.isActive == isActive &&
    other.zone == zone &&
    other.vehicleType == vehicleType &&
    other.status == status &&
    other.profilePicture == profilePicture &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.deviceToken == deviceToken &&
    other.isPartner == isPartner &&
    other.partnerCompany == partnerCompany &&
    other.employeeId == employeeId &&
    other.vehicleId == vehicleId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name == null ? 0 : name!.hashCode) +
    (firstName.hashCode) +
    (lastName.hashCode) +
    (licenseNumber == null ? 0 : licenseNumber!.hashCode) +
    (phone.hashCode) +
    (rating.hashCode) +
    (isActive.hashCode) +
    (zone == null ? 0 : zone!.hashCode) +
    (vehicleType.hashCode) +
    (status.hashCode) +
    (profilePicture == null ? 0 : profilePicture!.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (deviceToken == null ? 0 : deviceToken!.hashCode) +
    (isPartner == null ? 0 : isPartner!.hashCode) +
    (partnerCompany == null ? 0 : partnerCompany!.hashCode) +
    (employeeId == null ? 0 : employeeId!.hashCode) +
    (vehicleId == null ? 0 : vehicleId!.hashCode);

  @override
  String toString() => 'DriverUpdateRequest[name=$name, firstName=$firstName, lastName=$lastName, licenseNumber=$licenseNumber, phone=$phone, rating=$rating, isActive=$isActive, zone=$zone, vehicleType=$vehicleType, status=$status, profilePicture=$profilePicture, latitude=$latitude, longitude=$longitude, deviceToken=$deviceToken, isPartner=$isPartner, partnerCompany=$partnerCompany, employeeId=$employeeId, vehicleId=$vehicleId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
      json[r'firstName'] = this.firstName;
      json[r'lastName'] = this.lastName;
    if (this.licenseNumber != null) {
      json[r'licenseNumber'] = this.licenseNumber;
    } else {
      json[r'licenseNumber'] = null;
    }
      json[r'phone'] = this.phone;
      json[r'rating'] = this.rating;
      json[r'isActive'] = this.isActive;
    if (this.zone != null) {
      json[r'zone'] = this.zone;
    } else {
      json[r'zone'] = null;
    }
      json[r'vehicleType'] = this.vehicleType;
      json[r'status'] = this.status;
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
    if (this.isPartner != null) {
      json[r'isPartner'] = this.isPartner;
    } else {
      json[r'isPartner'] = null;
    }
    if (this.partnerCompany != null) {
      json[r'partnerCompany'] = this.partnerCompany;
    } else {
      json[r'partnerCompany'] = null;
    }
    if (this.employeeId != null) {
      json[r'employeeId'] = this.employeeId;
    } else {
      json[r'employeeId'] = null;
    }
    if (this.vehicleId != null) {
      json[r'vehicleId'] = this.vehicleId;
    } else {
      json[r'vehicleId'] = null;
    }
    return json;
  }

  /// Returns a new [DriverUpdateRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverUpdateRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'firstName'), 'Required key "DriverUpdateRequest[firstName]" is missing from JSON.');
        assert(json[r'firstName'] != null, 'Required key "DriverUpdateRequest[firstName]" has a null value in JSON.');
        assert(json.containsKey(r'lastName'), 'Required key "DriverUpdateRequest[lastName]" is missing from JSON.');
        assert(json[r'lastName'] != null, 'Required key "DriverUpdateRequest[lastName]" has a null value in JSON.');
        assert(json.containsKey(r'phone'), 'Required key "DriverUpdateRequest[phone]" is missing from JSON.');
        assert(json[r'phone'] != null, 'Required key "DriverUpdateRequest[phone]" has a null value in JSON.');
        assert(json.containsKey(r'rating'), 'Required key "DriverUpdateRequest[rating]" is missing from JSON.');
        assert(json[r'rating'] != null, 'Required key "DriverUpdateRequest[rating]" has a null value in JSON.');
        assert(json.containsKey(r'isActive'), 'Required key "DriverUpdateRequest[isActive]" is missing from JSON.');
        assert(json[r'isActive'] != null, 'Required key "DriverUpdateRequest[isActive]" has a null value in JSON.');
        assert(json.containsKey(r'vehicleType'), 'Required key "DriverUpdateRequest[vehicleType]" is missing from JSON.');
        assert(json[r'vehicleType'] != null, 'Required key "DriverUpdateRequest[vehicleType]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "DriverUpdateRequest[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "DriverUpdateRequest[status]" has a null value in JSON.');
        return true;
      }());

      return DriverUpdateRequest(
        name: mapValueOfType<String>(json, r'name'),
        firstName: mapValueOfType<String>(json, r'firstName')!,
        lastName: mapValueOfType<String>(json, r'lastName')!,
        licenseNumber: mapValueOfType<String>(json, r'licenseNumber'),
        phone: mapValueOfType<String>(json, r'phone')!,
        rating: mapValueOfType<double>(json, r'rating')!,
        isActive: mapValueOfType<bool>(json, r'isActive')!,
        zone: mapValueOfType<String>(json, r'zone'),
        vehicleType: DriverUpdateRequestVehicleTypeEnum.fromJson(json[r'vehicleType'])!,
        status: DriverUpdateRequestStatusEnum.fromJson(json[r'status'])!,
        profilePicture: mapValueOfType<String>(json, r'profilePicture'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        deviceToken: mapValueOfType<String>(json, r'deviceToken'),
        isPartner: mapValueOfType<bool>(json, r'isPartner'),
        partnerCompany: mapValueOfType<String>(json, r'partnerCompany'),
        employeeId: mapValueOfType<int>(json, r'employeeId'),
        vehicleId: mapValueOfType<int>(json, r'vehicleId'),
      );
    }
    return null;
  }

  static List<DriverUpdateRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverUpdateRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverUpdateRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverUpdateRequest> mapFromJson(dynamic json) {
    final map = <String, DriverUpdateRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverUpdateRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverUpdateRequest-objects as value to a dart map
  static Map<String, List<DriverUpdateRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverUpdateRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverUpdateRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'firstName',
    'lastName',
    'phone',
    'rating',
    'isActive',
    'vehicleType',
    'status',
  };
}


class DriverUpdateRequestVehicleTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverUpdateRequestVehicleTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BIG_TRUCK = DriverUpdateRequestVehicleTypeEnum._(r'BIG_TRUCK');
  static const TRUCK = DriverUpdateRequestVehicleTypeEnum._(r'TRUCK');
  static const TRAILER = DriverUpdateRequestVehicleTypeEnum._(r'TRAILER');
  static const SMALL_VAN = DriverUpdateRequestVehicleTypeEnum._(r'SMALL_VAN');
  static const VAN = DriverUpdateRequestVehicleTypeEnum._(r'VAN');
  static const SUV = DriverUpdateRequestVehicleTypeEnum._(r'SUV');
  static const CAR = DriverUpdateRequestVehicleTypeEnum._(r'CAR');
  static const BUS = DriverUpdateRequestVehicleTypeEnum._(r'BUS');
  static const MOTORBIKE = DriverUpdateRequestVehicleTypeEnum._(r'MOTORBIKE');
  static const ELECTRIC = DriverUpdateRequestVehicleTypeEnum._(r'ELECTRIC');
  static const OTHER = DriverUpdateRequestVehicleTypeEnum._(r'OTHER');
  static const UNKNOWN = DriverUpdateRequestVehicleTypeEnum._(r'UNKNOWN');

  /// List of all possible values in this [enum][DriverUpdateRequestVehicleTypeEnum].
  static const values = <DriverUpdateRequestVehicleTypeEnum>[
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

  static DriverUpdateRequestVehicleTypeEnum? fromJson(dynamic value) => DriverUpdateRequestVehicleTypeEnumTypeTransformer().decode(value);

  static List<DriverUpdateRequestVehicleTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverUpdateRequestVehicleTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverUpdateRequestVehicleTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverUpdateRequestVehicleTypeEnum] to String,
/// and [decode] dynamic data back to [DriverUpdateRequestVehicleTypeEnum].
class DriverUpdateRequestVehicleTypeEnumTypeTransformer {
  factory DriverUpdateRequestVehicleTypeEnumTypeTransformer() => _instance ??= const DriverUpdateRequestVehicleTypeEnumTypeTransformer._();

  const DriverUpdateRequestVehicleTypeEnumTypeTransformer._();

  String encode(DriverUpdateRequestVehicleTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverUpdateRequestVehicleTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverUpdateRequestVehicleTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BIG_TRUCK': return DriverUpdateRequestVehicleTypeEnum.BIG_TRUCK;
        case r'TRUCK': return DriverUpdateRequestVehicleTypeEnum.TRUCK;
        case r'TRAILER': return DriverUpdateRequestVehicleTypeEnum.TRAILER;
        case r'SMALL_VAN': return DriverUpdateRequestVehicleTypeEnum.SMALL_VAN;
        case r'VAN': return DriverUpdateRequestVehicleTypeEnum.VAN;
        case r'SUV': return DriverUpdateRequestVehicleTypeEnum.SUV;
        case r'CAR': return DriverUpdateRequestVehicleTypeEnum.CAR;
        case r'BUS': return DriverUpdateRequestVehicleTypeEnum.BUS;
        case r'MOTORBIKE': return DriverUpdateRequestVehicleTypeEnum.MOTORBIKE;
        case r'ELECTRIC': return DriverUpdateRequestVehicleTypeEnum.ELECTRIC;
        case r'OTHER': return DriverUpdateRequestVehicleTypeEnum.OTHER;
        case r'UNKNOWN': return DriverUpdateRequestVehicleTypeEnum.UNKNOWN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverUpdateRequestVehicleTypeEnumTypeTransformer] instance.
  static DriverUpdateRequestVehicleTypeEnumTypeTransformer? _instance;
}



class DriverUpdateRequestStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverUpdateRequestStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ONLINE = DriverUpdateRequestStatusEnum._(r'ONLINE');
  static const OFFLINE = DriverUpdateRequestStatusEnum._(r'OFFLINE');
  static const BUSY = DriverUpdateRequestStatusEnum._(r'BUSY');
  static const IDLE = DriverUpdateRequestStatusEnum._(r'IDLE');

  /// List of all possible values in this [enum][DriverUpdateRequestStatusEnum].
  static const values = <DriverUpdateRequestStatusEnum>[
    ONLINE,
    OFFLINE,
    BUSY,
    IDLE,
  ];

  static DriverUpdateRequestStatusEnum? fromJson(dynamic value) => DriverUpdateRequestStatusEnumTypeTransformer().decode(value);

  static List<DriverUpdateRequestStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverUpdateRequestStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverUpdateRequestStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverUpdateRequestStatusEnum] to String,
/// and [decode] dynamic data back to [DriverUpdateRequestStatusEnum].
class DriverUpdateRequestStatusEnumTypeTransformer {
  factory DriverUpdateRequestStatusEnumTypeTransformer() => _instance ??= const DriverUpdateRequestStatusEnumTypeTransformer._();

  const DriverUpdateRequestStatusEnumTypeTransformer._();

  String encode(DriverUpdateRequestStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverUpdateRequestStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverUpdateRequestStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ONLINE': return DriverUpdateRequestStatusEnum.ONLINE;
        case r'OFFLINE': return DriverUpdateRequestStatusEnum.OFFLINE;
        case r'BUSY': return DriverUpdateRequestStatusEnum.BUSY;
        case r'IDLE': return DriverUpdateRequestStatusEnum.IDLE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverUpdateRequestStatusEnumTypeTransformer] instance.
  static DriverUpdateRequestStatusEnumTypeTransformer? _instance;
}


