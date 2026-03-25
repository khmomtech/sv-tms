enum OfflineActionType {
  gateCheck,
  queueRegister,
  startLoading,
  endLoading,
  pallets,
  empties,
  uploadDoc,
}

class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  static OfflineAction fromJson(Map<String, dynamic> json) => OfflineAction(
        id: json['id'],
        type:
            OfflineActionType.values.firstWhere((e) => e.name == json['type']),
        payload: Map<String, dynamic>.from(json['payload']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}
