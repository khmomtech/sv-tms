//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class User {
  /// Returns a new [User] instance.
  User({
    this.id,
    this.username,
    this.email,
    this.roles = const {},
    this.enabled,
    this.accountNonLocked,
    this.accountNonExpired,
    this.credentialsNonExpired,
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
  String? username;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  Set<Role> roles;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? enabled;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? accountNonLocked;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? accountNonExpired;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? credentialsNonExpired;

  @override
  bool operator ==(Object other) => identical(this, other) || other is User &&
    other.id == id &&
    other.username == username &&
    other.email == email &&
    _deepEquality.equals(other.roles, roles) &&
    other.enabled == enabled &&
    other.accountNonLocked == accountNonLocked &&
    other.accountNonExpired == accountNonExpired &&
    other.credentialsNonExpired == credentialsNonExpired;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (username == null ? 0 : username!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (roles.hashCode) +
    (enabled == null ? 0 : enabled!.hashCode) +
    (accountNonLocked == null ? 0 : accountNonLocked!.hashCode) +
    (accountNonExpired == null ? 0 : accountNonExpired!.hashCode) +
    (credentialsNonExpired == null ? 0 : credentialsNonExpired!.hashCode);

  @override
  String toString() => 'User[id=$id, username=$username, email=$email, roles=$roles, enabled=$enabled, accountNonLocked=$accountNonLocked, accountNonExpired=$accountNonExpired, credentialsNonExpired=$credentialsNonExpired]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.username != null) {
      json[r'username'] = this.username;
    } else {
      json[r'username'] = null;
    }
    if (this.email != null) {
      json[r'email'] = this.email;
    } else {
      json[r'email'] = null;
    }
      json[r'roles'] = this.roles.toList(growable: false);
    if (this.enabled != null) {
      json[r'enabled'] = this.enabled;
    } else {
      json[r'enabled'] = null;
    }
    if (this.accountNonLocked != null) {
      json[r'accountNonLocked'] = this.accountNonLocked;
    } else {
      json[r'accountNonLocked'] = null;
    }
    if (this.accountNonExpired != null) {
      json[r'accountNonExpired'] = this.accountNonExpired;
    } else {
      json[r'accountNonExpired'] = null;
    }
    if (this.credentialsNonExpired != null) {
      json[r'credentialsNonExpired'] = this.credentialsNonExpired;
    } else {
      json[r'credentialsNonExpired'] = null;
    }
    return json;
  }

  /// Returns a new [User] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static User? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return User(
        id: mapValueOfType<int>(json, r'id'),
        username: mapValueOfType<String>(json, r'username'),
        email: mapValueOfType<String>(json, r'email'),
        roles: Role.listFromJson(json[r'roles']).toSet(),
        enabled: mapValueOfType<bool>(json, r'enabled'),
        accountNonLocked: mapValueOfType<bool>(json, r'accountNonLocked'),
        accountNonExpired: mapValueOfType<bool>(json, r'accountNonExpired'),
        credentialsNonExpired: mapValueOfType<bool>(json, r'credentialsNonExpired'),
      );
    }
    return null;
  }

  static List<User> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <User>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = User.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, User> mapFromJson(dynamic json) {
    final map = <String, User>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = User.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of User-objects as value to a dart map
  static Map<String, List<User>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<User>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = User.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

