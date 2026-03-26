//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiResponseListLoadProofDto {
  /// Returns a new [ApiResponseListLoadProofDto] instance.
  ApiResponseListLoadProofDto({
    this.success,
    this.message,
    this.code,
    this.data = const [],
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

  List<LoadProofDto> data;

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
  bool operator ==(Object other) => identical(this, other) || other is ApiResponseListLoadProofDto &&
    other.success == success &&
    other.message == message &&
    other.code == code &&
    _deepEquality.equals(other.data, data) &&
    other.errors == errors &&
    other.timestamp == timestamp &&
    other.requestId == requestId;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (success == null ? 0 : success!.hashCode) +
    (message == null ? 0 : message!.hashCode) +
    (code == null ? 0 : code!.hashCode) +
    (data.hashCode) +
    (errors == null ? 0 : errors!.hashCode) +
    (timestamp == null ? 0 : timestamp!.hashCode) +
    (requestId == null ? 0 : requestId!.hashCode);

  @override
  String toString() => 'ApiResponseListLoadProofDto[success=$success, message=$message, code=$code, data=$data, errors=$errors, timestamp=$timestamp, requestId=$requestId]';

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
      json[r'data'] = this.data;
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

  /// Returns a new [ApiResponseListLoadProofDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ApiResponseListLoadProofDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return ApiResponseListLoadProofDto(
        success: mapValueOfType<bool>(json, r'success'),
        message: mapValueOfType<String>(json, r'message'),
        code: mapValueOfType<String>(json, r'code'),
        data: LoadProofDto.listFromJson(json[r'data']),
        errors: mapValueOfType<Object>(json, r'errors'),
        timestamp: mapDateTime(json, r'timestamp', r''),
        requestId: mapValueOfType<String>(json, r'requestId'),
      );
    }
    return null;
  }

  static List<ApiResponseListLoadProofDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ApiResponseListLoadProofDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ApiResponseListLoadProofDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ApiResponseListLoadProofDto> mapFromJson(dynamic json) {
    final map = <String, ApiResponseListLoadProofDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ApiResponseListLoadProofDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ApiResponseListLoadProofDto-objects as value to a dart map
  static Map<String, List<ApiResponseListLoadProofDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ApiResponseListLoadProofDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ApiResponseListLoadProofDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

