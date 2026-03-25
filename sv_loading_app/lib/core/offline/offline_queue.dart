import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_models.dart';

class OfflineQueue {
  static const _key = 'offline_actions';

  Future<List<OfflineAction>> list() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key) ?? [];
    final actions =
        raw.map((s) => OfflineAction.fromJson(jsonDecode(s))).toList();
    actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return actions;
  }

  Future<void> add(OfflineAction action) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key) ?? [];
    raw.add(jsonEncode(action.toJson()));
    await sp.setStringList(_key, raw);
  }

  Future<void> removeById(String id) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList(_key) ?? [];
    raw.removeWhere((s) => jsonDecode(s)['id'] == id);
    await sp.setStringList(_key, raw);
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
