import 'dart:typed_data';

/// All supported message types — kept in sync with backend DriverChatMessageType enum.
class MessageType {
  static const String text = 'TEXT';
  static const String image = 'IMAGE';
  static const String voice = 'VOICE';
  static const String video = 'VIDEO';
  static const String location = 'LOCATION';
  static const String callRequest = 'CALL_REQUEST';
  static const String callAccepted = 'CALL_ACCEPTED';
  static const String callDeclined = 'CALL_DECLINED';
  static const String callEnded = 'CALL_ENDED';
  static const String typing = 'TYPING';
}

class ChatMessageModel {
  final int? id;
  final int? driverId;
  final String senderRole;
  final String sender;
  final String message;

  /// Discriminator: TEXT | IMAGE | VOICE | VIDEO | LOCATION |
  ///                CALL_REQUEST | CALL_ACCEPTED | CALL_DECLINED | CALL_ENDED | TYPING
  final String? messageType;

  final DateTime? createdAt;

  // ── Local-only fields (never serialised to/from JSON) ─────────────────────
  final Uint8List? localImageBytes;
  final bool isPending;
  bool read;

  // ── Agora call session fields ──────────────────────────────────────────────
  /// Agora channel name for CALL_REQUEST / CALL_ACCEPTED messages.
  final String? agoraChannelName;

  /// Back-end call session identifier.
  final String? callSessionId;

  ChatMessageModel({
    this.id,
    this.driverId,
    required this.senderRole,
    required this.sender,
    required this.message,
    this.messageType,
    this.createdAt,
    this.localImageBytes,
    this.isPending = false,
    this.read = false,
    this.agoraChannelName,
    this.callSessionId,
  });

  // ─── Parsing ────────────────────────────────────────────────────────────────

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return null;
      if (s.length == 10) return DateTime.tryParse('${s}T00:00:00');
      return DateTime.tryParse(s.contains('T') ? s : s.replaceFirst(' ', 'T'));
    }
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    if (raw is List) {
      final list = raw.cast<num>();
      if (list.length >= 6) {
        return DateTime(
          list[0].toInt(), list[1].toInt(), list[2].toInt(),
          list[3].toInt(), list[4].toInt(), list[5].toInt(),
        );
      }
    }
    return null;
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] as num?)?.toInt(),
      driverId: (json['driverId'] as num?)?.toInt() ??
          (json['driver_id'] as num?)?.toInt(),
      senderRole: json['senderRole']?.toString() ??
          json['sender_role']?.toString() ??
          'UNKNOWN',
      sender: json['sender']?.toString() ?? 'Unknown',
      message: json['message']?.toString() ?? '',
      messageType:
          json['messageType']?.toString() ?? json['message_type']?.toString(),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      localImageBytes: null,
      isPending: false,
      read: json['read'] == true ||
          json['isRead'] == true ||
          json['is_read'] == true,
      agoraChannelName: json['agoraChannelName']?.toString() ??
          json['agora_channel_name']?.toString(),
      callSessionId: json['callSessionId']?.toString() ??
          json['call_session_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (driverId != null) 'driverId': driverId,
        'senderRole': senderRole,
        'sender': sender,
        'message': message,
        if (messageType != null) 'messageType': messageType,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        'read': read,
        if (agoraChannelName != null) 'agoraChannelName': agoraChannelName,
        if (callSessionId != null) 'callSessionId': callSessionId,
      };

  // ─── Convenience predicates ─────────────────────────────────────────────────

  bool get isCallRequest =>
      messageType == MessageType.callRequest || message.contains('📞');

  bool get isCallAccepted => messageType == MessageType.callAccepted;

  bool get isCallDeclined => messageType == MessageType.callDeclined;

  bool get isCallEnded => messageType == MessageType.callEnded;

  bool get isCallSignal =>
      isCallRequest || isCallAccepted || isCallDeclined || isCallEnded;

  bool get isTypingIndicator => messageType == MessageType.typing;

  bool get isFromAdmin => !senderRole.toUpperCase().contains('DRIVER');

  bool get isVoice => messageType == MessageType.voice;

  bool get isImage => messageType == MessageType.image;

  bool get isVideo => messageType == MessageType.video;

  bool get isLocation => messageType == MessageType.location;

  // ─── copyWith ───────────────────────────────────────────────────────────────

  ChatMessageModel copyWith({
    int? id,
    int? driverId,
    String? senderRole,
    String? sender,
    String? message,
    String? messageType,
    DateTime? createdAt,
    Uint8List? localImageBytes,
    bool? isPending,
    bool? read,
    String? agoraChannelName,
    String? callSessionId,
  }) =>
      ChatMessageModel(
        id: id ?? this.id,
        driverId: driverId ?? this.driverId,
        senderRole: senderRole ?? this.senderRole,
        sender: sender ?? this.sender,
        message: message ?? this.message,
        messageType: messageType ?? this.messageType,
        createdAt: createdAt ?? this.createdAt,
        localImageBytes: localImageBytes ?? this.localImageBytes,
        isPending: isPending ?? this.isPending,
        read: read ?? this.read,
        agoraChannelName: agoraChannelName ?? this.agoraChannelName,
        callSessionId: callSessionId ?? this.callSessionId,
      );
}
