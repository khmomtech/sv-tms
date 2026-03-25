import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/pending_submission.dart';
import '../models/safety_check.dart';
import 'safety_service.dart';

class PendingQueueService extends ChangeNotifier {
  static const _boxName = 'pending_checks';
  Box<dynamic>? _box;
  bool initialized = false;

  Future<void> init() async {
    if (initialized) return;
    _box ??= Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    initialized = true;
    notifyListeners();
  }

  Future<void> enqueue(SafetyCheckRequest request, {List<String>? photoPaths}) async {
    await init();
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    final submission = PendingSafetySubmission(
      key: key,
      request: request,
      photoPaths: photoPaths ?? const [],
      createdAt: DateTime.now(),
    );
    await _box!.put(key, submission.toJson());
    notifyListeners();
  }

  List<PendingSafetySubmission> getPending() {
    if (_box == null) return <PendingSafetySubmission>[];
    return _box!.values
        .whereType<Map>()
        .map((map) => PendingSafetySubmission.fromJson(Map<String, dynamic>.from(map)))
        .toList();
  }

  Future<int> retryPending(SafetyService service, {dynamic stats}) async {
    await init();
    final pending = getPending();
    int success = 0;
    for (final submission in pending) {
      try {
        await service.submitSafetyCheck(
          submission.request,
          photoPaths: submission.photoPaths,
        );
        try {
          if (stats != null) {
            await stats.recordResult(submission.request.result);
          }
        } catch (_) {}
        await _box!.delete(submission.key);
        success++;
      } catch (_) {
        // keep it for next retry
      }
    }
    if (success > 0) notifyListeners();
    return success;
  }

  Future<void> clearAll() async {
    await init();
    await _box?.clear();
    notifyListeners();
  }
}
