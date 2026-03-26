//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LoadProofDto {
  /// Returns a new [LoadProofDto] instance.
  LoadProofDto({
    this.id,
    this.dispatchId,
    this.routeCode,
    this.driverName,
    this.remarks,
    this.proofImagePaths = const [],
    this.signaturePath,
    this.uploadedAt,
    this.imageUrls = const [],
    this.signatureUrl,
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
  int? dispatchId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? routeCode;

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
  String? remarks;

  List<String> proofImagePaths;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? signaturePath;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? uploadedAt;

  List<String> imageUrls;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? signatureUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LoadProofDto &&
    other.id == id &&
    other.dispatchId == dispatchId &&
    other.routeCode == routeCode &&
    other.driverName == driverName &&
    other.remarks == remarks &&
    _deepEquality.equals(other.proofImagePaths, proofImagePaths) &&
    other.signaturePath == signaturePath &&
    other.uploadedAt == uploadedAt &&
    _deepEquality.equals(other.imageUrls, imageUrls) &&
    other.signatureUrl == signatureUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (dispatchId == null ? 0 : dispatchId!.hashCode) +
    (routeCode == null ? 0 : routeCode!.hashCode) +
    (driverName == null ? 0 : driverName!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (proofImagePaths.hashCode) +
    (signaturePath == null ? 0 : signaturePath!.hashCode) +
    (uploadedAt == null ? 0 : uploadedAt!.hashCode) +
    (imageUrls.hashCode) +
    (signatureUrl == null ? 0 : signatureUrl!.hashCode);

  @override
  String toString() => 'LoadProofDto[id=$id, dispatchId=$dispatchId, routeCode=$routeCode, driverName=$driverName, remarks=$remarks, proofImagePaths=$proofImagePaths, signaturePath=$signaturePath, uploadedAt=$uploadedAt, imageUrls=$imageUrls, signatureUrl=$signatureUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.dispatchId != null) {
      json[r'dispatchId'] = this.dispatchId;
    } else {
      json[r'dispatchId'] = null;
    }
    if (this.routeCode != null) {
      json[r'routeCode'] = this.routeCode;
    } else {
      json[r'routeCode'] = null;
    }
    if (this.driverName != null) {
      json[r'driverName'] = this.driverName;
    } else {
      json[r'driverName'] = null;
    }
    if (this.remarks != null) {
      json[r'remarks'] = this.remarks;
    } else {
      json[r'remarks'] = null;
    }
      json[r'proofImagePaths'] = this.proofImagePaths;
    if (this.signaturePath != null) {
      json[r'signaturePath'] = this.signaturePath;
    } else {
      json[r'signaturePath'] = null;
    }
    if (this.uploadedAt != null) {
      json[r'uploadedAt'] = this.uploadedAt;
    } else {
      json[r'uploadedAt'] = null;
    }
      json[r'imageUrls'] = this.imageUrls;
    if (this.signatureUrl != null) {
      json[r'signatureUrl'] = this.signatureUrl;
    } else {
      json[r'signatureUrl'] = null;
    }
    return json;
  }

  /// Returns a new [LoadProofDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LoadProofDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return LoadProofDto(
        id: mapValueOfType<int>(json, r'id'),
        dispatchId: mapValueOfType<int>(json, r'dispatchId'),
        routeCode: mapValueOfType<String>(json, r'routeCode'),
        driverName: mapValueOfType<String>(json, r'driverName'),
        remarks: mapValueOfType<String>(json, r'remarks'),
        proofImagePaths: json[r'proofImagePaths'] is Iterable
            ? (json[r'proofImagePaths'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        signaturePath: mapValueOfType<String>(json, r'signaturePath'),
        uploadedAt: mapValueOfType<String>(json, r'uploadedAt'),
        imageUrls: json[r'imageUrls'] is Iterable
            ? (json[r'imageUrls'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        signatureUrl: mapValueOfType<String>(json, r'signatureUrl'),
      );
    }
    return null;
  }

  static List<LoadProofDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LoadProofDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LoadProofDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LoadProofDto> mapFromJson(dynamic json) {
    final map = <String, LoadProofDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LoadProofDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LoadProofDto-objects as value to a dart map
  static Map<String, List<LoadProofDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LoadProofDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LoadProofDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

