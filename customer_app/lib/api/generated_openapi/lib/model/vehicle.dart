//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Vehicle {
  /// Returns a new [Vehicle] instance.
  Vehicle({
    this.id,
    required this.licensePlate,
    this.fuelConsumption,
    this.lastInspectionDate,
    this.nextServiceDue,
    this.lastServiceDate,
    required this.manufacturer,
    this.year,
    required this.mileage,
    required this.model,
    required this.status,
    required this.type,
    this.truckSize,
    this.qtyPalletsCapacity,
    this.assignedZone,
    this.availableRoutes,
    this.unavailableRoutes,
    this.gpsDeviceId,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.currentAssignedDriver,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  String licensePlate;

  /// Minimum value: 0.0
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
  DateTime? nextServiceDue;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastServiceDate;

  String manufacturer;

  /// Minimum value: 1900
  /// Maximum value: 2100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? year;

  /// Minimum value: 0.0
  num mileage;

  String model;

  VehicleStatusEnum status;

  VehicleTypeEnum type;

  VehicleTruckSizeEnum? truckSize;

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
  DateTime? createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Driver? currentAssignedDriver;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Vehicle &&
    other.id == id &&
    other.licensePlate == licensePlate &&
    other.fuelConsumption == fuelConsumption &&
    other.lastInspectionDate == lastInspectionDate &&
    other.nextServiceDue == nextServiceDue &&
    other.lastServiceDate == lastServiceDate &&
    other.manufacturer == manufacturer &&
    other.year == year &&
    other.mileage == mileage &&
    other.model == model &&
    other.status == status &&
    other.type == type &&
    other.truckSize == truckSize &&
    other.qtyPalletsCapacity == qtyPalletsCapacity &&
    other.assignedZone == assignedZone &&
    other.availableRoutes == availableRoutes &&
    other.unavailableRoutes == unavailableRoutes &&
    other.gpsDeviceId == gpsDeviceId &&
    other.remarks == remarks &&
    other.createdAt == createdAt &&
    other.updatedAt == updatedAt &&
    other.currentAssignedDriver == currentAssignedDriver;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (licensePlate.hashCode) +
    (fuelConsumption == null ? 0 : fuelConsumption!.hashCode) +
    (lastInspectionDate == null ? 0 : lastInspectionDate!.hashCode) +
    (nextServiceDue == null ? 0 : nextServiceDue!.hashCode) +
    (lastServiceDate == null ? 0 : lastServiceDate!.hashCode) +
    (manufacturer.hashCode) +
    (year == null ? 0 : year!.hashCode) +
    (mileage.hashCode) +
    (model.hashCode) +
    (status.hashCode) +
    (type.hashCode) +
    (truckSize == null ? 0 : truckSize!.hashCode) +
    (qtyPalletsCapacity == null ? 0 : qtyPalletsCapacity!.hashCode) +
    (assignedZone == null ? 0 : assignedZone!.hashCode) +
    (availableRoutes == null ? 0 : availableRoutes!.hashCode) +
    (unavailableRoutes == null ? 0 : unavailableRoutes!.hashCode) +
    (gpsDeviceId == null ? 0 : gpsDeviceId!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (currentAssignedDriver == null ? 0 : currentAssignedDriver!.hashCode);

  @override
  String toString() => 'Vehicle[id=$id, licensePlate=$licensePlate, fuelConsumption=$fuelConsumption, lastInspectionDate=$lastInspectionDate, nextServiceDue=$nextServiceDue, lastServiceDate=$lastServiceDate, manufacturer=$manufacturer, year=$year, mileage=$mileage, model=$model, status=$status, type=$type, truckSize=$truckSize, qtyPalletsCapacity=$qtyPalletsCapacity, assignedZone=$assignedZone, availableRoutes=$availableRoutes, unavailableRoutes=$unavailableRoutes, gpsDeviceId=$gpsDeviceId, remarks=$remarks, createdAt=$createdAt, updatedAt=$updatedAt, currentAssignedDriver=$currentAssignedDriver]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'licensePlate'] = this.licensePlate;
    if (this.fuelConsumption != null) {
      json[r'fuelConsumption'] = this.fuelConsumption;
    } else {
      json[r'fuelConsumption'] = null;
    }
    if (this.lastInspectionDate != null) {
      json[r'lastInspectionDate'] = _dateFormatter.format(this.lastInspectionDate!.toUtc());
    } else {
      json[r'lastInspectionDate'] = null;
    }
    if (this.nextServiceDue != null) {
      json[r'nextServiceDue'] = _dateFormatter.format(this.nextServiceDue!.toUtc());
    } else {
      json[r'nextServiceDue'] = null;
    }
    if (this.lastServiceDate != null) {
      json[r'lastServiceDate'] = _dateFormatter.format(this.lastServiceDate!.toUtc());
    } else {
      json[r'lastServiceDate'] = null;
    }
      json[r'manufacturer'] = this.manufacturer;
    if (this.year != null) {
      json[r'year'] = this.year;
    } else {
      json[r'year'] = null;
    }
      json[r'mileage'] = this.mileage;
      json[r'model'] = this.model;
      json[r'status'] = this.status;
      json[r'type'] = this.type;
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
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updatedAt'] = null;
    }
    if (this.currentAssignedDriver != null) {
      json[r'currentAssignedDriver'] = this.currentAssignedDriver;
    } else {
      json[r'currentAssignedDriver'] = null;
    }
    return json;
  }

  /// Returns a new [Vehicle] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Vehicle? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'licensePlate'), 'Required key "Vehicle[licensePlate]" is missing from JSON.');
        assert(json[r'licensePlate'] != null, 'Required key "Vehicle[licensePlate]" has a null value in JSON.');
        assert(json.containsKey(r'manufacturer'), 'Required key "Vehicle[manufacturer]" is missing from JSON.');
        assert(json[r'manufacturer'] != null, 'Required key "Vehicle[manufacturer]" has a null value in JSON.');
        assert(json.containsKey(r'mileage'), 'Required key "Vehicle[mileage]" is missing from JSON.');
        assert(json[r'mileage'] != null, 'Required key "Vehicle[mileage]" has a null value in JSON.');
        assert(json.containsKey(r'model'), 'Required key "Vehicle[model]" is missing from JSON.');
        assert(json[r'model'] != null, 'Required key "Vehicle[model]" has a null value in JSON.');
        assert(json.containsKey(r'status'), 'Required key "Vehicle[status]" is missing from JSON.');
        assert(json[r'status'] != null, 'Required key "Vehicle[status]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "Vehicle[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "Vehicle[type]" has a null value in JSON.');
        return true;
      }());

      return Vehicle(
        id: mapValueOfType<int>(json, r'id'),
        licensePlate: mapValueOfType<String>(json, r'licensePlate')!,
        fuelConsumption: num.parse('${json[r'fuelConsumption']}'),
        lastInspectionDate: mapDateTime(json, r'lastInspectionDate', r''),
        nextServiceDue: mapDateTime(json, r'nextServiceDue', r''),
        lastServiceDate: mapDateTime(json, r'lastServiceDate', r''),
        manufacturer: mapValueOfType<String>(json, r'manufacturer')!,
        year: mapValueOfType<int>(json, r'year'),
        mileage: num.parse('${json[r'mileage']}'),
        model: mapValueOfType<String>(json, r'model')!,
        status: VehicleStatusEnum.fromJson(json[r'status'])!,
        type: VehicleTypeEnum.fromJson(json[r'type'])!,
        truckSize: VehicleTruckSizeEnum.fromJson(json[r'truckSize']),
        qtyPalletsCapacity: mapValueOfType<int>(json, r'qtyPalletsCapacity'),
        assignedZone: mapValueOfType<String>(json, r'assignedZone'),
        availableRoutes: mapValueOfType<String>(json, r'availableRoutes'),
        unavailableRoutes: mapValueOfType<String>(json, r'unavailableRoutes'),
        gpsDeviceId: mapValueOfType<String>(json, r'gpsDeviceId'),
        remarks: mapValueOfType<String>(json, r'remarks'),
        createdAt: mapDateTime(json, r'createdAt', r''),
        updatedAt: mapDateTime(json, r'updatedAt', r''),
        currentAssignedDriver: Driver.fromJson(json[r'currentAssignedDriver']),
      );
    }
    return null;
  }

  static List<Vehicle> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Vehicle>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Vehicle.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Vehicle> mapFromJson(dynamic json) {
    final map = <String, Vehicle>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Vehicle.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Vehicle-objects as value to a dart map
  static Map<String, List<Vehicle>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Vehicle>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Vehicle.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'licensePlate',
    'manufacturer',
    'mileage',
    'model',
    'status',
    'type',
  };
}


class VehicleStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const VehicleStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const AVAILABLE = VehicleStatusEnum._(r'AVAILABLE');
  static const IN_USE = VehicleStatusEnum._(r'IN_USE');
  static const MAINTENANCE = VehicleStatusEnum._(r'MAINTENANCE');
  static const OUT_OF_SERVICE = VehicleStatusEnum._(r'OUT_OF_SERVICE');

  /// List of all possible values in this [enum][VehicleStatusEnum].
  static const values = <VehicleStatusEnum>[
    AVAILABLE,
    IN_USE,
    MAINTENANCE,
    OUT_OF_SERVICE,
  ];

  static VehicleStatusEnum? fromJson(dynamic value) => VehicleStatusEnumTypeTransformer().decode(value);

  static List<VehicleStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VehicleStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VehicleStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [VehicleStatusEnum] to String,
/// and [decode] dynamic data back to [VehicleStatusEnum].
class VehicleStatusEnumTypeTransformer {
  factory VehicleStatusEnumTypeTransformer() => _instance ??= const VehicleStatusEnumTypeTransformer._();

  const VehicleStatusEnumTypeTransformer._();

  String encode(VehicleStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a VehicleStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  VehicleStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'AVAILABLE': return VehicleStatusEnum.AVAILABLE;
        case r'IN_USE': return VehicleStatusEnum.IN_USE;
        case r'MAINTENANCE': return VehicleStatusEnum.MAINTENANCE;
        case r'OUT_OF_SERVICE': return VehicleStatusEnum.OUT_OF_SERVICE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [VehicleStatusEnumTypeTransformer] instance.
  static VehicleStatusEnumTypeTransformer? _instance;
}



class VehicleTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const VehicleTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BIG_TRUCK = VehicleTypeEnum._(r'BIG_TRUCK');
  static const TRUCK = VehicleTypeEnum._(r'TRUCK');
  static const TRAILER = VehicleTypeEnum._(r'TRAILER');
  static const SMALL_VAN = VehicleTypeEnum._(r'SMALL_VAN');
  static const VAN = VehicleTypeEnum._(r'VAN');
  static const SUV = VehicleTypeEnum._(r'SUV');
  static const CAR = VehicleTypeEnum._(r'CAR');
  static const BUS = VehicleTypeEnum._(r'BUS');
  static const MOTORBIKE = VehicleTypeEnum._(r'MOTORBIKE');
  static const ELECTRIC = VehicleTypeEnum._(r'ELECTRIC');
  static const OTHER = VehicleTypeEnum._(r'OTHER');
  static const UNKNOWN = VehicleTypeEnum._(r'UNKNOWN');

