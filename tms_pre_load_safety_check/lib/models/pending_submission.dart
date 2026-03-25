import 'package:intl/intl.dart';

import 'safety_check.dart';

class PendingSafetySubmission {
  PendingSafetySubmission({
    required this.key,
    required this.request,
    required this.photoPaths,
    required this.createdAt,
  });

  final String key;
  final SafetyCheckRequest request;
  final List<String> photoPaths;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'dispatchId': request.dispatchId,
      'driverPpeOk': request.driverPpeOk,
      'fireExtinguisherOk': request.fireExtinguisherOk,
      'wheelChockOk': request.wheelChockOk,
      'truckLeakageOk': request.truckLeakageOk,
      'truckCleanOk': request.truckCleanOk,
      'truckConditionOk': request.truckConditionOk,
      'result': request.result.name,
      'failReason': request.failReason,
      'photoPaths': photoPaths,
      'createdAt': createdAt.toIso8601String(),
      'checkedAt': request.checkedAt != null
          ? DateFormat("yyyy-MM-dd'T'HH:mm:ss")
              .format(request.checkedAt!.toLocal())
          : null,
      'checkedByUserId': request.checkedByUserId,
      'clientUuid': request.clientUuid,
    };
  }

  factory PendingSafetySubmission.fromJson(Map<String, dynamic> json) {
    List<String> parsePhotos(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      if (raw is String && raw.isNotEmpty) {
        return [raw];
      }
      return <String>[];
    }

    return PendingSafetySubmission(
      key: json['key']?.toString() ?? '',
      request: SafetyCheckRequest(
        dispatchId: int.parse(json['dispatchId'].toString()),
        driverPpeOk: json['driverPpeOk'] == true,
        fireExtinguisherOk: json['fireExtinguisherOk'] == true,
        wheelChockOk: json['wheelChockOk'] == true,
        truckLeakageOk: json['truckLeakageOk'] == true,
        truckCleanOk: json['truckCleanOk'] == true,
        truckConditionOk: json['truckConditionOk'] == true,
        result: (json['result']?.toString().toLowerCase() == 'pass')
            ? SafetyResult.pass
            : SafetyResult.fail,
        failReason: json['failReason']?.toString(),
        checkedAt: json['checkedAt'] != null
            ? DateTime.tryParse(json['checkedAt'].toString())
            : null,
        checkedByUserId: json['checkedByUserId'] != null
            ? int.tryParse(json['checkedByUserId'].toString())
            : null,
        clientUuid: json['clientUuid']?.toString(),
      ),
      photoPaths: parsePhotos(json['photoPaths'] ?? json['photoPath']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
