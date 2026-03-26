//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverCreateRequest {
  /// Returns a new [DriverCreateRequest] instance.
  DriverCreateRequest({
    this.user,
    required this.firstName,
    required this.lastName,
    this.name,
    this.licenseNumber,
    required this.phone,
    this.rating,
    this.isActive,
    this.zone,
    this.vehicleType,
    this.status,
    this.latitude,
    this.longitude,
    this.deviceToken,
    this.profilePicture,
    this.partnerCompany,
    this.employeeId,
    this.assignedVehicleId,
    this.partner,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  RegisterRequest? user;

  String firstName;

  String lastName;

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

  String phone;

  /// Minimum value: 0.0
  /// Maximum value: 5.0
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
  bool? isActive;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? zone;

  DriverCreateRequestVehicleTypeEnum? vehicleType;

  DriverCreateRequestStatusEnum? status;

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
  String? profilePicture;

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
  int? assignedVehicleId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? partner;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverCreateRequest &&
    other.user == user &&
    other.firstName == firstName &&
    other.lastName == lastName &&
    other.name == name &&
    other.licenseNumber == licenseNumber &&
    other.phone == phone &&
    other.rating == rating &&
    other.isActive == isActive &&
    other.zone == zone &&
    other.vehicleType == vehicleType &&
    other.status == status &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    other.deviceToken == deviceToken &&
    other.profilePicture == profilePicture &&
    other.partnerCompany == partnerCompany &&
    other.employeeId == employeeId &&
    other.assignedVehicleId == assignedVehicleId &&
    other.partner == partner;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (user == null ? 0 : user!.hashCode) +
    (firstName.hashCode) +
    (lastName.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (licenseNumber == null ? 0 : licenseNumber!.hashCode) +
    (phone.hashCode) +
    (rating == null ? 0 : rating!.hashCode) +
    (isActive == null ? 0 : isActive!.hashCode) +
    (zone == null ? 0 : zone!.hashCode) +
    (vehicleType == null ? 0 : vehicleType!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (deviceToken == null ? 0 : deviceToken!.hashCode) +
    (profilePicture == null ? 0 : profilePicture!.hashCode) +
    (partnerCompany == null ? 0 : partnerCompany!.hashCode) +
    (employeeId == null ? 0 : employeeId!.hashCode) +
    (assignedVehicleId == null ? 0 : assignedVehicleId!.hashCode) +
    (partner == null ? 0 : partner!.hashCode);

  @override
  String toString() => 'DriverCreateRequest[user=$user, firstName=$firstName, lastName=$lastName, name=$name, licenseNumber=$licenseNumber, phone=$phone, rating=$rating, isActive=$isActive, zone=$zone, vehicleType=$vehicleType, status=$status, latitude=$latitude, longitude=$longitude, deviceToken=$deviceToken, profilePicture=$profilePicture, partnerCompany=$partnerCompany, employeeId=$employeeId, assignedVehicleId=$assignedVehicleId, partner=$partner]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.user != null) {
      json[r'user'] = this.user;
    } else {
      json[r'user'] = null;
    }
      json[r'firstName'] = this.firstName;
      json[r'lastName'] = this.lastName;
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
      json[r'phone'] = this.phone;
    if (this.rating != null) {
      json[r'rating'] = this.rating;
    } else {
      json[r'rating'] = null;
    }
    if (this.isActive != null) {
      json[r'isActive'] = this.isActive;
    } else {
      json[r'isActive'] = null;
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
    if (this.profilePicture != null) {
      json[r'profilePicture'] = this.profilePicture;
    } else {
      json[r'profilePicture'] = null;
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
    if (this.assignedVehicleId != null) {
      json[r'assignedVehicleId'] = this.assignedVehicleId;
    } else {
      json[r'assignedVehicleId'] = null;
    }
    if (this.partner != null) {
      json[r'partner'] = this.partner;
    } else {
      json[r'partner'] = null;
    }
    return json;
  }

  /// Returns a new [DriverCreateRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverCreateRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'firstName'), 'Required key "DriverCreateRequest[firstName]" is missing from JSON.');
        assert(json[r'firstName'] != null, 'Required key "DriverCreateRequest[firstName]" has a null value in JSON.');
        assert(json.containsKey(r'lastName'), 'Required key "DriverCreateRequest[lastName]" is missing from JSON.');
        assert(json[r'lastName'] != null, 'Required key "DriverCreateRequest[lastName]" has a null value in JSON.');
        assert(json.containsKey(r'phone'), 'Required key "DriverCreateRequest[phone]" is missing from JSON.');
        assert(json[r'phone'] != null, 'Required key "DriverCreateRequest[phone]" has a null value in JSON.');
        return true;
      }());

      return DriverCreateRequest(
        user: RegisterRequest.fromJson(json[r'user']),
        firstName: mapValueOfType<String>(json, r'firstName')!,
        lastName: mapValueOfType<String>(json, r'lastName')!,
        name: mapValueOfType<String>(json, r'name'),
        licenseNumber: mapValueOfType<String>(json, r'licenseNumber'),
        phone: mapValueOfType<String>(json, r'phone')!,
        rating: mapValueOfType<double>(json, r'rating'),
        isActive: mapValueOfType<bool>(json, r'isActive'),
        zone: mapValueOfType<String>(json, r'zone'),
        vehicleType: DriverCreateRequestVehicleTypeEnum.fromJson(json[r'vehicleType']),
        status: DriverCreateRequestStatusEnum.fromJson(json[r'status']),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        deviceToken: mapValueOfType<String>(json, r'deviceToken'),
        profilePicture: mapValueOfType<String>(json, r'profilePicture'),
        partnerCompany: mapValueOfType<String>(json, r'partnerCompany'),
        employeeId: mapValueOfType<int>(json, r'employeeId'),
        assignedVehicleId: mapValueOfType<int>(json, r'assignedVehicleId'),
        partner: mapValueOfType<bool>(json, r'partner'),
      );
    }
    return null;
  }

  static List<DriverCreateRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverCreateRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverCreateRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverCreateRequest> mapFromJson(dynamic json) {
    final map = <String, DriverCreateRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverCreateRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverCreateRequest-objects as value to a dart map
  static Map<String, List<DriverCreateRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverCreateRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverCreateRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'firstName',
    'lastName',
    'phone',
  };
}


class DriverCreateRequestVehicleTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverCreateRequestVehicleTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BIG_TRUCK = DriverCreateRequestVehicleTypeEnum._(r'BIG_TRUCK');
  static const TRUCK = DriverCreateRequestVehicleTypeEnum._(r'TRUCK');
  static const TRAILER = DriverCreateRequestVehicleTypeEnum._(r'TRAILER');
  static const SMALL_VAN = DriverCreateRequestVehicleTypeEnum._(r'SMALL_VAN');
  static const VAN = DriverCreateRequestVehicleTypeEnum._(r'VAN');
  static const SUV = DriverCreateRequestVehicleTypeEnum._(r'SUV');
  static const CAR = DriverCreateRequestVehicleTypeEnum._(r'CAR');
  static const BUS = DriverCreateRequestVehicleTypeEnum._(r'BUS');
  static const MOTORBIKE = DriverCreateRequestVehicleTypeEnum._(r'MOTORBIKE');
  static const ELECTRIC = DriverCreateRequestVehicleTypeEnum._(r'ELECTRIC');
  static const OTHER = DriverCreateRequestVehicleTypeEnum._(r'OTHER');
  static const UNKNOWN = DriverCreateRequestVehicleTypeEnum._(r'UNKNOWN');

  /// List of all possible values in this [enum][DriverCreateRequestVehicleTypeEnum].
  static const values = <DriverCreateRequestVehicleTypeEnum>[
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

  static DriverCreateRequestVehicleTypeEnum? fromJson(dynamic value) => DriverCreateRequestVehicleTypeEnumTypeTransformer().decode(value);

  static List<DriverCreateRequestVehicleTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverCreateRequestVehicleTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverCreateRequestVehicleTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverCreateRequestVehicleTypeEnum] to String,
