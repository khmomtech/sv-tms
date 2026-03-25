import 'dart:convert';

class SafetyCheck {
  int? id;
  DateTime? checkDate;
  String? shift;
  int? driverId;
  int? vehicleId;
  String? status;
  String? riskLevel;
  String? riskOverride;
  DateTime? submittedAt;
  DateTime? approvedAt;
  int? approvedBy;
  String? rejectReason;
  String? notes;
  double? gpsLat;
  double? gpsLng;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<SafetyCheckItem> items;
  List<SafetyCheckAttachment> attachments;
  List<SafetyCheckAudit> audits;

  SafetyCheck({
    this.id,
    this.checkDate,
    this.shift,
    this.driverId,
    this.vehicleId,
    this.status,
    this.riskLevel,
    this.riskOverride,
    this.submittedAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectReason,
    this.notes,
    this.gpsLat,
    this.gpsLng,
    this.createdAt,
    this.updatedAt,
    List<SafetyCheckItem>? items,
    List<SafetyCheckAttachment>? attachments,
    List<SafetyCheckAudit>? audits,
  })  : items = items ?? [],
        attachments = attachments ?? [],
        audits = audits ?? [];

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return null;
      if (s.length == 10) {
        return DateTime.tryParse('${s}T00:00:00');
      }
      return DateTime.tryParse(s.contains('T') ? s : s.replaceFirst(' ', 'T'));
    }
    if (raw is List) {
      final list = raw.cast<num>();
      if (list.length >= 3) {
        final y = list[0].toInt();
        final m = list[1].toInt();
        final d = list[2].toInt();
        final hh = list.length > 3 ? list[3].toInt() : 0;
        final mm = list.length > 4 ? list[4].toInt() : 0;
        final ss = list.length > 5 ? list[5].toInt() : 0;
        return DateTime(y, m, d, hh, mm, ss);
      }
    }
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (raw is double) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    return null;
  }

  static SafetyCheck fromJson(Map<String, dynamic> json) {
    final mappedNotes = json['notes'] ?? json['note'] ?? json['safetyNote'];
    return SafetyCheck(
      id: (json['id'] as num?)?.toInt(),
      checkDate: _parseDate(json['checkDate'] ?? json['check_date']),
      shift: json['shift']?.toString(),
      driverId: (json['driverId'] as num?)?.toInt() ??
          (json['driver_id'] as num?)?.toInt(),
      vehicleId: (json['vehicleId'] as num?)?.toInt() ??
          (json['vehicle_id'] as num?)?.toInt(),
      status: json['status']?.toString(),
      riskLevel:
          json['riskLevel']?.toString() ?? json['risk_level']?.toString(),
      riskOverride:
          json['riskOverride']?.toString() ?? json['risk_override']?.toString(),
      submittedAt: _parseDate(json['submittedAt']),
      approvedAt: _parseDate(json['approvedAt']),
      approvedBy: (json['approvedBy'] as num?)?.toInt(),
      rejectReason: json['rejectReason']?.toString(),
      notes: mappedNotes?.toString(),
      gpsLat: (json['gpsLat'] as num?)?.toDouble(),
      gpsLng: (json['gpsLng'] as num?)?.toDouble(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      items: (json['items'] as List?)
              ?.map(
                  (e) => SafetyCheckItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      attachments: (json['attachments'] as List?)
              ?.map((e) =>
                  SafetyCheckAttachment.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      audits: (json['audits'] as List?)
              ?.map((e) =>
                  SafetyCheckAudit.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checkDate': _formatDate(checkDate),
      'shift': shift,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'status': status,
      'riskLevel': riskLevel,
      'riskOverride': riskOverride,
      'submittedAt': submittedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'rejectReason': rejectReason,
      'notes': notes,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String toDraftJsonString() => jsonEncode(toJson());
}

class SafetyCheckItem {
  int? id;
  String category;
  String? categoryLabelKm;
  String itemKey;
  String? itemLabelKm;
  String? result;
  String? severity;
  String? remark;

  SafetyCheckItem({
    this.id,
    required this.category,
    this.categoryLabelKm,
    required this.itemKey,
    this.itemLabelKm,
    this.result,
    this.severity,
    this.remark,
  });

  factory SafetyCheckItem.fromJson(Map<String, dynamic> json) {
    return SafetyCheckItem(
      id: (json['id'] as num?)?.toInt(),
      category: json['category']?.toString() ?? '',
      categoryLabelKm: json['categoryLabelKm']?.toString(),
      itemKey: json['itemKey']?.toString() ?? '',
      itemLabelKm: json['itemLabelKm']?.toString(),
      result: json['result']?.toString(),
      severity: json['severity']?.toString(),
      remark: json['remark']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'categoryLabelKm': categoryLabelKm,
      'itemKey': itemKey,
      'itemLabelKm': itemLabelKm,
      'result': result,
      'severity': severity,
      'remark': remark,
    };
  }
}

class SafetyCheckAttachment {
  int? id;
  int? itemId;
  String? fileUrl;
  String? fileName;
  String? mimeType;
  DateTime? createdAt;

  SafetyCheckAttachment({
    this.id,
    this.itemId,
    this.fileUrl,
    this.fileName,
    this.mimeType,
    this.createdAt,
  });

  factory SafetyCheckAttachment.fromJson(Map<String, dynamic> json) {
    return SafetyCheckAttachment(
      id: (json['id'] as num?)?.toInt(),
      itemId: (json['itemId'] as num?)?.toInt(),
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
      mimeType: json['mimeType']?.toString(),
      createdAt: SafetyCheck._parseDate(json['createdAt']),
    );
  }
}

class SafetyCheckAudit {
  int? id;
  String? action;
  String? actorRole;
  String? message;
  DateTime? createdAt;

  SafetyCheckAudit({
    this.id,
    this.action,
    this.actorRole,
    this.message,
    this.createdAt,
  });

  factory SafetyCheckAudit.fromJson(Map<String, dynamic> json) {
    return SafetyCheckAudit(
      id: (json['id'] as num?)?.toInt(),
      action: json['action']?.toString(),
      actorRole: json['actorRole']?.toString(),
      message: json['message']?.toString(),
      createdAt: SafetyCheck._parseDate(json['createdAt']),
    );
  }
}

class PendingSafetyAttachment {
  final String filePath;
  final int? itemId;
  int? safetyCheckId;

  PendingSafetyAttachment({
    required this.filePath,
    this.itemId,
    this.safetyCheckId,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'itemId': itemId,
        'safetyCheckId': safetyCheckId,
      };

  factory PendingSafetyAttachment.fromJson(Map<String, dynamic> json) {
    return PendingSafetyAttachment(
      filePath: json['filePath']?.toString() ?? '',
      itemId: (json['itemId'] as num?)?.toInt(),
      safetyCheckId: (json['safetyCheckId'] as num?)?.toInt(),
    );
  }
}
