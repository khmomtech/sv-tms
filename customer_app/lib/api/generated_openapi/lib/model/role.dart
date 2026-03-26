//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Role {
  /// Returns a new [Role] instance.
  Role({
    this.id,
    this.name,
    this.description,
    this.permissions = const {},
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? id;

  RoleNameEnum? name;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  Set<Permission> permissions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Role &&
    other.id == id &&
    other.name == name &&
    other.description == description &&
    _deepEquality.equals(other.permissions, permissions);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (name == null ? 0 : name!.hashCode) +
    (description == null ? 0 : description!.hashCode) +
    (permissions.hashCode);

  @override
  String toString() => 'Role[id=$id, name=$name, description=$description, permissions=$permissions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
      json[r'permissions'] = this.permissions.toList(growable: false);
    return json;
  }

  /// Returns a new [Role] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Role? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return Role(
        id: mapValueOfType<int>(json, r'id'),
        name: RoleNameEnum.fromJson(json[r'name']),
        description: mapValueOfType<String>(json, r'description'),
        permissions: Permission.listFromJson(json[r'permissions']).toSet(),
      );
    }
    return null;
  }

  static List<Role> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Role>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Role.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Role> mapFromJson(dynamic json) {
    final map = <String, Role>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Role.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Role-objects as value to a dart map
  static Map<String, List<Role>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Role>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Role.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}


class RoleNameEnum {
  /// Instantiate a new enum with the provided [value].
  const RoleNameEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const SUPERADMIN = RoleNameEnum._(r'SUPERADMIN');
  static const ADMIN = RoleNameEnum._(r'ADMIN');
  static const MANAGER = RoleNameEnum._(r'MANAGER');
  static const TECHNICIAN = RoleNameEnum._(r'TECHNICIAN');
  static const DRIVER = RoleNameEnum._(r'DRIVER');
  static const CUSTOMER = RoleNameEnum._(r'CUSTOMER');
  static const PARTNER_ADMIN = RoleNameEnum._(r'PARTNER_ADMIN');
  static const USER = RoleNameEnum._(r'USER');

  /// List of all possible values in this [enum][RoleNameEnum].
  static const values = <RoleNameEnum>[
    SUPERADMIN,
    ADMIN,
    MANAGER,
    TECHNICIAN,
    DRIVER,
    CUSTOMER,
    PARTNER_ADMIN,
    USER,
  ];

  static RoleNameEnum? fromJson(dynamic value) => RoleNameEnumTypeTransformer().decode(value);

  static List<RoleNameEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoleNameEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoleNameEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RoleNameEnum] to String,
/// and [decode] dynamic data back to [RoleNameEnum].
class RoleNameEnumTypeTransformer {
  factory RoleNameEnumTypeTransformer() => _instance ??= const RoleNameEnumTypeTransformer._();

  const RoleNameEnumTypeTransformer._();

  String encode(RoleNameEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a RoleNameEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RoleNameEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'SUPERADMIN': return RoleNameEnum.SUPERADMIN;
        case r'ADMIN': return RoleNameEnum.ADMIN;
        case r'MANAGER': return RoleNameEnum.MANAGER;
        case r'TECHNICIAN': return RoleNameEnum.TECHNICIAN;
        case r'DRIVER': return RoleNameEnum.DRIVER;
        case r'CUSTOMER': return RoleNameEnum.CUSTOMER;
        case r'PARTNER_ADMIN': return RoleNameEnum.PARTNER_ADMIN;
        case r'USER': return RoleNameEnum.USER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RoleNameEnumTypeTransformer] instance.
  static RoleNameEnumTypeTransformer? _instance;
}


