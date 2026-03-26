//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DocumentAuditDto {
  /// Returns a new [DocumentAuditDto] instance.
  DocumentAuditDto({
    this.documentId,
    this.auditId,
    this.sizeBytes,
    this.mimeType,
    this.checksumSha256,
    this.integrityOk,
    this.thumbnailUrl,
    this.thumbnailAttempted,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? documentId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? auditId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  int? sizeBytes;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mimeType;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? checksumSha256;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? integrityOk;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? thumbnailUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? thumbnailAttempted;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DocumentAuditDto &&
    other.documentId == documentId &&
    other.auditId == auditId &&
    other.sizeBytes == sizeBytes &&
    other.mimeType == mimeType &&
    other.checksumSha256 == checksumSha256 &&
    other.integrityOk == integrityOk &&
    other.thumbnailUrl == thumbnailUrl &&
    other.thumbnailAttempted == thumbnailAttempted;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (documentId == null ? 0 : documentId!.hashCode) +
    (auditId == null ? 0 : auditId!.hashCode) +
    (sizeBytes == null ? 0 : sizeBytes!.hashCode) +
    (mimeType == null ? 0 : mimeType!.hashCode) +
    (checksumSha256 == null ? 0 : checksumSha256!.hashCode) +
    (integrityOk == null ? 0 : integrityOk!.hashCode) +
    (thumbnailUrl == null ? 0 : thumbnailUrl!.hashCode) +
    (thumbnailAttempted == null ? 0 : thumbnailAttempted!.hashCode);

  @override
  String toString() => 'DocumentAuditDto[documentId=$documentId, auditId=$auditId, sizeBytes=$sizeBytes, mimeType=$mimeType, checksumSha256=$checksumSha256, integrityOk=$integrityOk, thumbnailUrl=$thumbnailUrl, thumbnailAttempted=$thumbnailAttempted]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.documentId != null) {
      json[r'documentId'] = this.documentId;
    } else {
      json[r'documentId'] = null;
    }
    if (this.auditId != null) {
      json[r'auditId'] = this.auditId;
    } else {
      json[r'auditId'] = null;
    }
    if (this.sizeBytes != null) {
      json[r'sizeBytes'] = this.sizeBytes;
    } else {
      json[r'sizeBytes'] = null;
    }
    if (this.mimeType != null) {
      json[r'mimeType'] = this.mimeType;
    } else {
      json[r'mimeType'] = null;
    }
    if (this.checksumSha256 != null) {
      json[r'checksumSha256'] = this.checksumSha256;
    } else {
      json[r'checksumSha256'] = null;
    }
    if (this.integrityOk != null) {
      json[r'integrityOk'] = this.integrityOk;
    } else {
      json[r'integrityOk'] = null;
    }
    if (this.thumbnailUrl != null) {
      json[r'thumbnailUrl'] = this.thumbnailUrl;
    } else {
      json[r'thumbnailUrl'] = null;
    }
    if (this.thumbnailAttempted != null) {
      json[r'thumbnailAttempted'] = this.thumbnailAttempted;
    } else {
      json[r'thumbnailAttempted'] = null;
    }
    return json;
  }

  /// Returns a new [DocumentAuditDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DocumentAuditDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return DocumentAuditDto(
        documentId: mapValueOfType<int>(json, r'documentId'),
        auditId: mapValueOfType<int>(json, r'auditId'),
        sizeBytes: mapValueOfType<int>(json, r'sizeBytes'),
        mimeType: mapValueOfType<String>(json, r'mimeType'),
        checksumSha256: mapValueOfType<String>(json, r'checksumSha256'),
        integrityOk: mapValueOfType<bool>(json, r'integrityOk'),
        thumbnailUrl: mapValueOfType<String>(json, r'thumbnailUrl'),
        thumbnailAttempted: mapValueOfType<bool>(json, r'thumbnailAttempted'),
      );
    }
    return null;
  }

  static List<DocumentAuditDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DocumentAuditDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DocumentAuditDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DocumentAuditDto> mapFromJson(dynamic json) {
    final map = <String, DocumentAuditDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DocumentAuditDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DocumentAuditDto-objects as value to a dart map
  static Map<String, List<DocumentAuditDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DocumentAuditDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DocumentAuditDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

