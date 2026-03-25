import 'package:intl/intl.dart';

enum SafetyResult { pass, fail }

SafetyResult? safetyResultFromString(String? value) {
  if (value == null) return null;
  return value.toUpperCase() == 'PASS' ? SafetyResult.pass : SafetyResult.fail;
}

class SafetyCheckRequest {
  SafetyCheckRequest({
    required this.dispatchId,
    required this.driverPpeOk,
    required this.fireExtinguisherOk,
    required this.wheelChockOk,
    required this.truckLeakageOk,
    required this.truckCleanOk,
    required this.truckConditionOk,
    required this.result,
    this.failReason,
    this.checkedAt,
    this.checkedByUserId,
    this.clientUuid,
  });

  final int dispatchId;
  final bool driverPpeOk;
  final bool fireExtinguisherOk;
  final bool wheelChockOk;
  final bool truckLeakageOk;
  final bool truckCleanOk;
  final bool truckConditionOk;
  final SafetyResult result;
  final String? failReason;
  final DateTime? checkedAt;
  final int? checkedByUserId;
  final String? clientUuid;

  Map<String, dynamic> toJson() {
    final String? checkedAtValue = checkedAt != null
        ? DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(checkedAt!.toLocal())
        : null;
    return {
      'dispatchId': dispatchId,
      'driverPpeOk': driverPpeOk,
      'fireExtinguisherOk': fireExtinguisherOk,
      'wheelChockOk': wheelChockOk,
      'truckLeakageOk': truckLeakageOk,
      'truckCleanOk': truckCleanOk,
      'truckConditionOk': truckConditionOk,
      'result': result.name.toUpperCase(),
      'failReason': failReason,
      if (checkedAtValue != null) 'checkedAt': checkedAtValue,
      if (checkedByUserId != null) 'checkedByUserId': checkedByUserId,
      if (clientUuid != null && clientUuid!.isNotEmpty)
        'clientUuid': clientUuid,
    };
  }
}

class PreLoadingSafetyCheck {
  PreLoadingSafetyCheck({
    required this.id,
    required this.dispatchId,
    required this.result,
    required this.driverPpeOk,
    required this.fireExtinguisherOk,
    required this.wheelChockOk,
    required this.truckLeakageOk,
    required this.truckCleanOk,
    required this.truckConditionOk,
    this.failReason,
    this.checkedByName,
    this.checkedAt,
    this.createdDate,
    this.dispatchStatusAfterCheck,
    this.autoTransitionApplied,
    this.transitionMessage,
  });

  final int id;
  final int dispatchId;
  final SafetyResult result;
  final bool driverPpeOk;
  final bool fireExtinguisherOk;
  final bool wheelChockOk;
  final bool truckLeakageOk;
  final bool truckCleanOk;
  final bool truckConditionOk;
  final String? failReason;
  final String? checkedByName;
  final DateTime? checkedAt;
  final DateTime? createdDate;
  final String? dispatchStatusAfterCheck;
  final bool? autoTransitionApplied;
  final String? transitionMessage;

  factory PreLoadingSafetyCheck.fromJson(Map<String, dynamic> json) {
    return PreLoadingSafetyCheck(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      dispatchId: json['dispatchId'] is int
          ? json['dispatchId'] as int
          : int.parse(json['dispatchId'].toString()),
      result: safetyResultFromString(json['result']) ?? SafetyResult.fail,
      driverPpeOk: json['driverPpeOk'] == true,
      fireExtinguisherOk: json['fireExtinguisherOk'] == true,
      wheelChockOk: json['wheelChockOk'] == true,
      truckLeakageOk: json['truckLeakageOk'] == true,
      truckCleanOk: json['truckCleanOk'] == true,
      truckConditionOk: json['truckConditionOk'] == true,
      failReason: json['failReason']?.toString(),
      checkedByName:
          (json['checkedByName'] ?? json['checkedByUsername'])?.toString(),
      checkedAt: json['checkedAt'] != null
          ? DateTime.parse(json['checkedAt'].toString())
          : null,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'].toString())
          : null,
      dispatchStatusAfterCheck: json['dispatchStatusAfterCheck']?.toString(),
      autoTransitionApplied: json['autoTransitionApplied'] == true,
      transitionMessage: json['transitionMessage']?.toString(),
    );
  }

  String formattedTimestamp() {
    final ts = checkedAt ?? createdDate;
    if (ts == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(ts);
  }
}
