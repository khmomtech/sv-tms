import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/api/api_client.dart';
import '../core/api/api_data.dart';
import '../core/api/api_error.dart';
import '../core/api/endpoints.dart';
import '../core/offline/offline_models.dart';
import '../core/offline/offline_queue.dart';

class OfflineSyncResult {
  final int processed;
  final int succeeded;
  final int failed;
  final String? firstError;

  const OfflineSyncResult({
    required this.processed,
    required this.succeeded,
    required this.failed,
    this.firstError,
  });
}

class LoadingProvider extends ChangeNotifier {
  static const _queueIdKey = 'current_queue_id';
  static const _sessionIdKey = 'current_session_id';
  final ApiClient api;
  final OfflineQueue offlineQueue = OfflineQueue();
  final uuid = const Uuid();

  bool isLoading = false;
  String? error;
  String? lastMessage;
  int? currentQueueId;
  int? currentSessionId;
  List<Map<String, dynamic>> stagedPalletItems = [];
  List<Map<String, dynamic>> stagedEmptiesReturns = [];
  List<Map<String, dynamic>> monitorQueue = [];
  Map<String, dynamic>? monitorDispatchDetail;
  OfflineSyncResult? syncResult;

  LoadingProvider(this.api) {
    _restoreContext();
  }

  Future<void> _enqueue(
      OfflineActionType type, Map<String, dynamic> payload) async {
    await offlineQueue.add(OfflineAction(
      id: uuid.v4(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    ));
    lastMessage = 'offline';
    notifyListeners();
  }

  Future<void> submitGateCheck(Map<String, dynamic> payload,
      {required bool online}) async {
    if (!online) return _enqueue(OfflineActionType.gateCheck, payload);
    await _post(Endpoints.preEntrySafetySubmit, payload);
  }

  Future<void> registerQueue(Map<String, dynamic> payload,
      {required bool online}) async {
    final dispatchId = asInt(payload['dispatchId']);
    if (dispatchId == null) {
      error = 'Dispatch ID is required for queue registration.';
      notifyListeners();
      return;
    }
    if (!online) return _enqueue(OfflineActionType.queueRegister, payload);
    await _post(Endpoints.loadingQueue, payload, onData: (data) {
      currentQueueId = asInt(data['id']);
      _persistContext();
    });
  }

  Future<void> startLoading(Map<String, dynamic> payload,
      {required bool online}) async {
    final dispatchId = asInt(payload['dispatchId']);
    if (dispatchId == null) {
      error = 'Dispatch ID is required to start loading.';
      notifyListeners();
      return;
    }
    final queueId = asInt(payload['queueId']) ?? currentQueueId;
    if (queueId == null) {
      error = 'Queue context is required before starting loading.';
      notifyListeners();
      return;
    }
    final completePayload = Map<String, dynamic>.from(payload);
    completePayload['queueId'] = queueId;
    if (!online) {
      return _enqueue(OfflineActionType.startLoading, completePayload);
    }
    await _post(Endpoints.loadingSessionStart, completePayload, onData: (data) {
      currentSessionId = asInt(data['id']);
      currentQueueId ??= asInt(data['queueId']);
      _persistContext();
    });
  }

  Future<void> endLoading(Map<String, dynamic> payload,
      {required bool online}) async {
    final completePayload = Map<String, dynamic>.from(payload);
    completePayload['sessionId'] =
        asInt(payload['sessionId']) ?? currentSessionId;
    completePayload['palletItems'] =
        (payload['palletItems'] as List?)?.cast<Map<String, dynamic>>() ??
            stagedPalletItems;
    completePayload['emptiesReturns'] =
        (payload['emptiesReturns'] as List?)?.cast<Map<String, dynamic>>() ??
            stagedEmptiesReturns;
    if (asInt(completePayload['sessionId']) == null) {
      error = 'Session ID is required to complete loading.';
      notifyListeners();
      return;
    }
    if (!online) return _enqueue(OfflineActionType.endLoading, completePayload);
    await _put(Endpoints.loadingSessionComplete, completePayload);
  }

  Future<void> submitPallets(Map<String, dynamic> payload,
      {required bool online}) async {
    stagedPalletItems =
        List<Map<String, dynamic>>.from(payload['items'] ?? const []);
    lastMessage = online ? 'staged' : 'offline';
    notifyListeners();
    if (!online) {
      await _enqueue(OfflineActionType.pallets, payload);
    }
  }

  Future<void> submitEmpties(Map<String, dynamic> payload,
      {required bool online}) async {
    stagedEmptiesReturns =
        List<Map<String, dynamic>>.from(payload['items'] ?? const []);
    lastMessage = online ? 'staged' : 'offline';
    notifyListeners();
    if (!online) {
      await _enqueue(OfflineActionType.empties, payload);
    }
  }

  Future<void> uploadDocs({
    required int sessionId,
    required String documentType,
    required List<File> files,
    required Map<String, dynamic> extra,
    required bool online,
  }) async {
    if (!online) {
      final payload = {
        'sessionId': sessionId,
        'documentType': documentType,
        'files': files.map((f) => f.path).toList(),
        'extra': extra,
      };
      return _enqueue(OfflineActionType.uploadDoc, payload);
    }

    isLoading = true;
    error = null;
    lastMessage = null;
    notifyListeners();
    try {
      for (final f in files) {
        final form = FormData();
        form.fields.add(MapEntry('documentType', documentType));
        extra.forEach((k, v) => form.fields.add(MapEntry(k, v.toString())));
        form.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(f.path,
              filename: f.uri.pathSegments.last),
        ));
        await api.dio.post(Endpoints.loadingSessionUploadDocument(sessionId),
            data: form);
      }
      lastMessage = 'uploaded';
    } on DioException catch (e) {
      error = parseApiError(e).message;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncOffline() async {
    isLoading = true;
    error = null;
    lastMessage = null;
    syncResult = null;
    notifyListeners();

    final actions = await offlineQueue.list();
    var succeeded = 0;
    var failed = 0;
    String? firstError;

    for (final a in actions) {
      try {
        switch (a.type) {
          case OfflineActionType.gateCheck:
            await api.dio.post(Endpoints.preEntrySafetySubmit, data: a.payload);
            break;
          case OfflineActionType.queueRegister:
            final res =
                await api.dio.post(Endpoints.loadingQueue, data: a.payload);
            currentQueueId = asInt(unwrapData(res.data)['id']);
            await _persistContext();
            break;
          case OfflineActionType.startLoading:
            final res = await api.dio
                .post(Endpoints.loadingSessionStart, data: a.payload);
            currentSessionId = asInt(unwrapData(res.data)['id']);
            await _persistContext();
            break;
          case OfflineActionType.endLoading:
            await api.dio
                .put(Endpoints.loadingSessionComplete, data: a.payload);
            break;
          case OfflineActionType.pallets:
            stagedPalletItems =
                List<Map<String, dynamic>>.from(a.payload['items'] ?? const []);
            break;
          case OfflineActionType.empties:
            stagedEmptiesReturns =
                List<Map<String, dynamic>>.from(a.payload['items'] ?? const []);
            break;
          case OfflineActionType.uploadDoc:
            final sessionId = asInt(a.payload['sessionId']);
            if (sessionId == null) break;
            final docType = a.payload['documentType']?.toString() ?? 'OTHER';
            final filePaths =
                (a.payload['files'] as List).map((e) => e.toString()).toList();
            final extra = Map<String, dynamic>.from(a.payload['extra'] ?? {});
            for (final p in filePaths) {
              final f = File(p);
              if (!await f.exists()) continue;
              final form = FormData();
              form.fields.add(MapEntry('documentType', docType));
              extra.forEach(
                  (k, v) => form.fields.add(MapEntry(k, v.toString())));
              form.files.add(MapEntry(
                'file',
                await MultipartFile.fromFile(f.path,
                    filename: f.uri.pathSegments.last),
              ));
              await api.dio.post(
                  Endpoints.loadingSessionUploadDocument(sessionId),
                  data: form);
            }
            break;
        }
        await offlineQueue.removeById(a.id);
        succeeded += 1;
      } catch (e) {
        failed += 1;
        firstError ??= parseApiError(e).message;
        // keep it in queue
      }
    }

    isLoading = false;
    lastMessage = 'synced';
    syncResult = OfflineSyncResult(
      processed: actions.length,
      succeeded: succeeded,
      failed: failed,
      firstError: firstError,
    );
    notifyListeners();
  }

  Future<void> fetchQueueByWarehouse(String warehouseCode) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.dio.get(
        Endpoints.loadingQueue,
        queryParameters: {'warehouse': warehouseCode},
      );
      final body = res.data;
      monitorQueue = unwrapDataList(body);
    } on DioException catch (e) {
      error = parseApiError(e).message;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDispatchDetail(int dispatchId) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res =
          await api.dio.get(Endpoints.loadingDispatchDetail(dispatchId));
      monitorDispatchDetail = unwrapData(res.data);
      final sessionId = asInt(monitorDispatchDetail?['session']?['id']);
      if (sessionId != null) {
        currentSessionId = sessionId;
        await _persistContext();
      }
    } on DioException catch (e) {
      error = parseApiError(e).message;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _post(
    String path,
    Map<String, dynamic> payload, {
    void Function(Map<String, dynamic> data)? onData,
  }) async {
    isLoading = true;
    error = null;
    lastMessage = null;
    notifyListeners();
    try {
      final res = await api.dio.post(path, data: payload);
      onData?.call(unwrapData(res.data));
      lastMessage = 'ok';
    } on DioException catch (e) {
      error = parseApiError(e).message;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _put(String path, Map<String, dynamic> payload) async {
    isLoading = true;
    error = null;
    lastMessage = null;
    notifyListeners();
    try {
      await api.dio.put(path, data: payload);
      lastMessage = 'ok';
    } on DioException catch (e) {
      error = parseApiError(e).message;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreContext() async {
    final sp = await SharedPreferences.getInstance();
    currentQueueId = sp.getInt(_queueIdKey);
    currentSessionId = sp.getInt(_sessionIdKey);
    notifyListeners();
  }

  Future<void> _persistContext() async {
    final sp = await SharedPreferences.getInstance();
    if (currentQueueId != null) {
      await sp.setInt(_queueIdKey, currentQueueId!);
    } else {
      await sp.remove(_queueIdKey);
    }
    if (currentSessionId != null) {
      await sp.setInt(_sessionIdKey, currentSessionId!);
    } else {
      await sp.remove(_sessionIdKey);
    }
  }
}
