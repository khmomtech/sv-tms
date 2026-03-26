//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class VehicleDto {
  /// Returns a new [VehicleDto] instance.
  VehicleDto({
    this.id,
    this.licensePlate,
    this.model,
    this.manufacturer,
    this.type,
    this.status,
    this.mileage,
    this.fuelConsumption,
    this.lastInspectionDate,
    this.lastServiceDate,
    this.nextServiceDue,
    this.year,
    this.truckSize,
    this.qtyPalletsCapacity,
    this.assignedZone,
    this.availableRoutes,
    this.unavailableRoutes,
    this.gpsDeviceId,
    this.remarks,
    this.assignedDriver,
    this.assignedVehicleId,
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
  String? licensePlate;

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
  String? manufacturer;

  VehicleDtoTypeEnum? type;

  VehicleDtoStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? mileage;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? fuelConsumption;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastInspectionDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastServiceDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? nextServiceDue;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? year;

  VehicleDtoTruckSizeEnum? truckSize;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? qtyPalletsCapacity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? assignedZone;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? availableRoutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? unavailableRoutes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? gpsDeviceId;

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
  DriverSimpleDto? assignedDriver;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? assignedVehicleId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is VehicleDto &&
    other.id == id &&
    other.licensePlate == licensePlate &&
    other.model == model &&
    other.manufacturer == manufacturer &&
    other.type == type &&
    other.status == status &&
    other.mileage == mileage &&
    other.fuelConsumption == fuelConsumption &&
    other.lastInspectionDate == lastInspectionDate &&
    other.lastServiceDate == lastServiceDate &&
    other.nextServiceDue == nextServiceDue &&
    other.year == year &&
    other.truckSize == truckSize &&
    other.qtyPalletsCapacity == qtyPalletsCapacity &&
    other.assignedZone == assignedZone &&
    other.availableRoutes == availableRoutes &&
    other.unavailableRoutes == unavailableRoutes &&
    other.gpsDeviceId == gpsDeviceId &&
    other.remarks == remarks &&
    other.assignedDriver == assignedDriver &&
    other.assignedVehicleId == assignedVehicleId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (licensePlate == null ? 0 : licensePlate!.hashCode) +
    (model == null ? 0 : model!.hashCode) +
    (manufacturer == null ? 0 : manufacturer!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (mileage == null ? 0 : mileage!.hashCode) +
    (fuelConsumption == null ? 0 : fuelConsumption!.hashCode) +
    (lastInspectionDate == null ? 0 : lastInspectionDate!.hashCode) +
    (lastServiceDate == null ? 0 : lastServiceDate!.hashCode) +
    (nextServiceDue == null ? 0 : nextServiceDue!.hashCode) +
    (year == null ? 0 : year!.hashCode) +
    (truckSize == null ? 0 : truckSize!.hashCode) +
    (qtyPalletsCapacity == null ? 0 : qtyPalletsCapacity!.hashCode) +
    (assignedZone == null ? 0 : assignedZone!.hashCode) +
    (availableRoutes == null ? 0 : availableRoutes!.hashCode) +
    (unavailableRoutes == null ? 0 : unavailableRoutes!.hashCode) +
    (gpsDeviceId == null ? 0 : gpsDeviceId!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (assignedDriver == null ? 0 : assignedDriver!.hashCode) +
    (assignedVehicleId == null ? 0 : assignedVehicleId!.hashCode);

  @override
  String toString() => 'VehicleDto[id=$id, licensePlate=$licensePlate, model=$model, manufacturer=$manufacturer, type=$type, status=$status, mileage=$mileage, fuelConsumption=$fuelConsumption, lastInspectionDate=$lastInspectionDate, lastServiceDate=$lastServiceDate, nextServiceDue=$nextServiceDue, year=$year, truckSize=$truckSize, qtyPalletsCapacity=$qtyPalletsCapacity, assignedZone=$assignedZone, availableRoutes=$availableRoutes, unavailableRoutes=$unavailableRoutes, gpsDeviceId=$gpsDeviceId, remarks=$remarks, assignedDriver=$assignedDriver, assignedVehicleId=$assignedVehicleId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.licensePlate != null) {
      json[r'licensePlate'] = this.licensePlate;
    } else {
      json[r'licensePlate'] = null;
    }
    if (this.model != null) {
      json[r'model'] = this.model;
    } else {
      json[r'model'] = null;
    }
    if (this.manufacturer != null) {
      json[r'manufacturer'] = this.manufacturer;
    } else {
      json[r'manufacturer'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.mileage != null) {
      json[r'mileage'] = this.mileage;
    } else {
      json[r'mileage'] = null;
    }
    if (this.fuelConsumption != null) {
      json[r'fuelConsumption'] = this.fuelConsumption;
    } else {
      json[r'fuelConsumption'] = null;
    }
    if (this.lastInspectionDate != null) {
      json[r'lastInspectionDate'] = this.lastInspectionDate!.toUtc().toIso8601String();
    } else {
      json[r'lastInspectionDate'] = null;
    }
    if (this.lastServiceDate != null) {
      json[r'lastServiceDate'] = this.lastServiceDate!.toUtc().toIso8601String();
    } else {
      json[r'lastServiceDate'] = null;
    }
    if (this.nextServiceDue != null) {
      json[r'nextServiceDue'] = this.nextServiceDue!.toUtc().toIso8601String();
    } else {
      json[r'nextServiceDue'] = null;
    }
    if (this.year != null) {
      json[r'year'] = this.year;
    } else {
      json[r'year'] = null;
    }
    if (this.truckSize != null) {
      json[r'truckSize'] = this.truckSize;
    } else {
      json[r'truckSize'] = null;
    }
    if (this.qtyPalletsCapacity != null) {
      json[r'qtyPalletsCapacity'] = this.qtyPalletsCapacity;
    } else {
      json[r'qtyPalletsCapacity'] = null;
    }
    if (this.assignedZone != null) {
      json[r'assignedZone'] = this.assignedZone;
    } else {
      json[r'assignedZone'] = null;
    }
    if (this.availableRoutes != null) {
      json[r'availableRoutes'] = this.availableRoutes;
    } else {
      json[r'availableRoutes'] = null;
    }
    if (this.unavailableRoutes != null) {
      json[r'unavailableRoutes'] = this.unavailableRoutes;
    } else {
      json[r'unavailableRoutes'] = null;
    }
    if (this.gpsDeviceId != null) {
      json[r'gpsDeviceId'] = this.gpsDeviceId;
    } else {
      json[r'gpsDeviceId'] = null;
    }
    if (this.remarks != null) {
      json[r'remarks'] = this.remarks;
    } else {
      json[r'remarks'] = null;
    }
    if (this.assignedDriver != null) {
      json[r'assignedDriver'] = this.assignedDriver;
    } else {
      json[r'assignedDriver'] = null;
    }
    if (this.assignedVehicleId != null) {
      json[r'assignedVehicleId'] = this.assignedVehicleId;
    } else {
      json[r'assignedVehicleId'] = null;
    }
    return json;
  }

  /// Returns a new [VehicleDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static VehicleDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return VehicleDto(
        id: mapValueOfType<int>(json, r'id'),
        licensePlate: mapValueOfType<String>(json, r'licensePlate'),
        model: mapValueOfType<String>(json, r'model'),
        manufacturer: mapValueOfType<String>(json, r'manufacturer'),
        type: VehicleDtoTypeEnum.fromJson(json[r'type']),
        status: VehicleDtoStatusEnum.fromJson(json[r'status']),
        mileage: num.parse('${json[r'mileage']}'),
        fuelConsumption: num.parse('${json[r'fuelConsumption']}'),
        lastInspectionDate: mapDateTime(json, r'lastInspectionDate', r''),
        lastServiceDate: mapDateTime(json, r'lastServiceDate', r''),
        nextServiceDue: mapDateTime(json, r'nextServiceDue', r''),
        year: mapValueOfType<int>(json, r'year'),
        truckSize: VehicleDtoTruckSizeEnum.fromJson(json[r'truckSize']),
        qtyPalletsCapacity: mapValueOfType<int>(json, r'qtyPalletsCapacity'),
        assignedZone: mapValueOfType<String>(json, r'assignedZone'),
        availableRoutes: mapValueOfType<String>(json, r'availableRoutes'),
        unavailableRoutes: mapValueOfType<String>(json, r'unavailableRoutes'),
        gpsDeviceId: mapValueOfType<String>(json, r'gpsDeviceId'),
        remarks: mapValueOfType<String>(json, r'remarks'),
        assignedDriver: DriverSimpleDto.fromJson(json[r'assignedDriver']),
        assignedVehicleId: mapValueOfType<int>(json, r'assignedVehicleId'),
      );
    }
    return null;
  }

  static List<VehicleDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VehicleDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VehicleDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, VehicleDto> mapFromJson(dynamic json) {
    final map = <String, VehicleDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = VehicleDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of VehicleDto-objects as value to a dart map
  static Map<String, List<VehicleDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<VehicleDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = VehicleDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class VehicleDtoTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const VehicleDtoTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BIG_TRUCK = VehicleDtoTypeEnum._(r'BIG_TRUCK');
  static const TRUCK = VehicleDtoTypeEnum._(r'TRUCK');
  static const TRAILER = VehicleDtoTypeEnum._(r'TRAILER');
  static const SMALL_VAN = VehicleDtoTypeEnum._(r'SMALL_VAN');
  static const VAN = VehicleDtoTypeEnum._(r'VAN');
  static const SUV = VehicleDtoTypeEnum._(r'SUV');
  static const CAR = VehicleDtoTypeEnum._(r'CAR');
  static const BUS = VehicleDtoTypeEnum._(r'BUS');
  static const MOTORBIKE = VehicleDtoTypeEnum._(r'MOTORBIKE');
  static const ELECTRIC = VehicleDtoTypeEnum._(r'ELECTRIC');
  static const OTHER = VehicleDtoTypeEnum._(r'OTHER');
  static const UNKNOWN = VehicleDtoTypeEnum._(r'UNKNOWN');

  /// List of all possible values in this [enum][VehicleDtoTypeEnum].
  static const values = <VehicleDtoTypeEnum>[
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

  static VehicleDtoTypeEnum? fromJson(dynamic value) => VehicleDtoTypeEnumTypeTransformer().decode(value);

  static List<VehicleDtoTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VehicleDtoTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VehicleDtoTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [VehicleDtoTypeEnum] to String,
/// and [decode] dynamic data back to [VehicleDtoTypeEnum].
class VehicleDtoTypeEnumTypeTransformer {
  factory VehicleDtoTypeEnumTypeTransformer() => _instance ??= const VehicleDtoTypeEnumTypeTransformer._();

  const VehicleDtoTypeEnumTypeTransformer._();

  String encode(VehicleDtoTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a VehicleDtoTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  VehicleDtoTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BIG_TRUCK': return VehicleDtoTypeEnum.BIG_TRUCK;
        case r'TRUCK': return VehicleDtoTypeEnum.TRUCK;
        case r'TRAILER': return VehicleDtoTypeEnum.TRAILER;
        case r'SMALL_VAN': return VehicleDtoTypeEnum.SMALL_VAN;
        case r'VAN': return VehicleDtoTypeEnum.VAN;
        case r'SUV': return VehicleDtoTypeEnum.SUV;
        case r'CAR': return VehicleDtoTypeEnum.CAR;
        case r'BUS': return VehicleDtoTypeEnum.BUS;
        case r'MOTORBIKE': return VehicleDtoTypeEnum.MOTORBIKE;
        case r'ELECTRIC': return VehicleDtoTypeEnum.ELECTRIC;
        case r'OTHER': return VehicleDtoTypeEnum.OTHER;
        case r'UNKNOWN': return VehicleDtoTypeEnum.UNKNOWN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [VehicleDtoTypeEnumTypeTransformer] instance.
  static VehicleDtoTypeEnumTypeTransformer? _instance;
}



class VehicleDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const VehicleDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const AVAILABLE = VehicleDtoStatusEnum._(r'AVAILABLE');
  static const IN_USE = VehicleDtoStatusEnum._(r'IN_USE');
  static const MAINTENANCE = VehicleDtoStatusEnum._(r'MAINTENANCE');
  static const OUT_OF_SERVICE = VehicleDtoStatusEnum._(r'OUT_OF_SERVICE');

  /// List of all possible values in this [enum][VehicleDtoStatusEnum].
  static const values = <VehicleDtoStatusEnum>[
    AVAILABLE,
    IN_USE,
    MAINTENANCE,
    OUT_OF_SERVICE,
  ];

  static VehicleDtoStatusEnum? fromJson(dynamic value) => VehicleDtoStatusEnumTypeTransformer().decode(value);

  static List<VehicleDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VehicleDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VehicleDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [VehicleDtoStatusEnum] to String,
/// and [decode] dynamic data back to [VehicleDtoStatusEnum].
class VehicleDtoStatusEnumTypeTransformer {
  factory VehicleDtoStatusEnumTypeTransformer() => _instance ??= const VehicleDtoStatusEnumTypeTransformer._();

  const VehicleDtoStatusEnumTypeTransformer._();

  String encode(VehicleDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a VehicleDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  VehicleDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'AVAILABLE': return VehicleDtoStatusEnum.AVAILABLE;
        case r'IN_USE': return VehicleDtoStatusEnum.IN_USE;
        case r'MAINTENANCE': return VehicleDtoStatusEnum.MAINTENANCE;
        case r'OUT_OF_SERVICE': return VehicleDtoStatusEnum.OUT_OF_SERVICE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [VehicleDtoStatusEnumTypeTransformer] instance.
  static VehicleDtoStatusEnumTypeTransformer? _instance;
}



class VehicleDtoTruckSizeEnum {
  /// Instantiate a new enum with the provided [value].
  const VehicleDtoTruckSizeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const SMALL_VAN = VehicleDtoTruckSizeEnum._(r'SMALL_VAN');
  static const MEDIUM_TRUCK = VehicleDtoTruckSizeEnum._(r'MEDIUM_TRUCK');
  static const BIG_TRUCK = VehicleDtoTruckSizeEnum._(r'BIG_TRUCK');

  /// List of all possible values in this [enum][VehicleDtoTruckSizeEnum].
  static const values = <VehicleDtoTruckSizeEnum>[
    SMALL_VAN,
    MEDIUM_TRUCK,
    BIG_TRUCK,
  ];

  static VehicleDtoTruckSizeEnum? fromJson(dynamic value) => VehicleDtoTruckSizeEnumTypeTransformer().decode(value);

  static List<VehicleDtoTruckSizeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VehicleDtoTruckSizeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VehicleDtoTruckSizeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [VehicleDtoTruckSizeEnum] to String,
/// and [decode] dynamic data back to [VehicleDtoTruckSizeEnum].
class VehicleDtoTruckSizeEnumTypeTransformer {
  factory VehicleDtoTruckSizeEnumTypeTransformer() => _instance ??= const VehicleDtoTruckSizeEnumTypeTransformer._();

  const VehicleDtoTruckSizeEnumTypeTransformer._();

  String encode(VehicleDtoTruckSizeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a VehicleDtoTruckSizeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  VehicleDtoTruckSizeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'SMALL_VAN': return VehicleDtoTruckSizeEnum.SMALL_VAN;
        case r'MEDIUM_TRUCK': return VehicleDtoTruckSizeEnum.MEDIUM_TRUCK;
        case r'BIG_TRUCK': return VehicleDtoTruckSizeEnum.BIG_TRUCK;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [VehicleDtoTruckSizeEnumTypeTransformer] instance.
  static VehicleDtoTruckSizeEnumTypeTransformer? _instance;
}


