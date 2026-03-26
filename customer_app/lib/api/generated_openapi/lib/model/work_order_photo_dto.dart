//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class WorkOrderPhotoDto {
  /// Returns a new [WorkOrderPhotoDto] instance.
  WorkOrderPhotoDto({
    this.id,
    required this.workOrderId,
    this.taskId,
    required this.photoUrl,
    required this.photoType,
    this.description,
    this.uploadedAt,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  int workOrderId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? taskId;

  String photoUrl;

  WorkOrderPhotoDtoPhotoTypeEnum photoType;

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
  DateTime? uploadedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WorkOrderPhotoDto &&
    other.id == id &&
    other.workOrderId == workOrderId &&
    other.taskId == taskId &&
    other.photoUrl == photoUrl &&
    other.photoType == photoType &&
    other.description == description &&
    other.uploadedAt == uploadedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (workOrderId.hashCode) +
    (taskId == null ? 0 : taskId!.hashCode) +
    (photoUrl.hashCode) +
    (photoType.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (uploadedAt == null ? 0 : uploadedAt!.hashCode);

  @override
  String toString() => 'WorkOrderPhotoDto[id=$id, workOrderId=$workOrderId, taskId=$taskId, photoUrl=$photoUrl, photoType=$photoType, description=$description, uploadedAt=$uploadedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'workOrderId'] = this.workOrderId;
    if (this.taskId != null) {
      json[r'taskId'] = this.taskId;
    } else {
      json[r'taskId'] = null;
    }
      json[r'photoUrl'] = this.photoUrl;
      json[r'photoType'] = this.photoType;
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.uploadedAt != null) {
      json[r'uploadedAt'] = this.uploadedAt!.toUtc().toIso8601String();
    } else {
      json[r'uploadedAt'] = null;
    }
    return json;
  }

  /// Returns a new [WorkOrderPhotoDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static WorkOrderPhotoDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'workOrderId'), 'Required key "WorkOrderPhotoDto[workOrderId]" is missing from JSON.');
        assert(json[r'workOrderId'] != null, 'Required key "WorkOrderPhotoDto[workOrderId]" has a null value in JSON.');
        assert(json.containsKey(r'photoUrl'), 'Required key "WorkOrderPhotoDto[photoUrl]" is missing from JSON.');
        assert(json[r'photoUrl'] != null, 'Required key "WorkOrderPhotoDto[photoUrl]" has a null value in JSON.');
        assert(json.containsKey(r'photoType'), 'Required key "WorkOrderPhotoDto[photoType]" is missing from JSON.');
        assert(json[r'photoType'] != null, 'Required key "WorkOrderPhotoDto[photoType]" has a null value in JSON.');
        return true;
      }());

      return WorkOrderPhotoDto(
        id: mapValueOfType<int>(json, r'id'),
        workOrderId: mapValueOfType<int>(json, r'workOrderId')!,
        taskId: mapValueOfType<int>(json, r'taskId'),
        photoUrl: mapValueOfType<String>(json, r'photoUrl')!,
        photoType: WorkOrderPhotoDtoPhotoTypeEnum.fromJson(json[r'photoType'])!,
        description: mapValueOfType<String>(json, r'description'),
        uploadedAt: mapDateTime(json, r'uploadedAt', r''),
      );
    }
    return null;
  }

  static List<WorkOrderPhotoDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkOrderPhotoDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkOrderPhotoDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, WorkOrderPhotoDto> mapFromJson(dynamic json) {
    final map = <String, WorkOrderPhotoDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = WorkOrderPhotoDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of WorkOrderPhotoDto-objects as value to a dart map
  static Map<String, List<WorkOrderPhotoDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<WorkOrderPhotoDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = WorkOrderPhotoDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'workOrderId',
    'photoUrl',
    'photoType',
  };
}


class WorkOrderPhotoDtoPhotoTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const WorkOrderPhotoDtoPhotoTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const BEFORE = WorkOrderPhotoDtoPhotoTypeEnum._(r'BEFORE');
  static const AFTER = WorkOrderPhotoDtoPhotoTypeEnum._(r'AFTER');
  static const DIAGNOSTIC = WorkOrderPhotoDtoPhotoTypeEnum._(r'DIAGNOSTIC');

  /// List of all possible values in this [enum][WorkOrderPhotoDtoPhotoTypeEnum].
  static const values = <WorkOrderPhotoDtoPhotoTypeEnum>[
    BEFORE,
    AFTER,
    DIAGNOSTIC,
  ];

  static WorkOrderPhotoDtoPhotoTypeEnum? fromJson(dynamic value) => WorkOrderPhotoDtoPhotoTypeEnumTypeTransformer().decode(value);

  static List<WorkOrderPhotoDtoPhotoTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <WorkOrderPhotoDtoPhotoTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = WorkOrderPhotoDtoPhotoTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [WorkOrderPhotoDtoPhotoTypeEnum] to String,
/// and [decode] dynamic data back to [WorkOrderPhotoDtoPhotoTypeEnum].
class WorkOrderPhotoDtoPhotoTypeEnumTypeTransformer {
  factory WorkOrderPhotoDtoPhotoTypeEnumTypeTransformer() => _instance ??= const WorkOrderPhotoDtoPhotoTypeEnumTypeTransformer._();

  const WorkOrderPhotoDtoPhotoTypeEnumTypeTransformer._();

  String encode(WorkOrderPhotoDtoPhotoTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a WorkOrderPhotoDtoPhotoTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  WorkOrderPhotoDtoPhotoTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'BEFORE': return WorkOrderPhotoDtoPhotoTypeEnum.BEFORE;
        case r'AFTER': return WorkOrderPhotoDtoPhotoTypeEnum.AFTER;
        case r'DIAGNOSTIC': return WorkOrderPhotoDtoPhotoTypeEnum.DIAGNOSTIC;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [WorkOrderPhotoDtoPhotoTypeEnumTypeTransformer] instance.
  static WorkOrderPhotoDtoPhotoTypeEnumTypeTransformer? _instance;
}


