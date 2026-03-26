//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AboutAppInfo {
  /// Returns a new [AboutAppInfo] instance.
  AboutAppInfo({
    this.id,
    this.appNameKm,
    this.appNameEn,
    this.androidVersion,
    this.iosVersion,
    this.contactEmail,
    this.privacyPolicyUrlKm,
    this.privacyPolicyUrlEn,
    this.termsConditionsUrlKm,
    this.termsConditionsUrlEn,
    this.lastUpdated,
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
  String? appNameKm;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? appNameEn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? androidVersion;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? iosVersion;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? contactEmail;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? privacyPolicyUrlKm;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? privacyPolicyUrlEn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? termsConditionsUrlKm;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? termsConditionsUrlEn;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? lastUpdated;

  @override
  bool operator ==(Object other) => identical(this, other) || other is AboutAppInfo &&
    other.id == id &&
    other.appNameKm == appNameKm &&
    other.appNameEn == appNameEn &&
    other.androidVersion == androidVersion &&
    other.iosVersion == iosVersion &&
    other.contactEmail == contactEmail &&
    other.privacyPolicyUrlKm == privacyPolicyUrlKm &&
    other.privacyPolicyUrlEn == privacyPolicyUrlEn &&
    other.termsConditionsUrlKm == termsConditionsUrlKm &&
    other.termsConditionsUrlEn == termsConditionsUrlEn &&
    other.lastUpdated == lastUpdated;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (appNameKm == null ? 0 : appNameKm!.hashCode) +
    (appNameEn == null ? 0 : appNameEn!.hashCode) +
    (androidVersion == null ? 0 : androidVersion!.hashCode) +
    (iosVersion == null ? 0 : iosVersion!.hashCode) +
    (contactEmail == null ? 0 : contactEmail!.hashCode) +
    (privacyPolicyUrlKm == null ? 0 : privacyPolicyUrlKm!.hashCode) +
    (privacyPolicyUrlEn == null ? 0 : privacyPolicyUrlEn!.hashCode) +
    (termsConditionsUrlKm == null ? 0 : termsConditionsUrlKm!.hashCode) +
    (termsConditionsUrlEn == null ? 0 : termsConditionsUrlEn!.hashCode) +
    (lastUpdated == null ? 0 : lastUpdated!.hashCode);

  @override
  String toString() => 'AboutAppInfo[id=$id, appNameKm=$appNameKm, appNameEn=$appNameEn, androidVersion=$androidVersion, iosVersion=$iosVersion, contactEmail=$contactEmail, privacyPolicyUrlKm=$privacyPolicyUrlKm, privacyPolicyUrlEn=$privacyPolicyUrlEn, termsConditionsUrlKm=$termsConditionsUrlKm, termsConditionsUrlEn=$termsConditionsUrlEn, lastUpdated=$lastUpdated]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.appNameKm != null) {
      json[r'appNameKm'] = this.appNameKm;
    } else {
      json[r'appNameKm'] = null;
    }
    if (this.appNameEn != null) {
      json[r'appNameEn'] = this.appNameEn;
    } else {
      json[r'appNameEn'] = null;
    }
    if (this.androidVersion != null) {
      json[r'androidVersion'] = this.androidVersion;
    } else {
      json[r'androidVersion'] = null;
    }
    if (this.iosVersion != null) {
      json[r'iosVersion'] = this.iosVersion;
    } else {
      json[r'iosVersion'] = null;
    }
    if (this.contactEmail != null) {
      json[r'contactEmail'] = this.contactEmail;
    } else {
      json[r'contactEmail'] = null;
    }
    if (this.privacyPolicyUrlKm != null) {
      json[r'privacyPolicyUrlKm'] = this.privacyPolicyUrlKm;
    } else {
      json[r'privacyPolicyUrlKm'] = null;
    }
    if (this.privacyPolicyUrlEn != null) {
      json[r'privacyPolicyUrlEn'] = this.privacyPolicyUrlEn;
    } else {
      json[r'privacyPolicyUrlEn'] = null;
    }
    if (this.termsConditionsUrlKm != null) {
      json[r'termsConditionsUrlKm'] = this.termsConditionsUrlKm;
    } else {
      json[r'termsConditionsUrlKm'] = null;
    }
    if (this.termsConditionsUrlEn != null) {
      json[r'termsConditionsUrlEn'] = this.termsConditionsUrlEn;
    } else {
      json[r'termsConditionsUrlEn'] = null;
    }
    if (this.lastUpdated != null) {
      json[r'lastUpdated'] = this.lastUpdated!.toUtc().toIso8601String();
    } else {
      json[r'lastUpdated'] = null;
    }
    return json;
  }

  /// Returns a new [AboutAppInfo] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AboutAppInfo? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return AboutAppInfo(
        id: mapValueOfType<int>(json, r'id'),
        appNameKm: mapValueOfType<String>(json, r'appNameKm'),
        appNameEn: mapValueOfType<String>(json, r'appNameEn'),
        androidVersion: mapValueOfType<String>(json, r'androidVersion'),
        iosVersion: mapValueOfType<String>(json, r'iosVersion'),
        contactEmail: mapValueOfType<String>(json, r'contactEmail'),
        privacyPolicyUrlKm: mapValueOfType<String>(json, r'privacyPolicyUrlKm'),
        privacyPolicyUrlEn: mapValueOfType<String>(json, r'privacyPolicyUrlEn'),
        termsConditionsUrlKm: mapValueOfType<String>(json, r'termsConditionsUrlKm'),
        termsConditionsUrlEn: mapValueOfType<String>(json, r'termsConditionsUrlEn'),
        lastUpdated: mapDateTime(json, r'lastUpdated', r''),
      );
    }
    return null;
  }

  static List<AboutAppInfo> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <AboutAppInfo>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AboutAppInfo.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AboutAppInfo> mapFromJson(dynamic json) {
    final map = <String, AboutAppInfo>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AboutAppInfo.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AboutAppInfo-objects as value to a dart map
  static Map<String, List<AboutAppInfo>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<AboutAppInfo>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AboutAppInfo.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

