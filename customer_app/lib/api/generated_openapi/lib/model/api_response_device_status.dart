//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiResponseDeviceStatus {
  /// Returns a new [ApiResponseDeviceStatus] instance.
  ApiResponseDeviceStatus({
    this.success,
    this.message,
    this.code,
    this.data,
    this.errors,
    this.timestamp,
    this.requestId,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? success;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? message;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? code;

  ApiResponseDeviceStatusDataEnum? data;

  Object? errors;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? timestamp;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? requestId;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ApiResponseDeviceStatus &&
    other.success == success &&
    other.message == message &&
    other.code == code &&
    other.data == data &&
    other.errors == errors &&
    other.timestamp == timestamp &&
    other.requestId == requestId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (success == null ? 0 : success!.hashCode) +
    (message == null ? 0 : message!.hashCode) +
    (code == null ? 0 : code!.hashCode) +
    (data == null ? 0 : data!.hashCode) +
    (errors == null ? 0 : errors!.hashCode) +
    (timestamp == null ? 0 : timestamp!.hashCode) +
    (requestId == null ? 0 : requestId!.hashCode);

  @override
  String toString() => 'ApiResponseDeviceStatus[success=$success, message=$message, code=$code, data=$data, errors=$errors, timestamp=$timestamp, requestId=$requestId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.success != null) {
      json[r'success'] = this.success;
    } else {
      json[r'success'] = null;
    }
    if (this.message != null) {
      json[r'message'] = this.message;
    } else {
      json[r'message'] = null;
    }
    if (this.code != null) {
      json[r'code'] = this.code;
    } else {
      json[r'code'] = null;
    }
    if (this.data != null) {
      json[r'data'] = this.data;
    } else {
      json[r'data'] = null;
    }
    if (this.errors != null) {
      json[r'errors'] = this.errors;
    } else {
      json[r'errors'] = null;
    }
    if (this.timestamp != null) {
      json[r'timestamp'] = this.timestamp!.toUtc().toIso8601String();
    } else {
      json[r'timestamp'] = null;
    }
    if (this.requestId != null) {
      json[r'requestId'] = this.requestId;
    } else {
      json[r'requestId'] = null;
    }
    return json;
  }

  /// Returns a new [ApiResponseDeviceStatus] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApiResponseDeviceStatus? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ApiResponseDeviceStatus(
        success: mapValueOfType<bool>(json, r'success'),
        message: mapValueOfType<String>(json, r'message'),
        code: mapValueOfType<String>(json, r'code'),
        data: ApiResponseDeviceStatusDataEnum.fromJson(json[r'data']),
        errors: mapValueOfType<Object>(json, r'errors'),
        timestamp: mapDateTime(json, r'timestamp', r''),
        requestId: mapValueOfType<String>(json, r'requestId'),
      );
    }
    return null;
  }

  static List<ApiResponseDeviceStatus> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApiResponseDeviceStatus>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApiResponseDeviceStatus.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApiResponseDeviceStatus> mapFromJson(dynamic json) {
    final map = <String, ApiResponseDeviceStatus>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApiResponseDeviceStatus.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApiResponseDeviceStatus-objects as value to a dart map
  static Map<String, List<ApiResponseDeviceStatus>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ApiResponseDeviceStatus>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApiResponseDeviceStatus.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class ApiResponseDeviceStatusDataEnum {
  /// Instantiate a new enum with the provided [value].
  const ApiResponseDeviceStatusDataEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = ApiResponseDeviceStatusDataEnum._(r'PENDING');
  static const APPROVED = ApiResponseDeviceStatusDataEnum._(r'APPROVED');
  static const BLOCKED = ApiResponseDeviceStatusDataEnum._(r'BLOCKED');
  static const REJECTED = ApiResponseDeviceStatusDataEnum._(r'REJECTED');

  /// List of all possible values in this [enum][ApiResponseDeviceStatusDataEnum].
  static const values = <ApiResponseDeviceStatusDataEnum>[
    PENDING,
    APPROVED,
    BLOCKED,
    REJECTED,
  ];

  static ApiResponseDeviceStatusDataEnum? fromJson(dynamic value) => ApiResponseDeviceStatusDataEnumTypeTransformer().decode(value);

  static List<ApiResponseDeviceStatusDataEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApiResponseDeviceStatusDataEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApiResponseDeviceStatusDataEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ApiResponseDeviceStatusDataEnum] to String,
/// and [decode] dynamic data back to [ApiResponseDeviceStatusDataEnum].
class ApiResponseDeviceStatusDataEnumTypeTransformer {
  factory ApiResponseDeviceStatusDataEnumTypeTransformer() => _instance ??= const ApiResponseDeviceStatusDataEnumTypeTransformer._();

  const ApiResponseDeviceStatusDataEnumTypeTransformer._();

  String encode(ApiResponseDeviceStatusDataEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ApiResponseDeviceStatusDataEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ApiResponseDeviceStatusDataEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return ApiResponseDeviceStatusDataEnum.PENDING;
        case r'APPROVED': return ApiResponseDeviceStatusDataEnum.APPROVED;
        case r'BLOCKED': return ApiResponseDeviceStatusDataEnum.BLOCKED;
        case r'REJECTED': return ApiResponseDeviceStatusDataEnum.REJECTED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ApiResponseDeviceStatusDataEnumTypeTransformer] instance.
  static ApiResponseDeviceStatusDataEnumTypeTransformer? _instance;
}


