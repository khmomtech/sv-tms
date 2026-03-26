//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverAssignment {
  /// Returns a new [DriverAssignment] instance.
  DriverAssignment({
    this.id,
    this.driver,
    this.vehicle,
    this.assignedAt,
    this.completedAt,
    this.unassignedAt,
    this.status,
    this.version,
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
  Driver? driver;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Vehicle? vehicle;

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

  DriverAssignmentStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? version;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverAssignment &&
    other.id == id &&
    other.driver == driver &&
    other.vehicle == vehicle &&
    other.assignedAt == assignedAt &&
    other.completedAt == completedAt &&
    other.unassignedAt == unassignedAt &&
    other.status == status &&
    other.version == version;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (driver == null ? 0 : driver!.hashCode) +
    (vehicle == null ? 0 : vehicle!.hashCode) +
    (assignedAt == null ? 0 : assignedAt!.hashCode) +
    (completedAt == null ? 0 : completedAt!.hashCode) +
    (unassignedAt == null ? 0 : unassignedAt!.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (version == null ? 0 : version!.hashCode);

  @override
  String toString() => 'DriverAssignment[id=$id, driver=$driver, vehicle=$vehicle, assignedAt=$assignedAt, completedAt=$completedAt, unassignedAt=$unassignedAt, status=$status, version=$version]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.driver != null) {
      json[r'driver'] = this.driver;
    } else {
      json[r'driver'] = null;
    }
    if (this.vehicle != null) {
      json[r'vehicle'] = this.vehicle;
    } else {
      json[r'vehicle'] = null;
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
    if (this.version != null) {
      json[r'version'] = this.version;
    } else {
      json[r'version'] = null;
    }
    return json;
  }

  /// Returns a new [DriverAssignment] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverAssignment? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DriverAssignment(
        id: mapValueOfType<int>(json, r'id'),
        driver: Driver.fromJson(json[r'driver']),
        vehicle: Vehicle.fromJson(json[r'vehicle']),
        assignedAt: mapDateTime(json, r'assignedAt', r''),
        completedAt: mapDateTime(json, r'completedAt', r''),
        unassignedAt: mapDateTime(json, r'unassignedAt', r''),
        status: DriverAssignmentStatusEnum.fromJson(json[r'status']),
        version: mapValueOfType<int>(json, r'version'),
      );
    }
    return null;
  }

  static List<DriverAssignment> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverAssignment>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverAssignment.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverAssignment> mapFromJson(dynamic json) {
    final map = <String, DriverAssignment>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverAssignment.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverAssignment-objects as value to a dart map
  static Map<String, List<DriverAssignment>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverAssignment>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverAssignment.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class DriverAssignmentStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverAssignmentStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ASSIGNED = DriverAssignmentStatusEnum._(r'ASSIGNED');
  static const ACTIVE = DriverAssignmentStatusEnum._(r'ACTIVE');
  static const UNASSIGNED = DriverAssignmentStatusEnum._(r'UNASSIGNED');
  static const COMPLETED = DriverAssignmentStatusEnum._(r'COMPLETED');
  static const CANCELED = DriverAssignmentStatusEnum._(r'CANCELED');
  static const EXPIRED = DriverAssignmentStatusEnum._(r'EXPIRED');

  /// List of all possible values in this [enum][DriverAssignmentStatusEnum].
  static const values = <DriverAssignmentStatusEnum>[
    ASSIGNED,
    ACTIVE,
    UNASSIGNED,
    COMPLETED,
    CANCELED,
    EXPIRED,
  ];

  static DriverAssignmentStatusEnum? fromJson(dynamic value) => DriverAssignmentStatusEnumTypeTransformer().decode(value);

  static List<DriverAssignmentStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverAssignmentStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverAssignmentStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverAssignmentStatusEnum] to String,
/// and [decode] dynamic data back to [DriverAssignmentStatusEnum].
class DriverAssignmentStatusEnumTypeTransformer {
  factory DriverAssignmentStatusEnumTypeTransformer() => _instance ??= const DriverAssignmentStatusEnumTypeTransformer._();

  const DriverAssignmentStatusEnumTypeTransformer._();

  String encode(DriverAssignmentStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverAssignmentStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverAssignmentStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ASSIGNED': return DriverAssignmentStatusEnum.ASSIGNED;
        case r'ACTIVE': return DriverAssignmentStatusEnum.ACTIVE;
        case r'UNASSIGNED': return DriverAssignmentStatusEnum.UNASSIGNED;
        case r'COMPLETED': return DriverAssignmentStatusEnum.COMPLETED;
        case r'CANCELED': return DriverAssignmentStatusEnum.CANCELED;
        case r'EXPIRED': return DriverAssignmentStatusEnum.EXPIRED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverAssignmentStatusEnumTypeTransformer] instance.
  static DriverAssignmentStatusEnumTypeTransformer? _instance;
}


