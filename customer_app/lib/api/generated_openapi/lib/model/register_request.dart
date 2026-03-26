//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RegisterRequest {
  /// Returns a new [RegisterRequest] instance.
  RegisterRequest({
    this.username,
    this.password,
    this.email,
    this.roles = const {},
    this.enabled,
  });

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
  String? password;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? email;

  Set<String> roles;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? enabled;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegisterRequest &&
    other.username == username &&
    other.password == password &&
    other.email == email &&
    _deepEquality.equals(other.roles, roles) &&
    other.enabled == enabled;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (username == null ? 0 : username!.hashCode) +
    (password == null ? 0 : password!.hashCode) +
    (email == null ? 0 : email!.hashCode) +
    (roles.hashCode) +
    (enabled == null ? 0 : enabled!.hashCode);

  @override
  String toString() => 'RegisterRequest[username=$username, password=$password, email=$email, roles=$roles, enabled=$enabled]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.username != null) {
      json[r'username'] = this.username;
    } else {
      json[r'username'] = null;
    }
    if (this.password != null) {
      json[r'password'] = this.password;
    } else {
      json[r'password'] = null;
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
    return json;
  }

  /// Returns a new [RegisterRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RegisterRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return RegisterRequest(
        username: mapValueOfType<String>(json, r'username'),
        password: mapValueOfType<String>(json, r'password'),
        email: mapValueOfType<String>(json, r'email'),
        roles: json[r'roles'] is Iterable
            ? (json[r'roles'] as Iterable).cast<String>().toSet()
            : const {},
        enabled: mapValueOfType<bool>(json, r'enabled'),
      );
    }
    return null;
  }

  static List<RegisterRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RegisterRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RegisterRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RegisterRequest> mapFromJson(dynamic json) {
    final map = <String, RegisterRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RegisterRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RegisterRequest-objects as value to a dart map
  static Map<String, List<RegisterRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RegisterRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RegisterRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