/// and [decode] dynamic data back to [DriverCreateRequestVehicleTypeEnum].
class DriverCreateRequestVehicleTypeEnumTypeTransformer {
  factory DriverCreateRequestVehicleTypeEnumTypeTransformer() => _instance ??= const DriverCreateRequestVehicleTypeEnumTypeTransformer._();

  const DriverCreateRequestVehicleTypeEnumTypeTransformer._();

  String encode(DriverCreateRequestVehicleTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverCreateRequestVehicleTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverCreateRequestVehicleTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BIG_TRUCK': return DriverCreateRequestVehicleTypeEnum.BIG_TRUCK;
        case r'TRUCK': return DriverCreateRequestVehicleTypeEnum.TRUCK;
        case r'TRAILER': return DriverCreateRequestVehicleTypeEnum.TRAILER;
        case r'SMALL_VAN': return DriverCreateRequestVehicleTypeEnum.SMALL_VAN;
        case r'VAN': return DriverCreateRequestVehicleTypeEnum.VAN;
        case r'SUV': return DriverCreateRequestVehicleTypeEnum.SUV;
        case r'CAR': return DriverCreateRequestVehicleTypeEnum.CAR;
        case r'BUS': return DriverCreateRequestVehicleTypeEnum.BUS;
        case r'MOTORBIKE': return DriverCreateRequestVehicleTypeEnum.MOTORBIKE;
        case r'ELECTRIC': return DriverCreateRequestVehicleTypeEnum.ELECTRIC;
        case r'OTHER': return DriverCreateRequestVehicleTypeEnum.OTHER;
        case r'UNKNOWN': return DriverCreateRequestVehicleTypeEnum.UNKNOWN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverCreateRequestVehicleTypeEnumTypeTransformer] instance.
  static DriverCreateRequestVehicleTypeEnumTypeTransformer? _instance;
}



class DriverCreateRequestStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverCreateRequestStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ONLINE = DriverCreateRequestStatusEnum._(r'ONLINE');
  static const OFFLINE = DriverCreateRequestStatusEnum._(r'OFFLINE');
  static const BUSY = DriverCreateRequestStatusEnum._(r'BUSY');
  static const IDLE = DriverCreateRequestStatusEnum._(r'IDLE');

  /// List of all possible values in this [enum][DriverCreateRequestStatusEnum].
  static const values = <DriverCreateRequestStatusEnum>[
    ONLINE,
    OFFLINE,
    BUSY,
    IDLE,
  ];

  static DriverCreateRequestStatusEnum? fromJson(dynamic value) => DriverCreateRequestStatusEnumTypeTransformer().decode(value);

  static List<DriverCreateRequestStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverCreateRequestStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverCreateRequestStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverCreateRequestStatusEnum] to String,
/// and [decode] dynamic data back to [DriverCreateRequestStatusEnum].
class DriverCreateRequestStatusEnumTypeTransformer {
  factory DriverCreateRequestStatusEnumTypeTransformer() => _instance ??= const DriverCreateRequestStatusEnumTypeTransformer._();

  const DriverCreateRequestStatusEnumTypeTransformer._();

  String encode(DriverCreateRequestStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverCreateRequestStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverCreateRequestStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ONLINE': return DriverCreateRequestStatusEnum.ONLINE;
        case r'OFFLINE': return DriverCreateRequestStatusEnum.OFFLINE;
        case r'BUSY': return DriverCreateRequestStatusEnum.BUSY;
        case r'IDLE': return DriverCreateRequestStatusEnum.IDLE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverCreateRequestStatusEnumTypeTransformer] instance.
  static DriverCreateRequestStatusEnumTypeTransformer? _instance;
}


