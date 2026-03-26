//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkOrderDto {
  /// Returns a new [WorkOrderDto] instance.
  WorkOrderDto({
    this.id,
    this.woNumber,
    required this.vehicleId,
    this.vehiclePlate,
    required this.type,
    required this.priority,
    this.status,
    required this.title,
    this.description,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.scheduledDate,
    this.completedAt,
    this.estimatedCost,
    this.actualCost,
    this.laborCost,
    this.partsCost,
    this.notes,
    this.requiresApproval,
    this.approved,
    this.approvedById,
    this.approvedByName,
    this.approvedAt,
    this.maintenanceTaskId,
    this.maintenanceTaskName,
    this.driverIssueId,
    this.pmScheduleId,
    this.tasks = const [],
    this.photos = const [],
    this.parts = const [],
    this.totalTasks,
    this.completedTasks,
    this.totalPartsCost,
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
  String? woNumber;

  int vehicleId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? vehiclePlate;

  WorkOrderDtoTypeEnum type;

  WorkOrderDtoPriorityEnum priority;

  WorkOrderDtoStatusEnum? status;

  String title;

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
  int? assignedTechnicianId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? assignedTechnicianName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? scheduledDate;

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
  double? estimatedCost;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? actualCost;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? laborCost;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? partsCost;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? notes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? requiresApproval;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? approved;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? approvedById;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? approvedByName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? approvedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? maintenanceTaskId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? maintenanceTaskName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? driverIssueId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? pmScheduleId;

  List<WorkOrderTaskDto> tasks;

  List<WorkOrderPhotoDto> photos;

  List<WorkOrderPartDto> parts;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? totalTasks;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? completedTasks;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? totalPartsCost;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkOrderDto &&
    other.id == id &&
    other.woNumber == woNumber &&
    other.vehicleId == vehicleId &&
    other.vehiclePlate == vehiclePlate &&
    other.type == type &&
    other.priority == priority &&
    other.status == status &&
    other.title == title &&
    other.description == description &&
    other.assignedTechnicianId == assignedTechnicianId &&
    other.assignedTechnicianName == assignedTechnicianName &&
    other.scheduledDate == scheduledDate &&
    other.completedAt == completedAt &&
    other.estimatedCost == estimatedCost &&
    other.actualCost == actualCost &&
    other.laborCost == laborCost &&
    other.partsCost == partsCost &&
    other.notes == notes &&
    other.requiresApproval == requiresApproval &&
    other.approved == approved &&
    other.approvedById == approvedById &&
    other.approvedByName == approvedByName &&
    other.approvedAt == approvedAt &&
    other.maintenanceTaskId == maintenanceTaskId &&
    other.maintenanceTaskName == maintenanceTaskName &&
    other.driverIssueId == driverIssueId &&
    other.pmScheduleId == pmScheduleId &&
    _deepEquality.equals(other.tasks, tasks) &&
    _deepEquality.equals(other.photos, photos) &&
    _deepEquality.equals(other.parts, parts) &&
    other.totalTasks == totalTasks &&
    other.completedTasks == completedTasks &&
    other.totalPartsCost == totalPartsCost;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (woNumber == null ? 0 : woNumber!.hashCode) +
    (vehicleId.hashCode) +
    (vehiclePlate == null ? 0 : vehiclePlate!.hashCode) +
    (type.hashCode) +
    (priority.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (title.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (assignedTechnicianId == null ? 0 : assignedTechnicianId!.hashCode) +
    (assignedTechnicianName == null ? 0 : assignedTechnicianName!.hashCode) +
    (scheduledDate == null ? 0 : scheduledDate!.hashCode) +
    (completedAt == null ? 0 : completedAt!.hashCode) +
    (estimatedCost == null ? 0 : estimatedCost!.hashCode) +
    (actualCost == null ? 0 : actualCost!.hashCode) +
    (laborCost == null ? 0 : laborCost!.hashCode) +
    (partsCost == null ? 0 : partsCost!.hashCode) +
    (notes == null ? 0 : notes!.hashCode) +
    (requiresApproval == null ? 0 : requiresApproval!.hashCode) +
    (approved == null ? 0 : approved!.hashCode) +
    (approvedById == null ? 0 : approvedById!.hashCode) +
    (approvedByName == null ? 0 : approvedByName!.hashCode) +
    (approvedAt == null ? 0 : approvedAt!.hashCode) +
    (maintenanceTaskId == null ? 0 : maintenanceTaskId!.hashCode) +
    (maintenanceTaskName == null ? 0 : maintenanceTaskName!.hashCode) +
    (driverIssueId == null ? 0 : driverIssueId!.hashCode) +
    (pmScheduleId == null ? 0 : pmScheduleId!.hashCode) +
    (tasks.hashCode) +
    (photos.hashCode) +
    (parts.hashCode) +
    (totalTasks == null ? 0 : totalTasks!.hashCode) +
    (completedTasks == null ? 0 : completedTasks!.hashCode) +
    (totalPartsCost == null ? 0 : totalPartsCost!.hashCode);

  @override
  String toString() => 'WorkOrderDto[id=$id, woNumber=$woNumber, vehicleId=$vehicleId, vehiclePlate=$vehiclePlate, type=$type, priority=$priority, status=$status, title=$title, description=$description, assignedTechnicianId=$assignedTechnicianId, assignedTechnicianName=$assignedTechnicianName, scheduledDate=$scheduledDate, completedAt=$completedAt, estimatedCost=$estimatedCost, actualCost=$actualCost, laborCost=$laborCost, partsCost=$partsCost, notes=$notes, requiresApproval=$requiresApproval, approved=$approved, approvedById=$approvedById, approvedByName=$approvedByName, approvedAt=$approvedAt, maintenanceTaskId=$maintenanceTaskId, maintenanceTaskName=$maintenanceTaskName, driverIssueId=$driverIssueId, pmScheduleId=$pmScheduleId, tasks=$tasks, photos=$photos, parts=$parts, totalTasks=$totalTasks, completedTasks=$completedTasks, totalPartsCost=$totalPartsCost]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.woNumber != null) {
      json[r'woNumber'] = this.woNumber;
    } else {
      json[r'woNumber'] = null;
    }
      json[r'vehicleId'] = this.vehicleId;
    if (this.vehiclePlate != null) {
      json[r'vehiclePlate'] = this.vehiclePlate;
    } else {
      json[r'vehiclePlate'] = null;
    }
      json[r'type'] = this.type;
      json[r'priority'] = this.priority;
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
      json[r'title'] = this.title;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
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
    if (this.scheduledDate != null) {
      json[r'scheduledDate'] = this.scheduledDate!.toUtc().toIso8601String();
    } else {
      json[r'scheduledDate'] = null;
    }
    if (this.completedAt != null) {
      json[r'completedAt'] = this.completedAt!.toUtc().toIso8601String();
    } else {
      json[r'completedAt'] = null;
    }
    if (this.estimatedCost != null) {
      json[r'estimatedCost'] = this.estimatedCost;
    } else {
      json[r'estimatedCost'] = null;
    }
    if (this.actualCost != null) {
      json[r'actualCost'] = this.actualCost;
    } else {
      json[r'actualCost'] = null;
    }
    if (this.laborCost != null) {
      json[r'laborCost'] = this.laborCost;
    } else {
      json[r'laborCost'] = null;
    }
    if (this.partsCost != null) {
      json[r'partsCost'] = this.partsCost;
    } else {
      json[r'partsCost'] = null;
    }
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    if (this.requiresApproval != null) {
      json[r'requiresApproval'] = this.requiresApproval;
    } else {
      json[r'requiresApproval'] = null;
    }
    if (this.approved != null) {
      json[r'approved'] = this.approved;
    } else {
      json[r'approved'] = null;
    }
    if (this.approvedById != null) {
      json[r'approvedById'] = this.approvedById;
    } else {
      json[r'approvedById'] = null;
    }
    if (this.approvedByName != null) {
      json[r'approvedByName'] = this.approvedByName;
    } else {
      json[r'approvedByName'] = null;
    }
    if (this.approvedAt != null) {
      json[r'approvedAt'] = this.approvedAt!.toUtc().toIso8601String();
    } else {
      json[r'approvedAt'] = null;
    }
    if (this.maintenanceTaskId != null) {
      json[r'maintenanceTaskId'] = this.maintenanceTaskId;
    } else {
      json[r'maintenanceTaskId'] = null;
    }
    if (this.maintenanceTaskName != null) {
      json[r'maintenanceTaskName'] = this.maintenanceTaskName;
    } else {
      json[r'maintenanceTaskName'] = null;
    }
    if (this.driverIssueId != null) {
      json[r'driverIssueId'] = this.driverIssueId;
    } else {
      json[r'driverIssueId'] = null;
    }
    if (this.pmScheduleId != null) {
      json[r'pmScheduleId'] = this.pmScheduleId;
    } else {
      json[r'pmScheduleId'] = null;
    }
      json[r'tasks'] = this.tasks;
      json[r'photos'] = this.photos;
      json[r'parts'] = this.parts;
    if (this.totalTasks != null) {
      json[r'totalTasks'] = this.totalTasks;
    } else {
      json[r'totalTasks'] = null;
    }
    if (this.completedTasks != null) {
      json[r'completedTasks'] = this.completedTasks;
    } else {
      json[r'completedTasks'] = null;
    }
    if (this.totalPartsCost != null) {
      json[r'totalPartsCost'] = this.totalPartsCost;
    } else {
      json[r'totalPartsCost'] = null;
    }
    return json;
  }

  /// Returns a new [WorkOrderDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkOrderDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'vehicleId'), 'Required key "WorkOrderDto[vehicleId]" is missing from JSON.');
        assert(json[r'vehicleId'] != null, 'Required key "WorkOrderDto[vehicleId]" has a null value in JSON.');
        assert(json.containsKey(r'type'), 'Required key "WorkOrderDto[type]" is missing from JSON.');
        assert(json[r'type'] != null, 'Required key "WorkOrderDto[type]" has a null value in JSON.');
        assert(json.containsKey(r'priority'), 'Required key "WorkOrderDto[priority]" is missing from JSON.');
        assert(json[r'priority'] != null, 'Required key "WorkOrderDto[priority]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "WorkOrderDto[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "WorkOrderDto[title]" has a null value in JSON.');
        return true;
      }());

      return WorkOrderDto(
        id: mapValueOfType<int>(json, r'id'),
        woNumber: mapValueOfType<String>(json, r'woNumber'),
        vehicleId: mapValueOfType<int>(json, r'vehicleId')!,
        vehiclePlate: mapValueOfType<String>(json, r'vehiclePlate'),
        type: WorkOrderDtoTypeEnum.fromJson(json[r'type'])!,
        priority: WorkOrderDtoPriorityEnum.fromJson(json[r'priority'])!,
        status: WorkOrderDtoStatusEnum.fromJson(json[r'status']),
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description'),
        assignedTechnicianId: mapValueOfType<int>(json, r'assignedTechnicianId'),
        assignedTechnicianName: mapValueOfType<String>(json, r'assignedTechnicianName'),
        scheduledDate: mapDateTime(json, r'scheduledDate', r''),
        completedAt: mapDateTime(json, r'completedAt', r''),
        estimatedCost: mapValueOfType<double>(json, r'estimatedCost'),
        actualCost: mapValueOfType<double>(json, r'actualCost'),
        laborCost: mapValueOfType<double>(json, r'laborCost'),
        partsCost: mapValueOfType<double>(json, r'partsCost'),
        notes: mapValueOfType<String>(json, r'notes'),
        requiresApproval: mapValueOfType<bool>(json, r'requiresApproval'),
        approved: mapValueOfType<bool>(json, r'approved'),
        approvedById: mapValueOfType<int>(json, r'approvedById'),
        approvedByName: mapValueOfType<String>(json, r'approvedByName'),
        approvedAt: mapDateTime(json, r'approvedAt', r''),
        maintenanceTaskId: mapValueOfType<int>(json, r'maintenanceTaskId'),
        maintenanceTaskName: mapValueOfType<String>(json, r'maintenanceTaskName'),
        driverIssueId: mapValueOfType<int>(json, r'driverIssueId'),
        pmScheduleId: mapValueOfType<int>(json, r'pmScheduleId'),
        tasks: WorkOrderTaskDto.listFromJson(json[r'tasks']),
        photos: WorkOrderPhotoDto.listFromJson(json[r'photos']),
        parts: WorkOrderPartDto.listFromJson(json[r'parts']),
        totalTasks: mapValueOfType<int>(json, r'totalTasks'),
        completedTasks: mapValueOfType<int>(json, r'completedTasks'),
        totalPartsCost: mapValueOfType<double>(json, r'totalPartsCost'),
      );
    }
    return null;
  }

  static List<WorkOrderDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkOrderDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkOrderDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkOrderDto> mapFromJson(dynamic json) {
    final map = <String, WorkOrderDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkOrderDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkOrderDto-objects as value to a dart map
  static Map<String, List<WorkOrderDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkOrderDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkOrderDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'vehicleId',
    'type',
    'priority',
    'title',
  };
}


class WorkOrderDtoTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const WorkOrderDtoTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PREVENTIVE = WorkOrderDtoTypeEnum._(r'PREVENTIVE');
  static const REPAIR = WorkOrderDtoTypeEnum._(r'REPAIR');
  static const EMERGENCY = WorkOrderDtoTypeEnum._(r'EMERGENCY');
  static const INSPECTION = WorkOrderDtoTypeEnum._(r'INSPECTION');

  /// List of all possible values in this [enum][WorkOrderDtoTypeEnum].
  static const values = <WorkOrderDtoTypeEnum>[
    PREVENTIVE,
    REPAIR,
    EMERGENCY,
    INSPECTION,
  ];

  static WorkOrderDtoTypeEnum? fromJson(dynamic value) => WorkOrderDtoTypeEnumTypeTransformer().decode(value);

  static List<WorkOrderDtoTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkOrderDtoTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkOrderDtoTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WorkOrderDtoTypeEnum] to String,
/// and [decode] dynamic data back to [WorkOrderDtoTypeEnum].
class WorkOrderDtoTypeEnumTypeTransformer {
  factory WorkOrderDtoTypeEnumTypeTransformer() => _instance ??= const WorkOrderDtoTypeEnumTypeTransformer._();

  const WorkOrderDtoTypeEnumTypeTransformer._();

