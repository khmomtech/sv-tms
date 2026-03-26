//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MaintenanceTaskDto {
  /// Returns a new [MaintenanceTaskDto] instance.
  MaintenanceTaskDto({
    this.id,
    this.title,
    this.description,
    this.dueDate,
    this.completedAt,
    this.status,
    this.taskTypeId,
    this.taskTypeName,
    this.vehicleId,
    this.vehicleName,
    this.createdBy,
    this.createdByUsername,
    this.createdDate,
    this.updatedDate,
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
  String? title;

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
  DateTime? dueDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? completedAt;

  MaintenanceTaskDtoStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? taskTypeId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? taskTypeName;

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
  String? vehicleName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? createdBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? createdByUsername;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? updatedDate;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MaintenanceTaskDto &&
    other.id == id &&
    other.title == title &&
    other.description == description &&
    other.dueDate == dueDate &&
    other.completedAt == completedAt &&
    other.status == status &&
    other.taskTypeId == taskTypeId &&
    other.taskTypeName == taskTypeName &&
    other.vehicleId == vehicleId &&
    other.vehicleName == vehicleName &&
    other.createdBy == createdBy &&
    other.createdByUsername == createdByUsername &&
    other.createdDate == createdDate &&
    other.updatedDate == updatedDate;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (title == null ? 0 : title!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (dueDate == null ? 0 : dueDate!.hashCode) +
    (completedAt == null ? 0 : completedAt!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (taskTypeId == null ? 0 : taskTypeId!.hashCode) +
    (taskTypeName == null ? 0 : taskTypeName!.hashCode) +
    (vehicleId == null ? 0 : vehicleId!.hashCode) +
    (vehicleName == null ? 0 : vehicleName!.hashCode) +
    (createdBy == null ? 0 : createdBy!.hashCode) +
    (createdByUsername == null ? 0 : createdByUsername!.hashCode) +
    (createdDate == null ? 0 : createdDate!.hashCode) +
    (updatedDate == null ? 0 : updatedDate!.hashCode);

  @override
  String toString() => 'MaintenanceTaskDto[id=$id, title=$title, description=$description, dueDate=$dueDate, completedAt=$completedAt, status=$status, taskTypeId=$taskTypeId, taskTypeName=$taskTypeName, vehicleId=$vehicleId, vehicleName=$vehicleName, createdBy=$createdBy, createdByUsername=$createdByUsername, createdDate=$createdDate, updatedDate=$updatedDate]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.dueDate != null) {
      json[r'dueDate'] = this.dueDate!.toUtc().toIso8601String();
    } else {
      json[r'dueDate'] = null;
    }
    if (this.completedAt != null) {
      json[r'completedAt'] = this.completedAt!.toUtc().toIso8601String();
    } else {
      json[r'completedAt'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.taskTypeId != null) {
      json[r'taskTypeId'] = this.taskTypeId;
    } else {
      json[r'taskTypeId'] = null;
    }
    if (this.taskTypeName != null) {
      json[r'taskTypeName'] = this.taskTypeName;
    } else {
      json[r'taskTypeName'] = null;
    }
    if (this.vehicleId != null) {
      json[r'vehicleId'] = this.vehicleId;
    } else {
      json[r'vehicleId'] = null;
    }
    if (this.vehicleName != null) {
      json[r'vehicleName'] = this.vehicleName;
    } else {
      json[r'vehicleName'] = null;
    }
    if (this.createdBy != null) {
      json[r'createdBy'] = this.createdBy;
    } else {
      json[r'createdBy'] = null;
    }
    if (this.createdByUsername != null) {
      json[r'createdByUsername'] = this.createdByUsername;
    } else {
      json[r'createdByUsername'] = null;
    }
    if (this.createdDate != null) {
      json[r'createdDate'] = this.createdDate!.toUtc().toIso8601String();
    } else {
      json[r'createdDate'] = null;
    }
    if (this.updatedDate != null) {
      json[r'updatedDate'] = this.updatedDate!.toUtc().toIso8601String();
    } else {
      json[r'updatedDate'] = null;
    }
    return json;
  }

  /// Returns a new [MaintenanceTaskDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MaintenanceTaskDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return MaintenanceTaskDto(
        id: mapValueOfType<int>(json, r'id'),
        title: mapValueOfType<String>(json, r'title'),
        description: mapValueOfType<String>(json, r'description'),
        dueDate: mapDateTime(json, r'dueDate', r''),
        completedAt: mapDateTime(json, r'completedAt', r''),
        status: MaintenanceTaskDtoStatusEnum.fromJson(json[r'status']),
        taskTypeId: mapValueOfType<int>(json, r'taskTypeId'),
        taskTypeName: mapValueOfType<String>(json, r'taskTypeName'),
        vehicleId: mapValueOfType<int>(json, r'vehicleId'),
        vehicleName: mapValueOfType<String>(json, r'vehicleName'),
        createdBy: mapValueOfType<int>(json, r'createdBy'),
        createdByUsername: mapValueOfType<String>(json, r'createdByUsername'),
        createdDate: mapDateTime(json, r'createdDate', r''),
        updatedDate: mapDateTime(json, r'updatedDate', r''),
      );
    }
    return null;
  }

  static List<MaintenanceTaskDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MaintenanceTaskDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MaintenanceTaskDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MaintenanceTaskDto> mapFromJson(dynamic json) {
    final map = <String, MaintenanceTaskDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MaintenanceTaskDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MaintenanceTaskDto-objects as value to a dart map
  static Map<String, List<MaintenanceTaskDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MaintenanceTaskDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MaintenanceTaskDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class MaintenanceTaskDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const MaintenanceTaskDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = MaintenanceTaskDtoStatusEnum._(r'PENDING');
  static const IN_PROGRESS = MaintenanceTaskDtoStatusEnum._(r'IN_PROGRESS');
  static const COMPLETED = MaintenanceTaskDtoStatusEnum._(r'COMPLETED');
  static const CANCELLED = MaintenanceTaskDtoStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][MaintenanceTaskDtoStatusEnum].
  static const values = <MaintenanceTaskDtoStatusEnum>[
    PENDING,
    IN_PROGRESS,
    COMPLETED,
    CANCELLED,
  ];

  static MaintenanceTaskDtoStatusEnum? fromJson(dynamic value) => MaintenanceTaskDtoStatusEnumTypeTransformer().decode(value);

  static List<MaintenanceTaskDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MaintenanceTaskDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MaintenanceTaskDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [MaintenanceTaskDtoStatusEnum] to String,
/// and [decode] dynamic data back to [MaintenanceTaskDtoStatusEnum].
class MaintenanceTaskDtoStatusEnumTypeTransformer {
  factory MaintenanceTaskDtoStatusEnumTypeTransformer() => _instance ??= const MaintenanceTaskDtoStatusEnumTypeTransformer._();

  const MaintenanceTaskDtoStatusEnumTypeTransformer._();

  String encode(MaintenanceTaskDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a MaintenanceTaskDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  MaintenanceTaskDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return MaintenanceTaskDtoStatusEnum.PENDING;
        case r'IN_PROGRESS': return MaintenanceTaskDtoStatusEnum.IN_PROGRESS;
        case r'COMPLETED': return MaintenanceTaskDtoStatusEnum.COMPLETED;
        case r'CANCELLED': return MaintenanceTaskDtoStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [MaintenanceTaskDtoStatusEnumTypeTransformer] instance.
  static MaintenanceTaskDtoStatusEnumTypeTransformer? _instance;
}


