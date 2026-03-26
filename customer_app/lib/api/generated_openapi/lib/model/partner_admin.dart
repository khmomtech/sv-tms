//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PartnerAdmin {
  /// Returns a new [PartnerAdmin] instance.
  PartnerAdmin({
    this.id,
    this.user,
    this.partnerCompany,
    this.canManageDrivers,
    this.canManageCustomers,
    this.canViewReports,
    this.canManageSettings,
    this.isPrimary,
    this.createdAt,
    this.createdBy,
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
  User? user;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  PartnerCompany? partnerCompany;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? canManageDrivers;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? canManageCustomers;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? canViewReports;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? canManageSettings;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? isPrimary;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? createdAt;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? createdBy;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PartnerAdmin &&
    other.id == id &&
    other.user == user &&
    other.partnerCompany == partnerCompany &&
    other.canManageDrivers == canManageDrivers &&
    other.canManageCustomers == canManageCustomers &&
    other.canViewReports == canViewReports &&
    other.canManageSettings == canManageSettings &&
    other.isPrimary == isPrimary &&
    other.createdAt == createdAt &&
    other.createdBy == createdBy;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (user == null ? 0 : user!.hashCode) +
    (partnerCompany == null ? 0 : partnerCompany!.hashCode) +
    (canManageDrivers == null ? 0 : canManageDrivers!.hashCode) +
    (canManageCustomers == null ? 0 : canManageCustomers!.hashCode) +
    (canViewReports == null ? 0 : canViewReports!.hashCode) +
    (canManageSettings == null ? 0 : canManageSettings!.hashCode) +
    (isPrimary == null ? 0 : isPrimary!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (createdBy == null ? 0 : createdBy!.hashCode);

  @override
  String toString() => 'PartnerAdmin[id=$id, user=$user, partnerCompany=$partnerCompany, canManageDrivers=$canManageDrivers, canManageCustomers=$canManageCustomers, canViewReports=$canViewReports, canManageSettings=$canManageSettings, isPrimary=$isPrimary, createdAt=$createdAt, createdBy=$createdBy]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.user != null) {
      json[r'user'] = this.user;
    } else {
      json[r'user'] = null;
    }
    if (this.partnerCompany != null) {
      json[r'partnerCompany'] = this.partnerCompany;
    } else {
      json[r'partnerCompany'] = null;
    }
    if (this.canManageDrivers != null) {
      json[r'canManageDrivers'] = this.canManageDrivers;
    } else {
      json[r'canManageDrivers'] = null;
    }
    if (this.canManageCustomers != null) {
      json[r'canManageCustomers'] = this.canManageCustomers;
    } else {
      json[r'canManageCustomers'] = null;
    }
    if (this.canViewReports != null) {
      json[r'canViewReports'] = this.canViewReports;
    } else {
      json[r'canViewReports'] = null;
    }
    if (this.canManageSettings != null) {
      json[r'canManageSettings'] = this.canManageSettings;
    } else {
      json[r'canManageSettings'] = null;
    }
    if (this.isPrimary != null) {
      json[r'isPrimary'] = this.isPrimary;
    } else {
      json[r'isPrimary'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.createdBy != null) {
      json[r'createdBy'] = this.createdBy;
    } else {
      json[r'createdBy'] = null;
    }
    return json;
  }

  /// Returns a new [PartnerAdmin] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PartnerAdmin? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return PartnerAdmin(
        id: mapValueOfType<int>(json, r'id'),
        user: User.fromJson(json[r'user']),
        partnerCompany: PartnerCompany.fromJson(json[r'partnerCompany']),
        canManageDrivers: mapValueOfType<bool>(json, r'canManageDrivers'),
        canManageCustomers: mapValueOfType<bool>(json, r'canManageCustomers'),
        canViewReports: mapValueOfType<bool>(json, r'canViewReports'),
        canManageSettings: mapValueOfType<bool>(json, r'canManageSettings'),
        isPrimary: mapValueOfType<bool>(json, r'isPrimary'),
        createdAt: mapDateTime(json, r'createdAt', r''),
        createdBy: mapValueOfType<String>(json, r'createdBy'),
      );
    }
    return null;
  }

  static List<PartnerAdmin> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PartnerAdmin>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PartnerAdmin.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PartnerAdmin> mapFromJson(dynamic json) {
    final map = <String, PartnerAdmin>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PartnerAdmin.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PartnerAdmin-objects as value to a dart map
  static Map<String, List<PartnerAdmin>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PartnerAdmin>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PartnerAdmin.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

