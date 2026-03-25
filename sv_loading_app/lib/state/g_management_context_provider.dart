import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GManagementContextProvider extends ChangeNotifier {
  static const _dispatchIdKey = 'gmg_active_dispatch_id';
  static const _queueIdKey = 'gmg_active_queue_id';
  static const _sessionIdKey = 'gmg_active_session_id';
  static const _warehouseKey = 'gmg_selected_warehouse';

  int? activeDispatchId;
  int? activeQueueId;
  int? activeSessionId;
  String selectedWarehouse = 'ALL';
  bool isReady = false;

  GManagementContextProvider() {
    _restore();
  }

  Future<void> _restore() async {
    final sp = await SharedPreferences.getInstance();
    activeDispatchId = sp.getInt(_dispatchIdKey);
    activeQueueId = sp.getInt(_queueIdKey);
    activeSessionId = sp.getInt(_sessionIdKey);
    selectedWarehouse = sp.getString(_warehouseKey) ?? 'ALL';
    isReady = true;
    notifyListeners();
  }

  Future<void> setActiveDispatchId(int? id) async {
    activeDispatchId = id;
    final sp = await SharedPreferences.getInstance();
    if (id == null) {
      await sp.remove(_dispatchIdKey);
    } else {
      await sp.setInt(_dispatchIdKey, id);
    }
    notifyListeners();
  }

  Future<void> setActiveQueueId(int? id) async {
    activeQueueId = id;
    final sp = await SharedPreferences.getInstance();
    if (id == null) {
      await sp.remove(_queueIdKey);
    } else {
      await sp.setInt(_queueIdKey, id);
    }
    notifyListeners();
  }

  Future<void> setActiveSessionId(int? id) async {
    activeSessionId = id;
    final sp = await SharedPreferences.getInstance();
    if (id == null) {
      await sp.remove(_sessionIdKey);
    } else {
      await sp.setInt(_sessionIdKey, id);
    }
    notifyListeners();
  }

  Future<void> setWarehouse(String warehouse) async {
    final normalized = warehouse.trim().toUpperCase();
    if (normalized.isEmpty) return;
    selectedWarehouse = normalized;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_warehouseKey, selectedWarehouse);
    notifyListeners();
  }

  Future<void> clear() async {
    activeDispatchId = null;
    activeQueueId = null;
    activeSessionId = null;
    selectedWarehouse = 'ALL';
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_dispatchIdKey);
    await sp.remove(_queueIdKey);
    await sp.remove(_sessionIdKey);
    await sp.remove(_warehouseKey);
    notifyListeners();
  }
}
