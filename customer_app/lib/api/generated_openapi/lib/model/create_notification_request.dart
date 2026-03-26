//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateNotificationRequest {
  /// Returns a new [CreateNotificationRequest] instance.
  CreateNotificationRequest({
    this.driverId,
    this.title,
    this.message,
    this.type,
    this.topic,
    this.referenceId,
    this.actionUrl,
    this.actionLabel,
    this.severity,
    this.sender,
  });

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
  String? title;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? message;

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

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateNotificationRequest &&
    other.driverId == driverId &&
    other.title == title &&
    other.message == message &&
    other.type == type &&
    other.topic == topic &&
    other.referenceId == referenceId &&
    other.actionUrl == actionUrl &&
    other.actionLabel == actionLabel &&
    other.severity == severity &&
    other.sender == sender;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (driverId == null ? 0 : driverId!.hashCode) +
    (title == null ? 0 : title!.hashCode) +
    (message == null ? 0 : message!.hashCode) +
    (type == null ? 0 : type!.hashCode) +
    (topic == null ? 0 : topic!.hashCode) +
    (referenceId == null ? 0 : referenceId!.hashCode) +
    (actionUrl == null ? 0 : actionUrl!.hashCode) +
    (actionLabel == null ? 0 : actionLabel!.hashCode) +
    (severity == null ? 0 : severity!.hashCode) +
    (sender == null ? 0 : sender!.hashCode);

  @override
  String toString() => 'CreateNotificationRequest[driverId=$driverId, title=$title, message=$message, type=$type, topic=$topic, referenceId=$referenceId, actionUrl=$actionUrl, actionLabel=$actionLabel, severity=$severity, sender=$sender]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.driverId != null) {
      json[r'driverId'] = this.driverId;
    } else {
      json[r'driverId'] = null;
    }
    if (this.title != null) {
      json[r'title'] = this.title;
    } else {
      json[r'title'] = null;
    }
    if (this.message != null) {
      json[r'message'] = this.message;
    } else {
      json[r'message'] = null;
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
    return json;
  }

  /// Returns a new [CreateNotificationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateNotificationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        return true;
      }());

      return CreateNotificationRequest(
        driverId: mapValueOfType<int>(json, r'driverId'),
        title: mapValueOfType<String>(json, r'title'),
        message: mapValueOfType<String>(json, r'message'),
        type: mapValueOfType<String>(json, r'type'),
        topic: mapValueOfType<String>(json, r'topic'),
        referenceId: mapValueOfType<String>(json, r'referenceId'),
        actionUrl: mapValueOfType<String>(json, r'actionUrl'),
        actionLabel: mapValueOfType<String>(json, r'actionLabel'),
        severity: mapValueOfType<String>(json, r'severity'),
        sender: mapValueOfType<String>(json, r'sender'),
      );
    }
    return null;
  }

  static List<CreateNotificationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateNotificationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateNotificationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateNotificationRequest> mapFromJson(dynamic json) {
    final map = <String, CreateNotificationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateNotificationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateNotificationRequest-objects as value to a dart map
  static Map<String, List<CreateNotificationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateNotificationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateNotificationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

