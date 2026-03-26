//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverAssignmentDto {
  /// Returns a new [DriverAssignmentDto] instance.
  DriverAssignmentDto({
    this.id,
    this.driverId,
    this.driverName,
    this.vehicleId,
    this.vehicleLicensePlate,
    this.assignedAt,
    this.completedAt,
    this.unassignedAt,
    this.status,
    this.unassigned,
    this.active,
    this.completed,
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
  int? vehicleId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? vehicleLicensePlate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? assignedAt;

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
  DateTime? unassignedAt;

  DriverAssignmentDtoStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? unassigned;

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
  bool? completed;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverAssignmentDto &&
    other.id == id &&
    other.driverId == driverId &&
    other.driverName == driverName &&
    other.vehicleId == vehicleId &&
    other.vehicleLicensePlate == vehicleLicensePlate &&
    other.assignedAt == assignedAt &&
    other.completedAt == completedAt &&
    other.unassignedAt == unassignedAt &&
    other.status == status &&
    other.unassigned == unassigned &&
    other.active == active &&
    other.completed == completed;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (driverId == null ? 0 : driverId!.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (vehicleId == null ? 0 : vehicleId!.hashCode) +
    (vehicleLicensePlate == null ? 0 : vehicleLicensePlate!.hashCode) +
    (assignedAt == null ? 0 : assignedAt!.hashCode) +
    (completedAt == null ? 0 : completedAt!.hashCode) +
    (unassignedAt == null ? 0 : unassignedAt!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (unassigned == null ? 0 : unassigned!.hashCode) +
    (active == null ? 0 : active!.hashCode) +
    (completed == null ? 0 : completed!.hashCode);

  @override
  String toString() => 'DriverAssignmentDto[id=$id, driverId=$driverId, driverName=$driverName, vehicleId=$vehicleId, vehicleLicensePlate=$vehicleLicensePlate, assignedAt=$assignedAt, completedAt=$completedAt, unassignedAt=$unassignedAt, status=$status, unassigned=$unassigned, active=$active, completed=$completed]';

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
    if (this.vehicleId != null) {
      json[r'vehicleId'] = this.vehicleId;
    } else {
      json[r'vehicleId'] = null;
    }
    if (this.vehicleLicensePlate != null) {
      json[r'vehicleLicensePlate'] = this.vehicleLicensePlate;
    } else {
      json[r'vehicleLicensePlate'] = null;
    }
    if (this.assignedAt != null) {
      json[r'assignedAt'] = this.assignedAt!.toUtc().toIso8601String();
    } else {
      json[r'assignedAt'] = null;
    }
    if (this.completedAt != null) {
      json[r'completedAt'] = this.completedAt!.toUtc().toIso8601String();
    } else {
      json[r'completedAt'] = null;
    }
    if (this.unassignedAt != null) {
      json[r'unassignedAt'] = this.unassignedAt!.toUtc().toIso8601String();
    } else {
      json[r'unassignedAt'] = null;
    }
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.unassigned != null) {
      json[r'unassigned'] = this.unassigned;
    } else {
      json[r'unassigned'] = null;
    }
    if (this.active != null) {
      json[r'active'] = this.active;
    } else {
      json[r'active'] = null;
    }
    if (this.completed != null) {
      json[r'completed'] = this.completed;
    } else {
      json[r'completed'] = null;
    }
    return json;
  }

  /// Returns a new [DriverAssignmentDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverAssignmentDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DriverAssignmentDto(
        id: mapValueOfType<int>(json, r'id'),
        driverId: mapValueOfType<int>(json, r'driverId'),
        driverName: mapValueOfType<String>(json, r'driverName'),
        vehicleId: mapValueOfType<int>(json, r'vehicleId'),
        vehicleLicensePlate: mapValueOfType<String>(json, r'vehicleLicensePlate'),
        assignedAt: mapDateTime(json, r'assignedAt', r''),
        completedAt: mapDateTime(json, r'completedAt', r''),
        unassignedAt: mapDateTime(json, r'unassignedAt', r''),
        status: DriverAssignmentDtoStatusEnum.fromJson(json[r'status']),
        unassigned: mapValueOfType<bool>(json, r'unassigned'),
        active: mapValueOfType<bool>(json, r'active'),
        completed: mapValueOfType<bool>(json, r'completed'),
      );
    }
    return null;
  }

  static List<DriverAssignmentDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverAssignmentDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverAssignmentDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverAssignmentDto> mapFromJson(dynamic json) {
    final map = <String, DriverAssignmentDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverAssignmentDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverAssignmentDto-objects as value to a dart map
  static Map<String, List<DriverAssignmentDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverAssignmentDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverAssignmentDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class DriverAssignmentDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverAssignmentDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ASSIGNED = DriverAssignmentDtoStatusEnum._(r'ASSIGNED');
  static const ACTIVE = DriverAssignmentDtoStatusEnum._(r'ACTIVE');
  static const UNASSIGNED = DriverAssignmentDtoStatusEnum._(r'UNASSIGNED');
  static const COMPLETED = DriverAssignmentDtoStatusEnum._(r'COMPLETED');
  static const CANCELED = DriverAssignmentDtoStatusEnum._(r'CANCELED');
  static const EXPIRED = DriverAssignmentDtoStatusEnum._(r'EXPIRED');

  /// List of all possible values in this [enum][DriverAssignmentDtoStatusEnum].
  static const values = <DriverAssignmentDtoStatusEnum>[
    ASSIGNED,
    ACTIVE,
    UNASSIGNED,
    COMPLETED,
    CANCELED,
    EXPIRED,
  ];

  static DriverAssignmentDtoStatusEnum? fromJson(dynamic value) => DriverAssignmentDtoStatusEnumTypeTransformer().decode(value);

  static List<DriverAssignmentDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverAssignmentDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverAssignmentDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverAssignmentDtoStatusEnum] to String,
/// and [decode] dynamic data back to [DriverAssignmentDtoStatusEnum].
class DriverAssignmentDtoStatusEnumTypeTransformer {
  factory DriverAssignmentDtoStatusEnumTypeTransformer() => _instance ??= const DriverAssignmentDtoStatusEnumTypeTransformer._();

  const DriverAssignmentDtoStatusEnumTypeTransformer._();

  String encode(DriverAssignmentDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverAssignmentDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverAssignmentDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ASSIGNED': return DriverAssignmentDtoStatusEnum.ASSIGNED;
        case r'ACTIVE': return DriverAssignmentDtoStatusEnum.ACTIVE;
        case r'UNASSIGNED': return DriverAssignmentDtoStatusEnum.UNASSIGNED;
        case r'COMPLETED': return DriverAssignmentDtoStatusEnum.COMPLETED;
        case r'CANCELED': return DriverAssignmentDtoStatusEnum.CANCELED;
        case r'EXPIRED': return DriverAssignmentDtoStatusEnum.EXPIRED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverAssignmentDtoStatusEnumTypeTransformer] instance.
  static DriverAssignmentDtoStatusEnumTypeTransformer? _instance;
}