  String encode(WorkOrderDtoTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a WorkOrderDtoTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WorkOrderDtoTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PREVENTIVE': return WorkOrderDtoTypeEnum.PREVENTIVE;
        case r'REPAIR': return WorkOrderDtoTypeEnum.REPAIR;
        case r'EMERGENCY': return WorkOrderDtoTypeEnum.EMERGENCY;
        case r'INSPECTION': return WorkOrderDtoTypeEnum.INSPECTION;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WorkOrderDtoTypeEnumTypeTransformer] instance.
  static WorkOrderDtoTypeEnumTypeTransformer? _instance;
}



class WorkOrderDtoPriorityEnum {
  /// Instantiate a new enum with the provided [value].
  const WorkOrderDtoPriorityEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const URGENT = WorkOrderDtoPriorityEnum._(r'URGENT');
  static const HIGH = WorkOrderDtoPriorityEnum._(r'HIGH');
  static const NORMAL = WorkOrderDtoPriorityEnum._(r'NORMAL');
  static const LOW = WorkOrderDtoPriorityEnum._(r'LOW');

  /// List of all possible values in this [enum][WorkOrderDtoPriorityEnum].
  static const values = <WorkOrderDtoPriorityEnum>[
    URGENT,
    HIGH,
    NORMAL,
    LOW,
  ];

