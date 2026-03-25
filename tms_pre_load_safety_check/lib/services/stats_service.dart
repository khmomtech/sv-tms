import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/safety_check.dart';

class StatsService extends ChangeNotifier {
  static const _boxName = 'safety_stats';
  static const _todayKey = 'stats_by_day';

  Box<dynamic>? _box;
  bool initialized = false;

  Future<void> init() async {
    if (initialized) return;
    _box ??= Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : await Hive.openBox(_boxName);
    initialized = true;
    notifyListeners();
  }

  Future<void> _ensureInit() async {
    if (!initialized) {
      await init();
    }
  }

  Map<String, dynamic> _getDay(String dayKey) {
    if (_box == null) return <String, dynamic>{};
    final raw = _box!.get(dayKey);
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  Future<void> recordResult(SafetyResult result) async {
    await _ensureInit();
    final dayKey = _currentDayKey();
    final map = _getDay(dayKey);
    final scanned = (map['scanned'] as int? ?? 0) + 1;
    final pass = (map['pass'] as int? ?? 0) + (result == SafetyResult.pass ? 1 : 0);
    final fail = (map['fail'] as int? ?? 0) + (result == SafetyResult.fail ? 1 : 0);
    await _box!.put(dayKey, {'scanned': scanned, 'pass': pass, 'fail': fail});
    notifyListeners();
  }

  Map<String, int> today() {
    final dayKey = _currentDayKey();
    final map = _getDay(dayKey);
    return {
      'scanned': map['scanned'] as int? ?? 0,
      'pass': map['pass'] as int? ?? 0,
      'fail': map['fail'] as int? ?? 0,
    };
  }

  String _currentDayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
