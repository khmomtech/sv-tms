//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UnloadProofDto {
  /// Returns a new [UnloadProofDto] instance.
  UnloadProofDto({
    this.id,
    this.dispatchId,
    this.remarks,
    this.address,
    this.latitude,
    this.longitude,
    this.proofImagePaths = const [],
    this.signaturePath,
    this.submittedAt,
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
  String? remarks;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? address;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? latitude;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  double? longitude;

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
  DateTime? submittedAt;

  List<String> imageUrls;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? signatureUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UnloadProofDto &&
    other.id == id &&
    other.dispatchId == dispatchId &&
    other.remarks == remarks &&
    other.address == address &&
    other.latitude == latitude &&
    other.longitude == longitude &&
    _deepEquality.equals(other.proofImagePaths, proofImagePaths) &&
    other.signaturePath == signaturePath &&
    other.submittedAt == submittedAt &&
    _deepEquality.equals(other.imageUrls, imageUrls) &&
    other.signatureUrl == signatureUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (dispatchId == null ? 0 : dispatchId!.hashCode) +
    (remarks == null ? 0 : remarks!.hashCode) +
    (address == null ? 0 : address!.hashCode) +
    (latitude == null ? 0 : latitude!.hashCode) +
    (longitude == null ? 0 : longitude!.hashCode) +
    (proofImagePaths.hashCode) +
    (signaturePath == null ? 0 : signaturePath!.hashCode) +
    (submittedAt == null ? 0 : submittedAt!.hashCode) +
    (imageUrls.hashCode) +
    (signatureUrl == null ? 0 : signatureUrl!.hashCode);

  @override
  String toString() => 'UnloadProofDto[id=$id, dispatchId=$dispatchId, remarks=$remarks, address=$address, latitude=$latitude, longitude=$longitude, proofImagePaths=$proofImagePaths, signaturePath=$signaturePath, submittedAt=$submittedAt, imageUrls=$imageUrls, signatureUrl=$signatureUrl]';

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
    if (this.remarks != null) {
      json[r'remarks'] = this.remarks;
    } else {
      json[r'remarks'] = null;
    }
    if (this.address != null) {
      json[r'address'] = this.address;
    } else {
      json[r'address'] = null;
    }
    if (this.latitude != null) {
      json[r'latitude'] = this.latitude;
    } else {
      json[r'latitude'] = null;
    }
    if (this.longitude != null) {
      json[r'longitude'] = this.longitude;
    } else {
      json[r'longitude'] = null;
    }
      json[r'proofImagePaths'] = this.proofImagePaths;
    if (this.signaturePath != null) {
      json[r'signaturePath'] = this.signaturePath;
    } else {
      json[r'signaturePath'] = null;
    }
    if (this.submittedAt != null) {
      json[r'submittedAt'] = this.submittedAt!.toUtc().toIso8601String();
    } else {
      json[r'submittedAt'] = null;
    }
      json[r'imageUrls'] = this.imageUrls;
    if (this.signatureUrl != null) {
      json[r'signatureUrl'] = this.signatureUrl;
    } else {
      json[r'signatureUrl'] = null;
    }
    return json;
  }

  /// Returns a new [UnloadProofDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UnloadProofDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return UnloadProofDto(
        id: mapValueOfType<int>(json, r'id'),
        dispatchId: mapValueOfType<int>(json, r'dispatchId'),
        remarks: mapValueOfType<String>(json, r'remarks'),
        address: mapValueOfType<String>(json, r'address'),
        latitude: mapValueOfType<double>(json, r'latitude'),
        longitude: mapValueOfType<double>(json, r'longitude'),
        proofImagePaths: json[r'proofImagePaths'] is Iterable
            ? (json[r'proofImagePaths'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        signaturePath: mapValueOfType<String>(json, r'signaturePath'),
        submittedAt: mapDateTime(json, r'submittedAt', r''),
        imageUrls: json[r'imageUrls'] is Iterable
            ? (json[r'imageUrls'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        signatureUrl: mapValueOfType<String>(json, r'signatureUrl'),
      );
    }
    return null;
  }

  static List<UnloadProofDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UnloadProofDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UnloadProofDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UnloadProofDto> mapFromJson(dynamic json) {
    final map = <String, UnloadProofDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UnloadProofDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UnloadProofDto-objects as value to a dart map
  static Map<String, List<UnloadProofDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UnloadProofDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UnloadProofDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