  /// List of all possible values in this [enum][VehicleTypeEnum].
  static const values = <VehicleTypeEnum>[
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

  static VehicleTypeEnum? fromJson(dynamic value) => VehicleTypeEnumTypeTransformer().decode(value);

  static List<VehicleTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VehicleTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VehicleTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [VehicleTypeEnum] to String,
/// and [decode] dynamic data back to [VehicleTypeEnum].
class VehicleTypeEnumTypeTransformer {
  factory VehicleTypeEnumTypeTransformer() => _instance ??= const VehicleTypeEnumTypeTransformer._();

  const VehicleTypeEnumTypeTransformer._();

  String encode(VehicleTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a VehicleTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  VehicleTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BIG_TRUCK': return VehicleTypeEnum.BIG_TRUCK;
        case r'TRUCK': return VehicleTypeEnum.TRUCK;
        case r'TRAILER': return VehicleTypeEnum.TRAILER;
        case r'SMALL_VAN': return VehicleTypeEnum.SMALL_VAN;
        case r'VAN': return VehicleTypeEnum.VAN;
        case r'SUV': return VehicleTypeEnum.SUV;
        case r'CAR': return VehicleTypeEnum.CAR;
        case r'BUS': return VehicleTypeEnum.BUS;
        case r'MOTORBIKE': return VehicleTypeEnum.MOTORBIKE;
        case r'ELECTRIC': return VehicleTypeEnum.ELECTRIC;
        case r'OTHER': return VehicleTypeEnum.OTHER;
        case r'UNKNOWN': return VehicleTypeEnum.UNKNOWN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [VehicleTypeEnumTypeTransformer] instance.
  static VehicleTypeEnumTypeTransformer? _instance;
}



class VehicleTruckSizeEnum {
  /// Instantiate a new enum with the provided [value].
  const VehicleTruckSizeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const SMALL_VAN = VehicleTruckSizeEnum._(r'SMALL_VAN');
  static const MEDIUM_TRUCK = VehicleTruckSizeEnum._(r'MEDIUM_TRUCK');
  static const BIG_TRUCK = VehicleTruckSizeEnum._(r'BIG_TRUCK');

  /// List of all possible values in this [enum][VehicleTruckSizeEnum].
  static const values = <VehicleTruckSizeEnum>[
    SMALL_VAN,
    MEDIUM_TRUCK,
    BIG_TRUCK,
  ];

  static VehicleTruckSizeEnum? fromJson(dynamic value) => VehicleTruckSizeEnumTypeTransformer().decode(value);

  static List<VehicleTruckSizeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <VehicleTruckSizeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = VehicleTruckSizeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [VehicleTruckSizeEnum] to String,
/// and [decode] dynamic data back to [VehicleTruckSizeEnum].
class VehicleTruckSizeEnumTypeTransformer {
  factory VehicleTruckSizeEnumTypeTransformer() => _instance ??= const VehicleTruckSizeEnumTypeTransformer._();

  const VehicleTruckSizeEnumTypeTransformer._();

  String encode(VehicleTruckSizeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a VehicleTruckSizeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  VehicleTruckSizeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'SMALL_VAN': return VehicleTruckSizeEnum.SMALL_VAN;
        case r'MEDIUM_TRUCK': return VehicleTruckSizeEnum.MEDIUM_TRUCK;
        case r'BIG_TRUCK': return VehicleTruckSizeEnum.BIG_TRUCK;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [VehicleTruckSizeEnumTypeTransformer] instance.
  static VehicleTruckSizeEnumTypeTransformer? _instance;
}


