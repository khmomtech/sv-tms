//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkOrderTaskDto {
  /// Returns a new [WorkOrderTaskDto] instance.
  WorkOrderTaskDto({
    this.id,
    required this.workOrderId,
    required this.taskName,
    this.description,
    this.status,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.estimatedHours,
    this.actualHours,
    this.completedAt,
    this.notes,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  int workOrderId;

  String taskName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  WorkOrderTaskDtoStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? assignedTechnicianId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? assignedTechnicianName;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? estimatedHours;

  /// Minimum value: 0
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? actualHours;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? completedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkOrderTaskDto &&
    other.id == id &&
    other.workOrderId == workOrderId &&
    other.taskName == taskName &&
    other.description == description &&
    other.status == status &&
    other.assignedTechnicianId == assignedTechnicianId &&
    other.assignedTechnicianName == assignedTechnicianName &&
    other.estimatedHours == estimatedHours &&
    other.actualHours == actualHours &&
    other.completedAt == completedAt &&
    other.notes == notes;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (workOrderId.hashCode) +
    (taskName.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (assignedTechnicianId == null ? 0 : assignedTechnicianId!.hashCode) +
    (assignedTechnicianName == null ? 0 : assignedTechnicianName!.hashCode) +
    (estimatedHours == null ? 0 : estimatedHours!.hashCode) +
    (actualHours == null ? 0 : actualHours!.hashCode) +
    (completedAt == null ? 0 : completedAt!.hashCode) +
    (notes == null ? 0 : notes!.hashCode);

  @override
  String toString() => 'WorkOrderTaskDto[id=$id, workOrderId=$workOrderId, taskName=$taskName, description=$description, status=$status, assignedTechnicianId=$assignedTechnicianId, assignedTechnicianName=$assignedTechnicianName, estimatedHours=$estimatedHours, actualHours=$actualHours, completedAt=$completedAt, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'workOrderId'] = this.workOrderId;
      json[r'taskName'] = this.taskName;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.assignedTechnicianId != null) {
      json[r'assignedTechnicianId'] = this.assignedTechnicianId;
    } else {
      json[r'assignedTechnicianId'] = null;
    }
    if (this.assignedTechnicianName != null) {
      json[r'assignedTechnicianName'] = this.assignedTechnicianName;
    } else {
      json[r'assignedTechnicianName'] = null;
    }
    if (this.estimatedHours != null) {
      json[r'estimatedHours'] = this.estimatedHours;
    } else {
      json[r'estimatedHours'] = null;
    }
    if (this.actualHours != null) {
      json[r'actualHours'] = this.actualHours;
    } else {
      json[r'actualHours'] = null;
    }
    if (this.completedAt != null) {
      json[r'completedAt'] = this.completedAt!.toUtc().toIso8601String();
    } else {
      json[r'completedAt'] = null;
    }
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    return json;
  }

  /// Returns a new [WorkOrderTaskDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkOrderTaskDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'workOrderId'), 'Required key "WorkOrderTaskDto[workOrderId]" is missing from JSON.');
        assert(json[r'workOrderId'] != null, 'Required key "WorkOrderTaskDto[workOrderId]" has a null value in JSON.');
        assert(json.containsKey(r'taskName'), 'Required key "WorkOrderTaskDto[taskName]" is missing from JSON.');
        assert(json[r'taskName'] != null, 'Required key "WorkOrderTaskDto[taskName]" has a null value in JSON.');
        return true;
      }());

      return WorkOrderTaskDto(
        id: mapValueOfType<int>(json, r'id'),
        workOrderId: mapValueOfType<int>(json, r'workOrderId')!,
        taskName: mapValueOfType<String>(json, r'taskName')!,
        description: mapValueOfType<String>(json, r'description'),
        status: WorkOrderTaskDtoStatusEnum.fromJson(json[r'status']),
        assignedTechnicianId: mapValueOfType<int>(json, r'assignedTechnicianId'),
        assignedTechnicianName: mapValueOfType<String>(json, r'assignedTechnicianName'),
        estimatedHours: mapValueOfType<double>(json, r'estimatedHours'),
        actualHours: mapValueOfType<double>(json, r'actualHours'),
        completedAt: mapDateTime(json, r'completedAt', r''),
        notes: mapValueOfType<String>(json, r'notes'),
      );
    }
    return null;
  }

  static List<WorkOrderTaskDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkOrderTaskDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkOrderTaskDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkOrderTaskDto> mapFromJson(dynamic json) {
    final map = <String, WorkOrderTaskDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkOrderTaskDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkOrderTaskDto-objects as value to a dart map
  static Map<String, List<WorkOrderTaskDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkOrderTaskDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkOrderTaskDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'workOrderId',
    'taskName',
  };
}


class WorkOrderTaskDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const WorkOrderTaskDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const OPEN = WorkOrderTaskDtoStatusEnum._(r'OPEN');
  static const IN_PROGRESS = WorkOrderTaskDtoStatusEnum._(r'IN_PROGRESS');
  static const COMPLETED = WorkOrderTaskDtoStatusEnum._(r'COMPLETED');
  static const CANCELLED = WorkOrderTaskDtoStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][WorkOrderTaskDtoStatusEnum].
  static const values = <WorkOrderTaskDtoStatusEnum>[
    OPEN,
    IN_PROGRESS,
    COMPLETED,
    CANCELLED,
  ];

  static WorkOrderTaskDtoStatusEnum? fromJson(dynamic value) => WorkOrderTaskDtoStatusEnumTypeTransformer().decode(value);

  static List<WorkOrderTaskDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkOrderTaskDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkOrderTaskDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WorkOrderTaskDtoStatusEnum] to String,
/// and [decode] dynamic data back to [WorkOrderTaskDtoStatusEnum].
class WorkOrderTaskDtoStatusEnumTypeTransformer {
  factory WorkOrderTaskDtoStatusEnumTypeTransformer() => _instance ??= const WorkOrderTaskDtoStatusEnumTypeTransformer._();

  const WorkOrderTaskDtoStatusEnumTypeTransformer._();

  String encode(WorkOrderTaskDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a WorkOrderTaskDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WorkOrderTaskDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'OPEN': return WorkOrderTaskDtoStatusEnum.OPEN;
        case r'IN_PROGRESS': return WorkOrderTaskDtoStatusEnum.IN_PROGRESS;
        case r'COMPLETED': return WorkOrderTaskDtoStatusEnum.COMPLETED;
        case r'CANCELLED': return WorkOrderTaskDtoStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WorkOrderTaskDtoStatusEnumTypeTransformer] instance.
  static WorkOrderTaskDtoStatusEnumTypeTransformer? _instance;
}


