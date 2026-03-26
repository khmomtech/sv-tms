//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PMScheduleDto {
  /// Returns a new [PMScheduleDto] instance.
  PMScheduleDto({
    this.id,
    required this.pmName,
    this.description,
    this.vehicleId,
    this.vehiclePlate,
    this.vehicleType,
    required this.triggerType,
    this.intervalKm,
    this.intervalDays,
    this.intervalEngineHours,
    this.nextDueKm,
    this.nextDueDate,
    this.nextDueEngineHours,
    this.lastPerformedKm,
    this.lastPerformedDate,
    this.lastPerformedEngineHours,
    this.active,
    this.maintenanceTaskTypeId,
    this.maintenanceTaskTypeName,
    this.createdById,
    this.createdByName,
    this.isDueNow,
    this.isDueSoon,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  String pmName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? vehicleId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? vehiclePlate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? vehicleType;

  PMScheduleDtoTriggerTypeEnum triggerType;

  /// Minimum value: 1
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? intervalKm;

  /// Minimum value: 1
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? intervalDays;

  /// Minimum value: 1
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? intervalEngineHours;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? nextDueKm;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? nextDueDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? nextDueEngineHours;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? lastPerformedKm;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastPerformedDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? lastPerformedEngineHours;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? active;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? maintenanceTaskTypeId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? maintenanceTaskTypeName;

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
  String? createdByName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isDueNow;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isDueSoon;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PMScheduleDto &&
    other.id == id &&
    other.pmName == pmName &&
    other.description == description &&
    other.vehicleId == vehicleId &&
    other.vehiclePlate == vehiclePlate &&
    other.vehicleType == vehicleType &&
    other.triggerType == triggerType &&
    other.intervalKm == intervalKm &&
    other.intervalDays == intervalDays &&
    other.intervalEngineHours == intervalEngineHours &&
    other.nextDueKm == nextDueKm &&
    other.nextDueDate == nextDueDate &&
    other.nextDueEngineHours == nextDueEngineHours &&
    other.lastPerformedKm == lastPerformedKm &&
    other.lastPerformedDate == lastPerformedDate &&
    other.lastPerformedEngineHours == lastPerformedEngineHours &&
    other.active == active &&
    other.maintenanceTaskTypeId == maintenanceTaskTypeId &&
    other.maintenanceTaskTypeName == maintenanceTaskTypeName &&
    other.createdById == createdById &&
    other.createdByName == createdByName &&
    other.isDueNow == isDueNow &&
    other.isDueSoon == isDueSoon;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (pmName.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (vehicleId == null ? 0 : vehicleId!.hashCode) +
    (vehiclePlate == null ? 0 : vehiclePlate!.hashCode) +
    (vehicleType == null ? 0 : vehicleType!.hashCode) +
    (triggerType.hashCode) +
    (intervalKm == null ? 0 : intervalKm!.hashCode) +
    (intervalDays == null ? 0 : intervalDays!.hashCode) +
    (intervalEngineHours == null ? 0 : intervalEngineHours!.hashCode) +
    (nextDueKm == null ? 0 : nextDueKm!.hashCode) +
    (nextDueDate == null ? 0 : nextDueDate!.hashCode) +
    (nextDueEngineHours == null ? 0 : nextDueEngineHours!.hashCode) +
    (lastPerformedKm == null ? 0 : lastPerformedKm!.hashCode) +
    (lastPerformedDate == null ? 0 : lastPerformedDate!.hashCode) +
    (lastPerformedEngineHours == null ? 0 : lastPerformedEngineHours!.hashCode) +
    (active == null ? 0 : active!.hashCode) +
    (maintenanceTaskTypeId == null ? 0 : maintenanceTaskTypeId!.hashCode) +
    (maintenanceTaskTypeName == null ? 0 : maintenanceTaskTypeName!.hashCode) +
    (createdById == null ? 0 : createdById!.hashCode) +
    (createdByName == null ? 0 : createdByName!.hashCode) +
    (isDueNow == null ? 0 : isDueNow!.hashCode) +
    (isDueSoon == null ? 0 : isDueSoon!.hashCode);

  @override
  String toString() => 'PMScheduleDto[id=$id, pmName=$pmName, description=$description, vehicleId=$vehicleId, vehiclePlate=$vehiclePlate, vehicleType=$vehicleType, triggerType=$triggerType, intervalKm=$intervalKm, intervalDays=$intervalDays, intervalEngineHours=$intervalEngineHours, nextDueKm=$nextDueKm, nextDueDate=$nextDueDate, nextDueEngineHours=$nextDueEngineHours, lastPerformedKm=$lastPerformedKm, lastPerformedDate=$lastPerformedDate, lastPerformedEngineHours=$lastPerformedEngineHours, active=$active, maintenanceTaskTypeId=$maintenanceTaskTypeId, maintenanceTaskTypeName=$maintenanceTaskTypeName, createdById=$createdById, createdByName=$createdByName, isDueNow=$isDueNow, isDueSoon=$isDueSoon]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'pmName'] = this.pmName;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.vehicleId != null) {
      json[r'vehicleId'] = this.vehicleId;
    } else {
      json[r'vehicleId'] = null;
    }
    if (this.vehiclePlate != null) {
      json[r'vehiclePlate'] = this.vehiclePlate;
    } else {
      json[r'vehiclePlate'] = null;
    }
    if (this.vehicleType != null) {
      json[r'vehicleType'] = this.vehicleType;
    } else {
      json[r'vehicleType'] = null;
    }
      json[r'triggerType'] = this.triggerType;
    if (this.intervalKm != null) {
      json[r'intervalKm'] = this.intervalKm;
    } else {
      json[r'intervalKm'] = null;
    }
    if (this.intervalDays != null) {
      json[r'intervalDays'] = this.intervalDays;
    } else {
      json[r'intervalDays'] = null;
    }
    if (this.intervalEngineHours != null) {
      json[r'intervalEngineHours'] = this.intervalEngineHours;
    } else {
      json[r'intervalEngineHours'] = null;
    }
    if (this.nextDueKm != null) {
      json[r'nextDueKm'] = this.nextDueKm;
    } else {
      json[r'nextDueKm'] = null;
    }
    if (this.nextDueDate != null) {
      json[r'nextDueDate'] = _dateFormatter.format(this.nextDueDate!.toUtc());
    } else {
      json[r'nextDueDate'] = null;
    }
    if (this.nextDueEngineHours != null) {
      json[r'nextDueEngineHours'] = this.nextDueEngineHours;
    } else {
      json[r'nextDueEngineHours'] = null;
    }
    if (this.lastPerformedKm != null) {
      json[r'lastPerformedKm'] = this.lastPerformedKm;
    } else {
      json[r'lastPerformedKm'] = null;
    }
    if (this.lastPerformedDate != null) {
      json[r'lastPerformedDate'] = _dateFormatter.format(this.lastPerformedDate!.toUtc());
    } else {
      json[r'lastPerformedDate'] = null;
    }
    if (this.lastPerformedEngineHours != null) {
      json[r'lastPerformedEngineHours'] = this.lastPerformedEngineHours;
    } else {
      json[r'lastPerformedEngineHours'] = null;
    }
    if (this.active != null) {
      json[r'active'] = this.active;
    } else {
      json[r'active'] = null;
    }
    if (this.maintenanceTaskTypeId != null) {
      json[r'maintenanceTaskTypeId'] = this.maintenanceTaskTypeId;
    } else {
      json[r'maintenanceTaskTypeId'] = null;
    }
    if (this.maintenanceTaskTypeName != null) {
      json[r'maintenanceTaskTypeName'] = this.maintenanceTaskTypeName;
    } else {
      json[r'maintenanceTaskTypeName'] = null;
    }
    if (this.createdById != null) {
      json[r'createdById'] = this.createdById;
    } else {
      json[r'createdById'] = null;
    }
    if (this.createdByName != null) {
      json[r'createdByName'] = this.createdByName;
    } else {
      json[r'createdByName'] = null;
    }
    if (this.isDueNow != null) {
      json[r'isDueNow'] = this.isDueNow;
    } else {
      json[r'isDueNow'] = null;
    }
    if (this.isDueSoon != null) {
      json[r'isDueSoon'] = this.isDueSoon;
    } else {
      json[r'isDueSoon'] = null;
    }
    return json;
  }

  /// Returns a new [PMScheduleDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PMScheduleDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'pmName'), 'Required key "PMScheduleDto[pmName]" is missing from JSON.');
        assert(json[r'pmName'] != null, 'Required key "PMScheduleDto[pmName]" has a null value in JSON.');
        assert(json.containsKey(r'triggerType'), 'Required key "PMScheduleDto[triggerType]" is missing from JSON.');
        assert(json[r'triggerType'] != null, 'Required key "PMScheduleDto[triggerType]" has a null value in JSON.');
        return true;
      }());

      return PMScheduleDto(
        id: mapValueOfType<int>(json, r'id'),
        pmName: mapValueOfType<String>(json, r'pmName')!,
        description: mapValueOfType<String>(json, r'description'),
        vehicleId: mapValueOfType<int>(json, r'vehicleId'),
        vehiclePlate: mapValueOfType<String>(json, r'vehiclePlate'),
        vehicleType: mapValueOfType<String>(json, r'vehicleType'),
        triggerType: PMScheduleDtoTriggerTypeEnum.fromJson(json[r'triggerType'])!,
        intervalKm: mapValueOfType<int>(json, r'intervalKm'),
        intervalDays: mapValueOfType<int>(json, r'intervalDays'),
        intervalEngineHours: mapValueOfType<int>(json, r'intervalEngineHours'),
        nextDueKm: mapValueOfType<int>(json, r'nextDueKm'),
        nextDueDate: mapDateTime(json, r'nextDueDate', r''),
        nextDueEngineHours: mapValueOfType<int>(json, r'nextDueEngineHours'),
        lastPerformedKm: mapValueOfType<int>(json, r'lastPerformedKm'),
        lastPerformedDate: mapDateTime(json, r'lastPerformedDate', r''),
        lastPerformedEngineHours: mapValueOfType<int>(json, r'lastPerformedEngineHours'),
        active: mapValueOfType<bool>(json, r'active'),
        maintenanceTaskTypeId: mapValueOfType<int>(json, r'maintenanceTaskTypeId'),
        maintenanceTaskTypeName: mapValueOfType<String>(json, r'maintenanceTaskTypeName'),
        createdById: mapValueOfType<int>(json, r'createdById'),
        createdByName: mapValueOfType<String>(json, r'createdByName'),
        isDueNow: mapValueOfType<bool>(json, r'isDueNow'),
        isDueSoon: mapValueOfType<bool>(json, r'isDueSoon'),
      );
    }
    return null;
  }

  static List<PMScheduleDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PMScheduleDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PMScheduleDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PMScheduleDto> mapFromJson(dynamic json) {
    final map = <String, PMScheduleDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PMScheduleDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PMScheduleDto-objects as value to a dart map
  static Map<String, List<PMScheduleDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PMScheduleDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PMScheduleDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'pmName',
    'triggerType',
  };
}


class PMScheduleDtoTriggerTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const PMScheduleDtoTriggerTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const KILOMETER = PMScheduleDtoTriggerTypeEnum._(r'KILOMETER');
  static const DATE = PMScheduleDtoTriggerTypeEnum._(r'DATE');
  static const ENGINE_HOUR = PMScheduleDtoTriggerTypeEnum._(r'ENGINE_HOUR');

  /// List of all possible values in this [enum][PMScheduleDtoTriggerTypeEnum].
  static const values = <PMScheduleDtoTriggerTypeEnum>[
    KILOMETER,
    DATE,
    ENGINE_HOUR,
  ];

  static PMScheduleDtoTriggerTypeEnum? fromJson(dynamic value) => PMScheduleDtoTriggerTypeEnumTypeTransformer().decode(value);

  static List<PMScheduleDtoTriggerTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PMScheduleDtoTriggerTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PMScheduleDtoTriggerTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PMScheduleDtoTriggerTypeEnum] to String,
/// and [decode] dynamic data back to [PMScheduleDtoTriggerTypeEnum].
class PMScheduleDtoTriggerTypeEnumTypeTransformer {
  factory PMScheduleDtoTriggerTypeEnumTypeTransformer() => _instance ??= const PMScheduleDtoTriggerTypeEnumTypeTransformer._();

  const PMScheduleDtoTriggerTypeEnumTypeTransformer._();

  String encode(PMScheduleDtoTriggerTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PMScheduleDtoTriggerTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PMScheduleDtoTriggerTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'KILOMETER': return PMScheduleDtoTriggerTypeEnum.KILOMETER;
        case r'DATE': return PMScheduleDtoTriggerTypeEnum.DATE;
        case r'ENGINE_HOUR': return PMScheduleDtoTriggerTypeEnum.ENGINE_HOUR;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PMScheduleDtoTriggerTypeEnumTypeTransformer] instance.
  static PMScheduleDtoTriggerTypeEnumTypeTransformer? _instance;
}


