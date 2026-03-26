//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverIssueDto {
  /// Returns a new [DriverIssueDto] instance.
  DriverIssueDto({
    this.id,
    required this.driverId,
    this.driverName,
    required this.vehicleId,
    this.vehiclePlate,
    required this.title,
    required this.description,
    required this.severity,
    this.status,
    this.location,
    this.currentKm,
    this.photoUrls = const [],
    this.photos = const [],
    this.workOrderId,
    this.assignedToId,
    this.assignedToName,
    this.reportedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.createdAt,
    this.images = const [],
    this.dispatchId,
    this.orderReference,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  int driverId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? driverName;

  int vehicleId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? vehiclePlate;

  String title;

  String description;

  DriverIssueDtoSeverityEnum severity;

  DriverIssueDtoStatusEnum? status;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? location;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? currentKm;

  List<String> photoUrls;

  List<DriverIssuePhotoDto> photos;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? workOrderId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? assignedToId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? assignedToName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? reportedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? resolvedAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? resolutionNotes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  List<String> images;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? dispatchId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? orderReference;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverIssueDto &&
    other.id == id &&
    other.driverId == driverId &&
    other.driverName == driverName &&
    other.vehicleId == vehicleId &&
    other.vehiclePlate == vehiclePlate &&
    other.title == title &&
    other.description == description &&
    other.severity == severity &&
    other.status == status &&
    other.location == location &&
    other.currentKm == currentKm &&
    _deepEquality.equals(other.photoUrls, photoUrls) &&
    _deepEquality.equals(other.photos, photos) &&
    other.workOrderId == workOrderId &&
    other.assignedToId == assignedToId &&
    other.assignedToName == assignedToName &&
    other.reportedAt == reportedAt &&
    other.resolvedAt == resolvedAt &&
    other.resolutionNotes == resolutionNotes &&
    other.createdAt == createdAt &&
    _deepEquality.equals(other.images, images) &&
    other.dispatchId == dispatchId &&
    other.orderReference == orderReference;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (driverId.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (vehicleId.hashCode) +
    (vehiclePlate == null ? 0 : vehiclePlate!.hashCode) +
    (title.hashCode) +
    (description.hashCode) +
    (severity.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (location == null ? 0 : location!.hashCode) +
    (currentKm == null ? 0 : currentKm!.hashCode) +
    (photoUrls.hashCode) +
    (photos.hashCode) +
    (workOrderId == null ? 0 : workOrderId!.hashCode) +
    (assignedToId == null ? 0 : assignedToId!.hashCode) +
    (assignedToName == null ? 0 : assignedToName!.hashCode) +
    (reportedAt == null ? 0 : reportedAt!.hashCode) +
    (resolvedAt == null ? 0 : resolvedAt!.hashCode) +
    (resolutionNotes == null ? 0 : resolutionNotes!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (images.hashCode) +
    (dispatchId == null ? 0 : dispatchId!.hashCode) +
    (orderReference == null ? 0 : orderReference!.hashCode);

  @override
  String toString() => 'DriverIssueDto[id=$id, driverId=$driverId, driverName=$driverName, vehicleId=$vehicleId, vehiclePlate=$vehiclePlate, title=$title, description=$description, severity=$severity, status=$status, location=$location, currentKm=$currentKm, photoUrls=$photoUrls, photos=$photos, workOrderId=$workOrderId, assignedToId=$assignedToId, assignedToName=$assignedToName, reportedAt=$reportedAt, resolvedAt=$resolvedAt, resolutionNotes=$resolutionNotes, createdAt=$createdAt, images=$images, dispatchId=$dispatchId, orderReference=$orderReference]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
      json[r'driverId'] = this.driverId;
    if (this.driverName != null) {
      json[r'driverName'] = this.driverName;
    } else {
      json[r'driverName'] = null;
    }
      json[r'vehicleId'] = this.vehicleId;
    if (this.vehiclePlate != null) {
      json[r'vehiclePlate'] = this.vehiclePlate;
    } else {
      json[r'vehiclePlate'] = null;
    }
      json[r'title'] = this.title;
      json[r'description'] = this.description;
      json[r'severity'] = this.severity;
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.location != null) {
      json[r'location'] = this.location;
    } else {
      json[r'location'] = null;
    }
    if (this.currentKm != null) {
      json[r'currentKm'] = this.currentKm;
    } else {
      json[r'currentKm'] = null;
    }
      json[r'photoUrls'] = this.photoUrls;
      json[r'photos'] = this.photos;
    if (this.workOrderId != null) {
      json[r'workOrderId'] = this.workOrderId;
    } else {
      json[r'workOrderId'] = null;
    }
    if (this.assignedToId != null) {
      json[r'assignedToId'] = this.assignedToId;
    } else {
      json[r'assignedToId'] = null;
    }
    if (this.assignedToName != null) {
      json[r'assignedToName'] = this.assignedToName;
    } else {
      json[r'assignedToName'] = null;
    }
    if (this.reportedAt != null) {
      json[r'reportedAt'] = this.reportedAt!.toUtc().toIso8601String();
    } else {
      json[r'reportedAt'] = null;
    }
    if (this.resolvedAt != null) {
      json[r'resolvedAt'] = this.resolvedAt!.toUtc().toIso8601String();
    } else {
      json[r'resolvedAt'] = null;
    }
    if (this.resolutionNotes != null) {
      json[r'resolutionNotes'] = this.resolutionNotes;
    } else {
      json[r'resolutionNotes'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
      json[r'images'] = this.images;
    if (this.dispatchId != null) {
      json[r'dispatchId'] = this.dispatchId;
    } else {
      json[r'dispatchId'] = null;
    }
    if (this.orderReference != null) {
      json[r'orderReference'] = this.orderReference;
    } else {
      json[r'orderReference'] = null;
    }
    return json;
  }

  /// Returns a new [DriverIssueDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverIssueDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        assert(json.containsKey(r'driverId'), 'Required key "DriverIssueDto[driverId]" is missing from JSON.');
        assert(json[r'driverId'] != null, 'Required key "DriverIssueDto[driverId]" has a null value in JSON.');
        assert(json.containsKey(r'vehicleId'), 'Required key "DriverIssueDto[vehicleId]" is missing from JSON.');
        assert(json[r'vehicleId'] != null, 'Required key "DriverIssueDto[vehicleId]" has a null value in JSON.');
        assert(json.containsKey(r'title'), 'Required key "DriverIssueDto[title]" is missing from JSON.');
        assert(json[r'title'] != null, 'Required key "DriverIssueDto[title]" has a null value in JSON.');
        assert(json.containsKey(r'description'), 'Required key "DriverIssueDto[description]" is missing from JSON.');
        assert(json[r'description'] != null, 'Required key "DriverIssueDto[description]" has a null value in JSON.');
        assert(json.containsKey(r'severity'), 'Required key "DriverIssueDto[severity]" is missing from JSON.');
        assert(json[r'severity'] != null, 'Required key "DriverIssueDto[severity]" has a null value in JSON.');
        return true;
      }());

      return DriverIssueDto(
        id: mapValueOfType<int>(json, r'id'),
        driverId: mapValueOfType<int>(json, r'driverId')!,
        driverName: mapValueOfType<String>(json, r'driverName'),
        vehicleId: mapValueOfType<int>(json, r'vehicleId')!,
        vehiclePlate: mapValueOfType<String>(json, r'vehiclePlate'),
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description')!,
        severity: DriverIssueDtoSeverityEnum.fromJson(json[r'severity'])!,
        status: DriverIssueDtoStatusEnum.fromJson(json[r'status']),
        location: mapValueOfType<String>(json, r'location'),
        currentKm: mapValueOfType<double>(json, r'currentKm'),
        photoUrls: json[r'photoUrls'] is Iterable
            ? (json[r'photoUrls'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        photos: DriverIssuePhotoDto.listFromJson(json[r'photos']),
        workOrderId: mapValueOfType<int>(json, r'workOrderId'),
        assignedToId: mapValueOfType<int>(json, r'assignedToId'),
        assignedToName: mapValueOfType<String>(json, r'assignedToName'),
        reportedAt: mapDateTime(json, r'reportedAt', r''),
        resolvedAt: mapDateTime(json, r'resolvedAt', r''),
        resolutionNotes: mapValueOfType<String>(json, r'resolutionNotes'),
        createdAt: mapDateTime(json, r'createdAt', r''),
        images: json[r'images'] is Iterable
            ? (json[r'images'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        dispatchId: mapValueOfType<int>(json, r'dispatchId'),
        orderReference: mapValueOfType<String>(json, r'orderReference'),
      );
    }
    return null;
  }

  static List<DriverIssueDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverIssueDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverIssueDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverIssueDto> mapFromJson(dynamic json) {
    final map = <String, DriverIssueDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverIssueDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverIssueDto-objects as value to a dart map
  static Map<String, List<DriverIssueDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverIssueDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverIssueDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'driverId',
    'vehicleId',
    'title',
    'description',
    'severity',
  };
}


class DriverIssueDtoSeverityEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverIssueDtoSeverityEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const LOW = DriverIssueDtoSeverityEnum._(r'LOW');
  static const MEDIUM = DriverIssueDtoSeverityEnum._(r'MEDIUM');
  static const HIGH = DriverIssueDtoSeverityEnum._(r'HIGH');
  static const CRITICAL = DriverIssueDtoSeverityEnum._(r'CRITICAL');

  /// List of all possible values in this [enum][DriverIssueDtoSeverityEnum].
  static const values = <DriverIssueDtoSeverityEnum>[
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL,
  ];

  static DriverIssueDtoSeverityEnum? fromJson(dynamic value) => DriverIssueDtoSeverityEnumTypeTransformer().decode(value);

  static List<DriverIssueDtoSeverityEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverIssueDtoSeverityEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverIssueDtoSeverityEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverIssueDtoSeverityEnum] to String,
/// and [decode] dynamic data back to [DriverIssueDtoSeverityEnum].
class DriverIssueDtoSeverityEnumTypeTransformer {
  factory DriverIssueDtoSeverityEnumTypeTransformer() => _instance ??= const DriverIssueDtoSeverityEnumTypeTransformer._();

  const DriverIssueDtoSeverityEnumTypeTransformer._();

  String encode(DriverIssueDtoSeverityEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverIssueDtoSeverityEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverIssueDtoSeverityEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'LOW': return DriverIssueDtoSeverityEnum.LOW;
        case r'MEDIUM': return DriverIssueDtoSeverityEnum.MEDIUM;
        case r'HIGH': return DriverIssueDtoSeverityEnum.HIGH;
        case r'CRITICAL': return DriverIssueDtoSeverityEnum.CRITICAL;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverIssueDtoSeverityEnumTypeTransformer] instance.
  static DriverIssueDtoSeverityEnumTypeTransformer? _instance;
}



class DriverIssueDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DriverIssueDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const OPEN = DriverIssueDtoStatusEnum._(r'OPEN');
  static const IN_PROGRESS = DriverIssueDtoStatusEnum._(r'IN_PROGRESS');
  static const RESOLVED = DriverIssueDtoStatusEnum._(r'RESOLVED');
  static const CLOSED = DriverIssueDtoStatusEnum._(r'CLOSED');

  /// List of all possible values in this [enum][DriverIssueDtoStatusEnum].
  static const values = <DriverIssueDtoStatusEnum>[
    OPEN,
    IN_PROGRESS,
    RESOLVED,
    CLOSED,
  ];

  static DriverIssueDtoStatusEnum? fromJson(dynamic value) => DriverIssueDtoStatusEnumTypeTransformer().decode(value);

  static List<DriverIssueDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverIssueDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverIssueDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DriverIssueDtoStatusEnum] to String,
/// and [decode] dynamic data back to [DriverIssueDtoStatusEnum].
class DriverIssueDtoStatusEnumTypeTransformer {
  factory DriverIssueDtoStatusEnumTypeTransformer() => _instance ??= const DriverIssueDtoStatusEnumTypeTransformer._();

  const DriverIssueDtoStatusEnumTypeTransformer._();

  String encode(DriverIssueDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DriverIssueDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DriverIssueDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'OPEN': return DriverIssueDtoStatusEnum.OPEN;
        case r'IN_PROGRESS': return DriverIssueDtoStatusEnum.IN_PROGRESS;
        case r'RESOLVED': return DriverIssueDtoStatusEnum.RESOLVED;
        case r'CLOSED': return DriverIssueDtoStatusEnum.CLOSED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DriverIssueDtoStatusEnumTypeTransformer] instance.
  static DriverIssueDtoStatusEnumTypeTransformer? _instance;
}


