// lib/setup_guard.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Simple utility to remember if the driver has already
/// completed the one-time setup (permissions, battery, etc.)
class SetupGuard {
  static const _doneKey = 'driver_setup_done';

  /// Returns true if setup was already completed.
  static Future<bool> isDone() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_doneKey) ?? false;
  }

  /// Marks setup as done so the app can skip it next time.
  static Future<void> markDone() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_doneKey, true);
  }

  /// Clears the flag (e.g. for testing)
  static Future<void> reset() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_doneKey);
  }
}
