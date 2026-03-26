//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserPermissionSummaryDto {
  /// Returns a new [UserPermissionSummaryDto] instance.
  UserPermissionSummaryDto({
    this.userId,
    this.permissions = const {},
    this.permissionMatrix = const {},
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? userId;

  Set<String> permissions;

  Map<String, Set<String>> permissionMatrix;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserPermissionSummaryDto &&
    other.userId == userId &&
    _deepEquality.equals(other.permissions, permissions) &&
    _deepEquality.equals(other.permissionMatrix, permissionMatrix);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (userId == null ? 0 : userId!.hashCode) +
    (permissions.hashCode) +
    (permissionMatrix.hashCode);

  @override
  String toString() => 'UserPermissionSummaryDto[userId=$userId, permissions=$permissions, permissionMatrix=$permissionMatrix]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.userId != null) {
      json[r'userId'] = this.userId;
    } else {
      json[r'userId'] = null;
    }
      json[r'permissions'] = this.permissions.toList(growable: false);
      json[r'permissionMatrix'] = this.permissionMatrix;
    return json;
  }

  /// Returns a new [UserPermissionSummaryDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserPermissionSummaryDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UserPermissionSummaryDto(
        userId: mapValueOfType<int>(json, r'userId'),
        permissions: json[r'permissions'] is Iterable
            ? (json[r'permissions'] as Iterable).cast<String>().toSet()
            : const {},
        permissionMatrix: json[r'permissionMatrix'] == null
          ? const {}
            : (json[r'permissionMatrix'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v == null ? const <String>[] : (v as List).cast<String>())),
      );
    }
    return null;
  }

  static List<UserPermissionSummaryDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserPermissionSummaryDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserPermissionSummaryDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserPermissionSummaryDto> mapFromJson(dynamic json) {
    final map = <String, UserPermissionSummaryDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserPermissionSummaryDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserPermissionSummaryDto-objects as value to a dart map
  static Map<String, List<UserPermissionSummaryDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserPermissionSummaryDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserPermissionSummaryDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

