//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DriverLicenseDto {
  /// Returns a new [DriverLicenseDto] instance.
  DriverLicenseDto({
    this.id,
    this.driverId,
    this.driverName,
    this.licenseNumber,
    this.licenseType,
    this.issuedDate,
    this.expiryDate,
    this.issuingAuthority,
    this.licenseImageUrl,
    this.licenseFrontImage,
    this.licenseBackImage,
    this.notes,
    this.expired,
    this.deleted,
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
  int? driverId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? driverName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? licenseNumber;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? licenseType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? issuedDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? expiryDate;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? issuingAuthority;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? licenseImageUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? licenseFrontImage;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? licenseBackImage;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? notes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? expired;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? deleted;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DriverLicenseDto &&
    other.id == id &&
    other.driverId == driverId &&
    other.driverName == driverName &&
    other.licenseNumber == licenseNumber &&
    other.licenseType == licenseType &&
    other.issuedDate == issuedDate &&
    other.expiryDate == expiryDate &&
    other.issuingAuthority == issuingAuthority &&
    other.licenseImageUrl == licenseImageUrl &&
    other.licenseFrontImage == licenseFrontImage &&
    other.licenseBackImage == licenseBackImage &&
    other.notes == notes &&
    other.expired == expired &&
    other.deleted == deleted;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (driverId == null ? 0 : driverId!.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (licenseNumber == null ? 0 : licenseNumber!.hashCode) +
    (licenseType == null ? 0 : licenseType!.hashCode) +
    (issuedDate == null ? 0 : issuedDate!.hashCode) +
    (expiryDate == null ? 0 : expiryDate!.hashCode) +
    (issuingAuthority == null ? 0 : issuingAuthority!.hashCode) +
    (licenseImageUrl == null ? 0 : licenseImageUrl!.hashCode) +
    (licenseFrontImage == null ? 0 : licenseFrontImage!.hashCode) +
    (licenseBackImage == null ? 0 : licenseBackImage!.hashCode) +
    (notes == null ? 0 : notes!.hashCode) +
    (expired == null ? 0 : expired!.hashCode) +
    (deleted == null ? 0 : deleted!.hashCode);

  @override
  String toString() => 'DriverLicenseDto[id=$id, driverId=$driverId, driverName=$driverName, licenseNumber=$licenseNumber, licenseType=$licenseType, issuedDate=$issuedDate, expiryDate=$expiryDate, issuingAuthority=$issuingAuthority, licenseImageUrl=$licenseImageUrl, licenseFrontImage=$licenseFrontImage, licenseBackImage=$licenseBackImage, notes=$notes, expired=$expired, deleted=$deleted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.driverId != null) {
      json[r'driverId'] = this.driverId;
    } else {
      json[r'driverId'] = null;
    }
    if (this.driverName != null) {
      json[r'driverName'] = this.driverName;
    } else {
      json[r'driverName'] = null;
    }
    if (this.licenseNumber != null) {
      json[r'licenseNumber'] = this.licenseNumber;
    } else {
      json[r'licenseNumber'] = null;
    }
    if (this.licenseType != null) {
      json[r'licenseType'] = this.licenseType;
    } else {
      json[r'licenseType'] = null;
    }
    if (this.issuedDate != null) {
      json[r'issuedDate'] = _dateFormatter.format(this.issuedDate!.toUtc());
    } else {
      json[r'issuedDate'] = null;
    }
    if (this.expiryDate != null) {
      json[r'expiryDate'] = _dateFormatter.format(this.expiryDate!.toUtc());
    } else {
      json[r'expiryDate'] = null;
    }
    if (this.issuingAuthority != null) {
      json[r'issuingAuthority'] = this.issuingAuthority;
    } else {
      json[r'issuingAuthority'] = null;
    }
    if (this.licenseImageUrl != null) {
      json[r'licenseImageUrl'] = this.licenseImageUrl;
    } else {
      json[r'licenseImageUrl'] = null;
    }
    if (this.licenseFrontImage != null) {
      json[r'licenseFrontImage'] = this.licenseFrontImage;
    } else {
      json[r'licenseFrontImage'] = null;
    }
    if (this.licenseBackImage != null) {
      json[r'licenseBackImage'] = this.licenseBackImage;
    } else {
      json[r'licenseBackImage'] = null;
    }
    if (this.notes != null) {
      json[r'notes'] = this.notes;
    } else {
      json[r'notes'] = null;
    }
    if (this.expired != null) {
      json[r'expired'] = this.expired;
    } else {
      json[r'expired'] = null;
    }
    if (this.deleted != null) {
      json[r'deleted'] = this.deleted;
    } else {
      json[r'deleted'] = null;
    }
    return json;
  }

  /// Returns a new [DriverLicenseDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DriverLicenseDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DriverLicenseDto(
        id: mapValueOfType<int>(json, r'id'),
        driverId: mapValueOfType<int>(json, r'driverId'),
        driverName: mapValueOfType<String>(json, r'driverName'),
        licenseNumber: mapValueOfType<String>(json, r'licenseNumber'),
        licenseType: mapValueOfType<String>(json, r'licenseType'),
        issuedDate: mapDateTime(json, r'issuedDate', r''),
        expiryDate: mapDateTime(json, r'expiryDate', r''),
        issuingAuthority: mapValueOfType<String>(json, r'issuingAuthority'),
        licenseImageUrl: mapValueOfType<String>(json, r'licenseImageUrl'),
        licenseFrontImage: mapValueOfType<String>(json, r'licenseFrontImage'),
        licenseBackImage: mapValueOfType<String>(json, r'licenseBackImage'),
        notes: mapValueOfType<String>(json, r'notes'),
        expired: mapValueOfType<bool>(json, r'expired'),
        deleted: mapValueOfType<bool>(json, r'deleted'),
      );
    }
    return null;
  }

  static List<DriverLicenseDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DriverLicenseDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DriverLicenseDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DriverLicenseDto> mapFromJson(dynamic json) {
    final map = <String, DriverLicenseDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DriverLicenseDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DriverLicenseDto-objects as value to a dart map
  static Map<String, List<DriverLicenseDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DriverLicenseDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DriverLicenseDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

