//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class NotificationDTO {
  /// Returns a new [NotificationDTO] instance.
  NotificationDTO({
    this.id,
    this.title,
    this.body,
    this.type,
    this.topic,
    this.referenceId,
    this.actionUrl,
    this.actionLabel,
    this.severity,
    this.sender,
    this.sentAt,
    this.createdAt,
    this.read,
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
  String? title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? body;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? type;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? topic;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? referenceId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? actionUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? actionLabel;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? severity;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? sender;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  DateTime? sentAt;

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
  bool? read;

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationDTO &&
    other.id == id &&
    other.title == title &&
    other.body == body &&
    other.type == type &&
    other.topic == topic &&
    other.referenceId == referenceId &&
    other.actionUrl == actionUrl &&
    other.actionLabel == actionLabel &&
    other.severity == severity &&
    other.sender == sender &&
    other.sentAt == sentAt &&
    other.createdAt == createdAt &&
    other.read == read;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id == null ? 0 : id!.hashCode) +
    (title == null ? 0 : title!.hashCode) +
    (body == null ? 0 : body!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (topic == null ? 0 : topic!.hashCode) +
    (referenceId == null ? 0 : referenceId!.hashCode) +
    (actionUrl == null ? 0 : actionUrl!.hashCode) +
    (actionLabel == null ? 0 : actionLabel!.hashCode) +
    (severity == null ? 0 : severity!.hashCode) +
    (sender == null ? 0 : sender!.hashCode) +
    (sentAt == null ? 0 : sentAt!.hashCode) +
    (createdAt == null ? 0 : createdAt!.hashCode) +
    (read == null ? 0 : read!.hashCode);

  @override
  String toString() => 'NotificationDTO[id=$id, title=$title, body=$body, type=$type, topic=$topic, referenceId=$referenceId, actionUrl=$actionUrl, actionLabel=$actionLabel, severity=$severity, sender=$sender, sentAt=$sentAt, createdAt=$createdAt, read=$read]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.body != null) {
      json[r'body'] = this.body;
    } else {
      json[r'body'] = null;
    }
    if (this.type != null) {
      json[r'type'] = this.type;
    } else {
      json[r'type'] = null;
    }
    if (this.topic != null) {
      json[r'topic'] = this.topic;
    } else {
      json[r'topic'] = null;
    }
    if (this.referenceId != null) {
      json[r'referenceId'] = this.referenceId;
    } else {
      json[r'referenceId'] = null;
    }
    if (this.actionUrl != null) {
      json[r'actionUrl'] = this.actionUrl;
    } else {
      json[r'actionUrl'] = null;
    }
    if (this.actionLabel != null) {
      json[r'actionLabel'] = this.actionLabel;
    } else {
      json[r'actionLabel'] = null;
    }
    if (this.severity != null) {
      json[r'severity'] = this.severity;
    } else {
      json[r'severity'] = null;
    }
    if (this.sender != null) {
      json[r'sender'] = this.sender;
    } else {
      json[r'sender'] = null;
    }
    if (this.sentAt != null) {
      json[r'sentAt'] = this.sentAt!.toUtc().toIso8601String();
    } else {
      json[r'sentAt'] = null;
    }
    if (this.createdAt != null) {
      json[r'createdAt'] = this.createdAt!.toUtc().toIso8601String();
    } else {
      json[r'createdAt'] = null;
    }
    if (this.read != null) {
      json[r'read'] = this.read;
    } else {
      json[r'read'] = null;
    }
    return json;
  }

  /// Returns a new [NotificationDTO] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static NotificationDTO? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return NotificationDTO(
        id: mapValueOfType<int>(json, r'id'),
        title: mapValueOfType<String>(json, r'title'),
        body: mapValueOfType<String>(json, r'body'),
        type: mapValueOfType<String>(json, r'type'),
        topic: mapValueOfType<String>(json, r'topic'),
        referenceId: mapValueOfType<String>(json, r'referenceId'),
        actionUrl: mapValueOfType<String>(json, r'actionUrl'),
        actionLabel: mapValueOfType<String>(json, r'actionLabel'),
        severity: mapValueOfType<String>(json, r'severity'),
        sender: mapValueOfType<String>(json, r'sender'),
        sentAt: mapDateTime(json, r'sentAt', r''),
        createdAt: mapDateTime(json, r'createdAt', r''),
        read: mapValueOfType<bool>(json, r'read'),
      );
    }
    return null;
  }

  static List<NotificationDTO> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <NotificationDTO>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = NotificationDTO.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, NotificationDTO> mapFromJson(dynamic json) {
    final map = <String, NotificationDTO>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = NotificationDTO.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of NotificationDTO-objects as value to a dart map
  static Map<String, List<NotificationDTO>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<NotificationDTO>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = NotificationDTO.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