  static WorkOrderDtoPriorityEnum? fromJson(dynamic value) => WorkOrderDtoPriorityEnumTypeTransformer().decode(value);

  static List<WorkOrderDtoPriorityEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkOrderDtoPriorityEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkOrderDtoPriorityEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WorkOrderDtoPriorityEnum] to String,
/// and [decode] dynamic data back to [WorkOrderDtoPriorityEnum].
class WorkOrderDtoPriorityEnumTypeTransformer {
  factory WorkOrderDtoPriorityEnumTypeTransformer() => _instance ??= const WorkOrderDtoPriorityEnumTypeTransformer._();

  const WorkOrderDtoPriorityEnumTypeTransformer._();

  String encode(WorkOrderDtoPriorityEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a WorkOrderDtoPriorityEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WorkOrderDtoPriorityEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'URGENT': return WorkOrderDtoPriorityEnum.URGENT;
        case r'HIGH': return WorkOrderDtoPriorityEnum.HIGH;
        case r'NORMAL': return WorkOrderDtoPriorityEnum.NORMAL;
        case r'LOW': return WorkOrderDtoPriorityEnum.LOW;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WorkOrderDtoPriorityEnumTypeTransformer] instance.
  static WorkOrderDtoPriorityEnumTypeTransformer? _instance;
}



class WorkOrderDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const WorkOrderDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const OPEN = WorkOrderDtoStatusEnum._(r'OPEN');
  static const IN_PROGRESS = WorkOrderDtoStatusEnum._(r'IN_PROGRESS');
  static const WAITING_PARTS = WorkOrderDtoStatusEnum._(r'WAITING_PARTS');
  static const COMPLETED = WorkOrderDtoStatusEnum._(r'COMPLETED');
  static const CANCELLED = WorkOrderDtoStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][WorkOrderDtoStatusEnum].
  static const values = <WorkOrderDtoStatusEnum>[
    OPEN,
    IN_PROGRESS,
    WAITING_PARTS,
    COMPLETED,
    CANCELLED,
  ];

  static WorkOrderDtoStatusEnum? fromJson(dynamic value) => WorkOrderDtoStatusEnumTypeTransformer().decode(value);

  static List<WorkOrderDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkOrderDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkOrderDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WorkOrderDtoStatusEnum] to String,
/// and [decode] dynamic data back to [WorkOrderDtoStatusEnum].
class WorkOrderDtoStatusEnumTypeTransformer {
  factory WorkOrderDtoStatusEnumTypeTransformer() => _instance ??= const WorkOrderDtoStatusEnumTypeTransformer._();

  const WorkOrderDtoStatusEnumTypeTransformer._();

  String encode(WorkOrderDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a WorkOrderDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WorkOrderDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'OPEN': return WorkOrderDtoStatusEnum.OPEN;
        case r'IN_PROGRESS': return WorkOrderDtoStatusEnum.IN_PROGRESS;
        case r'WAITING_PARTS': return WorkOrderDtoStatusEnum.WAITING_PARTS;
        case r'COMPLETED': return WorkOrderDtoStatusEnum.COMPLETED;
        case r'CANCELLED': return WorkOrderDtoStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WorkOrderDtoStatusEnumTypeTransformer] instance.
  static WorkOrderDtoStatusEnumTypeTransformer? _instance;
}


