//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DispatchStatusHistoryDto {
  /// Returns a new [DispatchStatusHistoryDto] instance.
  DispatchStatusHistoryDto({
    this.status,
    this.updatedAt,
    this.updatedBy,
    this.remarks,
  });

  DispatchStatusHistoryDtoStatusEnum? status;

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
  String? updatedBy;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? remarks;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DispatchStatusHistoryDto &&
    other.status == status &&
    other.updatedAt == updatedAt &&
    other.updatedBy == updatedBy &&
    other.remarks == remarks;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status == null ? 0 : status!.hashCode) +
    (updatedAt == null ? 0 : updatedAt!.hashCode) +
    (updatedBy == null ? 0 : updatedBy!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode);

  @override
  String toString() => 'DispatchStatusHistoryDto[status=$status, updatedAt=$updatedAt, updatedBy=$updatedBy, remarks=$remarks]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.updatedAt != null) {
      json[r'updatedAt'] = this.updatedAt!.toUtc().toIso8601String();
    } else {
      json[r'updatedAt'] = null;
    }
    if (this.updatedBy != null) {
      json[r'updatedBy'] = this.updatedBy;
    } else {
      json[r'updatedBy'] = null;
    }
    if (this.remarks != null) {
      json[r'remarks'] = this.remarks;
    } else {
      json[r'remarks'] = null;
    }
    return json;
  }

  /// Returns a new [DispatchStatusHistoryDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DispatchStatusHistoryDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DispatchStatusHistoryDto(
        status: DispatchStatusHistoryDtoStatusEnum.fromJson(json[r'status']),
        updatedAt: mapDateTime(json, r'updatedAt', r''),
        updatedBy: mapValueOfType<String>(json, r'updatedBy'),
        remarks: mapValueOfType<String>(json, r'remarks'),
      );
    }
    return null;
  }

  static List<DispatchStatusHistoryDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DispatchStatusHistoryDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DispatchStatusHistoryDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DispatchStatusHistoryDto> mapFromJson(dynamic json) {
    final map = <String, DispatchStatusHistoryDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DispatchStatusHistoryDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DispatchStatusHistoryDto-objects as value to a dart map
  static Map<String, List<DispatchStatusHistoryDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DispatchStatusHistoryDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DispatchStatusHistoryDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class DispatchStatusHistoryDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DispatchStatusHistoryDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = DispatchStatusHistoryDtoStatusEnum._(r'PENDING');
  static const ASSIGNED = DispatchStatusHistoryDtoStatusEnum._(r'ASSIGNED');
  static const DRIVER_CONFIRMED = DispatchStatusHistoryDtoStatusEnum._(r'DRIVER_CONFIRMED');
  static const APPROVED = DispatchStatusHistoryDtoStatusEnum._(r'APPROVED');
  static const REJECTED = DispatchStatusHistoryDtoStatusEnum._(r'REJECTED');
  static const SCHEDULED = DispatchStatusHistoryDtoStatusEnum._(r'SCHEDULED');
  static const ARRIVED_LOADING = DispatchStatusHistoryDtoStatusEnum._(r'ARRIVED_LOADING');
  static const LOADING = DispatchStatusHistoryDtoStatusEnum._(r'LOADING');
  static const LOADED = DispatchStatusHistoryDtoStatusEnum._(r'LOADED');
  static const IN_TRANSIT = DispatchStatusHistoryDtoStatusEnum._(r'IN_TRANSIT');
  static const ARRIVED_UNLOADING = DispatchStatusHistoryDtoStatusEnum._(r'ARRIVED_UNLOADING');
  static const UNLOADING = DispatchStatusHistoryDtoStatusEnum._(r'UNLOADING');
  static const UNLOADED = DispatchStatusHistoryDtoStatusEnum._(r'UNLOADED');
  static const DELIVERED = DispatchStatusHistoryDtoStatusEnum._(r'DELIVERED');
  static const COMPLETED = DispatchStatusHistoryDtoStatusEnum._(r'COMPLETED');
  static const CANCELLED = DispatchStatusHistoryDtoStatusEnum._(r'CANCELLED');

  /// List of all possible values in this [enum][DispatchStatusHistoryDtoStatusEnum].
  static const values = <DispatchStatusHistoryDtoStatusEnum>[
    PENDING,
    ASSIGNED,
    DRIVER_CONFIRMED,
    APPROVED,
    REJECTED,
    SCHEDULED,
    ARRIVED_LOADING,
    LOADING,
    LOADED,
    IN_TRANSIT,
    ARRIVED_UNLOADING,
    UNLOADING,
    UNLOADED,
    DELIVERED,
    COMPLETED,
    CANCELLED,
  ];

  static DispatchStatusHistoryDtoStatusEnum? fromJson(dynamic value) => DispatchStatusHistoryDtoStatusEnumTypeTransformer().decode(value);

  static List<DispatchStatusHistoryDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DispatchStatusHistoryDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DispatchStatusHistoryDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DispatchStatusHistoryDtoStatusEnum] to String,
/// and [decode] dynamic data back to [DispatchStatusHistoryDtoStatusEnum].
class DispatchStatusHistoryDtoStatusEnumTypeTransformer {
  factory DispatchStatusHistoryDtoStatusEnumTypeTransformer() => _instance ??= const DispatchStatusHistoryDtoStatusEnumTypeTransformer._();

  const DispatchStatusHistoryDtoStatusEnumTypeTransformer._();

  String encode(DispatchStatusHistoryDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DispatchStatusHistoryDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DispatchStatusHistoryDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return DispatchStatusHistoryDtoStatusEnum.PENDING;
        case r'ASSIGNED': return DispatchStatusHistoryDtoStatusEnum.ASSIGNED;
        case r'DRIVER_CONFIRMED': return DispatchStatusHistoryDtoStatusEnum.DRIVER_CONFIRMED;
        case r'APPROVED': return DispatchStatusHistoryDtoStatusEnum.APPROVED;
        case r'REJECTED': return DispatchStatusHistoryDtoStatusEnum.REJECTED;
        case r'SCHEDULED': return DispatchStatusHistoryDtoStatusEnum.SCHEDULED;
        case r'ARRIVED_LOADING': return DispatchStatusHistoryDtoStatusEnum.ARRIVED_LOADING;
        case r'LOADING': return DispatchStatusHistoryDtoStatusEnum.LOADING;
        case r'LOADED': return DispatchStatusHistoryDtoStatusEnum.LOADED;
        case r'IN_TRANSIT': return DispatchStatusHistoryDtoStatusEnum.IN_TRANSIT;
        case r'ARRIVED_UNLOADING': return DispatchStatusHistoryDtoStatusEnum.ARRIVED_UNLOADING;
        case r'UNLOADING': return DispatchStatusHistoryDtoStatusEnum.UNLOADING;
        case r'UNLOADED': return DispatchStatusHistoryDtoStatusEnum.UNLOADED;
        case r'DELIVERED': return DispatchStatusHistoryDtoStatusEnum.DELIVERED;
        case r'COMPLETED': return DispatchStatusHistoryDtoStatusEnum.COMPLETED;
        case r'CANCELLED': return DispatchStatusHistoryDtoStatusEnum.CANCELLED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DispatchStatusHistoryDtoStatusEnumTypeTransformer] instance.
  static DispatchStatusHistoryDtoStatusEnumTypeTransformer? _instance;
}


