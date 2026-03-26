//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DeviceRegisterDto {
  /// Returns a new [DeviceRegisterDto] instance.
  DeviceRegisterDto({
    this.id,
    this.driverId,
    this.driverName,
    this.deviceId,
    this.deviceName,
    this.os,
    this.version,
    this.appVersion,
    this.manufacturer,
    this.model,
    this.ipAddress,
    this.location,
    this.status,
    this.registeredAt,
    this.approvedBy,
    this.statusUpdatedAt,
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
  int? driverId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? driverName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? deviceId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? deviceName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? os;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? version;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? appVersion;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? manufacturer;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? model;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? ipAddress;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? location;

  DeviceRegisterDtoStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? registeredAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? approvedBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? statusUpdatedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DeviceRegisterDto &&
    other.id == id &&
    other.driverId == driverId &&
    other.driverName == driverName &&
    other.deviceId == deviceId &&
    other.deviceName == deviceName &&
    other.os == os &&
    other.version == version &&
    other.appVersion == appVersion &&
    other.manufacturer == manufacturer &&
    other.model == model &&
    other.ipAddress == ipAddress &&
    other.location == location &&
    other.status == status &&
    other.registeredAt == registeredAt &&
    other.approvedBy == approvedBy &&
    other.statusUpdatedAt == statusUpdatedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (driverId == null ? 0 : driverId!.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (deviceId == null ? 0 : deviceId!.hashCode) +
    (deviceName == null ? 0 : deviceName!.hashCode) +
    (os == null ? 0 : os!.hashCode) +
    (version == null ? 0 : version!.hashCode) +
    (appVersion == null ? 0 : appVersion!.hashCode) +
    (manufacturer == null ? 0 : manufacturer!.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (ipAddress == null ? 0 : ipAddress!.hashCode) +
    (location == null ? 0 : location!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (registeredAt == null ? 0 : registeredAt!.hashCode) +
    (approvedBy == null ? 0 : approvedBy!.hashCode) +
    (statusUpdatedAt == null ? 0 : statusUpdatedAt!.hashCode);

  @override
  String toString() => 'DeviceRegisterDto[id=$id, driverId=$driverId, driverName=$driverName, deviceId=$deviceId, deviceName=$deviceName, os=$os, version=$version, appVersion=$appVersion, manufacturer=$manufacturer, model=$model, ipAddress=$ipAddress, location=$location, status=$status, registeredAt=$registeredAt, approvedBy=$approvedBy, statusUpdatedAt=$statusUpdatedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.driverId != null) {
      json[r'driverId'] = this.driverId;
    } else {
      json[r'driverId'] = null;
    }
    if (this.driverName != null) {
      json[r'driverName'] = this.driverName;
    } else {
      json[r'driverName'] = null;
    }
    if (this.deviceId != null) {
      json[r'deviceId'] = this.deviceId;
    } else {
      json[r'deviceId'] = null;
    }
    if (this.deviceName != null) {
      json[r'deviceName'] = this.deviceName;
    } else {
      json[r'deviceName'] = null;
    }
    if (this.os != null) {
      json[r'os'] = this.os;
    } else {
      json[r'os'] = null;
    }
    if (this.version != null) {
      json[r'version'] = this.version;
    } else {
      json[r'version'] = null;
    }
    if (this.appVersion != null) {
      json[r'appVersion'] = this.appVersion;
    } else {
      json[r'appVersion'] = null;
    }
    if (this.manufacturer != null) {
      json[r'manufacturer'] = this.manufacturer;
    } else {
      json[r'manufacturer'] = null;
    }
    if (this.model != null) {
      json[r'model'] = this.model;
    } else {
      json[r'model'] = null;
    }
    if (this.ipAddress != null) {
      json[r'ipAddress'] = this.ipAddress;
    } else {
      json[r'ipAddress'] = null;
    }
    if (this.location != null) {
      json[r'location'] = this.location;
    } else {
      json[r'location'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.registeredAt != null) {
      json[r'registeredAt'] = this.registeredAt!.toUtc().toIso8601String();
    } else {
      json[r'registeredAt'] = null;
    }
    if (this.approvedBy != null) {
      json[r'approvedBy'] = this.approvedBy;
    } else {
      json[r'approvedBy'] = null;
    }
    if (this.statusUpdatedAt != null) {
      json[r'statusUpdatedAt'] = this.statusUpdatedAt!.toUtc().toIso8601String();
    } else {
      json[r'statusUpdatedAt'] = null;
    }
    return json;
  }

  /// Returns a new [DeviceRegisterDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeviceRegisterDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DeviceRegisterDto(
        id: mapValueOfType<int>(json, r'id'),
        driverId: mapValueOfType<int>(json, r'driverId'),
        driverName: mapValueOfType<String>(json, r'driverName'),
        deviceId: mapValueOfType<String>(json, r'deviceId'),
        deviceName: mapValueOfType<String>(json, r'deviceName'),
        os: mapValueOfType<String>(json, r'os'),
        version: mapValueOfType<String>(json, r'version'),
        appVersion: mapValueOfType<String>(json, r'appVersion'),
        manufacturer: mapValueOfType<String>(json, r'manufacturer'),
        model: mapValueOfType<String>(json, r'model'),
        ipAddress: mapValueOfType<String>(json, r'ipAddress'),
        location: mapValueOfType<String>(json, r'location'),
        status: DeviceRegisterDtoStatusEnum.fromJson(json[r'status']),
        registeredAt: mapDateTime(json, r'registeredAt', r''),
        approvedBy: mapValueOfType<String>(json, r'approvedBy'),
        statusUpdatedAt: mapDateTime(json, r'statusUpdatedAt', r''),
      );
    }
    return null;
  }

  static List<DeviceRegisterDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceRegisterDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceRegisterDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeviceRegisterDto> mapFromJson(dynamic json) {
    final map = <String, DeviceRegisterDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeviceRegisterDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeviceRegisterDto-objects as value to a dart map
  static Map<String, List<DeviceRegisterDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DeviceRegisterDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeviceRegisterDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class DeviceRegisterDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DeviceRegisterDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = DeviceRegisterDtoStatusEnum._(r'PENDING');
  static const APPROVED = DeviceRegisterDtoStatusEnum._(r'APPROVED');
  static const BLOCKED = DeviceRegisterDtoStatusEnum._(r'BLOCKED');
  static const REJECTED = DeviceRegisterDtoStatusEnum._(r'REJECTED');

  /// List of all possible values in this [enum][DeviceRegisterDtoStatusEnum].
  static const values = <DeviceRegisterDtoStatusEnum>[
    PENDING,
    APPROVED,
    BLOCKED,
    REJECTED,
  ];

  static DeviceRegisterDtoStatusEnum? fromJson(dynamic value) => DeviceRegisterDtoStatusEnumTypeTransformer().decode(value);

  static List<DeviceRegisterDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceRegisterDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceRegisterDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DeviceRegisterDtoStatusEnum] to String,
/// and [decode] dynamic data back to [DeviceRegisterDtoStatusEnum].
class DeviceRegisterDtoStatusEnumTypeTransformer {
  factory DeviceRegisterDtoStatusEnumTypeTransformer() => _instance ??= const DeviceRegisterDtoStatusEnumTypeTransformer._();

  const DeviceRegisterDtoStatusEnumTypeTransformer._();

  String encode(DeviceRegisterDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DeviceRegisterDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DeviceRegisterDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return DeviceRegisterDtoStatusEnum.PENDING;
        case r'APPROVED': return DeviceRegisterDtoStatusEnum.APPROVED;
        case r'BLOCKED': return DeviceRegisterDtoStatusEnum.BLOCKED;
        case r'REJECTED': return DeviceRegisterDtoStatusEnum.REJECTED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DeviceRegisterDtoStatusEnumTypeTransformer] instance.
  static DeviceRegisterDtoStatusEnumTypeTransformer? _instance;
}


