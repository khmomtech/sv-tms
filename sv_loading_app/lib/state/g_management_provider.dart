import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_data.dart';
import '../core/api/api_error.dart';
import '../core/api/endpoints.dart';
import 'g_management_context_provider.dart';

class DispatchMonitorFilter {
  String? status;
  String? driverName;
  String? routeCode;
  String? customerName;
  String? destinationTo;
  String? truckPlate;
  String? tripNo;
  DateTime? startDate;
  DateTime? endDate;
  int page;
  int size;

  DispatchMonitorFilter({
    this.status,
    this.driverName,
    this.routeCode,
    this.customerName,
    this.destinationTo,
    this.truckPlate,
    this.tripNo,
    this.startDate,
    this.endDate,
    this.page = 0,
    this.size = 20,
  });
}

class SafetyChecklistSubmission {
  final int dispatchId;
  final int vehicleId;
  final int driverId;
  final String warehouseCode;
  final String remarks;
  final List<Map<String, dynamic>> items;

  const SafetyChecklistSubmission({
    required this.dispatchId,
    required this.vehicleId,
    required this.driverId,
    required this.warehouseCode,
    required this.remarks,
    required this.items,
  });

  Map<String, dynamic> toPayload() {
    return {
      'dispatchId': dispatchId,
      'vehicleId': vehicleId,
      'driverId': driverId,
      'warehouseCode': warehouseCode,
      'remarks': remarks,
      'items': items,
    };
  }
}

class GManagementProvider extends ChangeNotifier {
  final ApiClient api;
  final GManagementContextProvider context;

  bool isLoading = false;
  String? error;
  Map<String, String> fieldErrors = const {};
  String? requestId;

  DispatchMonitorFilter monitorFilter = DispatchMonitorFilter();
  List<Map<String, dynamic>> monitorRows = [];
  int totalPages = 0;
  Map<int, List<Map<String, dynamic>>> actionByDispatch = {};
  Map<int, String> rowErrors = {};

  List<Map<String, dynamic>> safetyRows = [];
  Map<String, dynamic>? safetyDetail;

  List<Map<String, dynamic>> queueRows = [];
  Map<String, dynamic>? loadingDispatchDetail;

  GManagementProvider(this.api, this.context);

  void clearError() {
    error = null;
    fieldErrors = const {};
    requestId = null;
    notifyListeners();
  }

  Future<void> fetchDispatches({DispatchMonitorFilter? filter}) async {
    if (filter != null) {
      monitorFilter = filter;
    }
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      final query = <String, dynamic>{
        'page': monitorFilter.page,
        'size': monitorFilter.size,
      };
      _putIfNotEmpty(query, 'status', monitorFilter.status);
      _putIfNotEmpty(query, 'driverName', monitorFilter.driverName);
      _putIfNotEmpty(query, 'routeCode', monitorFilter.routeCode);
      _putIfNotEmpty(query, 'customerName', monitorFilter.customerName);
      _putIfNotEmpty(query, 'destinationTo', monitorFilter.destinationTo);
      _putIfNotEmpty(query, 'truckPlate', monitorFilter.truckPlate);
      _putIfNotEmpty(query, 'tripNo', monitorFilter.tripNo);
      if (monitorFilter.startDate != null) {
        query['start'] = monitorFilter.startDate!.toIso8601String();
      }
      if (monitorFilter.endDate != null) {
        query['end'] = monitorFilter.endDate!.toIso8601String();
      }

      final res = await api.dio
          .get(Endpoints.adminDispatchesFilter, queryParameters: query);
      final data = unwrapData(res.data);
      final content = data['content'];
      if (content is List) {
        monitorRows = content
            .whereType<Map>()
            .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
            .toList();
      } else {
        monitorRows = [];
      }
      totalPages = asInt(data['totalPages']) ?? 0;
      rowErrors = {};
      actionByDispatch = {};
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDispatchActions(int dispatchId) async {
    try {
      final res = await api.dio.get(Endpoints.adminDispatchActions(dispatchId));
      final data = unwrapData(res.data);
      final actions = data['availableActions'];
      if (actions is List) {
        actionByDispatch[dispatchId] = actions
            .whereType<Map>()
            .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
            .toList();
      } else {
        actionByDispatch[dispatchId] = [];
      }
      rowErrors.remove(dispatchId);
      notifyListeners();
    } catch (e) {
      final parsed = parseApiError(e);
      rowErrors[dispatchId] = parsed.message;
      notifyListeners();
    }
  }

  Future<void> runDispatchAction({
    required int dispatchId,
    required String targetStatus,
    String? reason,
  }) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      await api.dio.patch(
        Endpoints.adminDispatchStatus(dispatchId),
        data: {'status': targetStatus, 'reason': reason ?? ''},
      );
      await fetchDispatches();
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSafetyList({
    String? status,
    String? warehouseCode,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      final qp = <String, dynamic>{};
      _putIfNotEmpty(qp, 'status', status);
      _putIfNotEmpty(qp, 'warehouseCode', warehouseCode);
      if (fromDate != null) qp['fromDate'] = _isoDate(fromDate);
      if (toDate != null) qp['toDate'] = _isoDate(toDate);
      final res =
          await api.dio.get(Endpoints.preEntrySafetyList, queryParameters: qp);
      safetyRows = unwrapDataList(res.data);
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSafetyByDispatch(int dispatchId) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      final res =
          await api.dio.get(Endpoints.preEntrySafetyByDispatch(dispatchId));
      safetyDetail = unwrapData(res.data);
      await context.setActiveDispatchId(dispatchId);
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSafetyById(int checkId) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      final res = await api.dio.get('${Endpoints.preEntrySafetyList}/$checkId');
      safetyDetail = unwrapData(res.data);
      await context.setActiveDispatchId(asInt(safetyDetail?['dispatchId']));
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitSafetyChecklist(
      SafetyChecklistSubmission submission) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      await api.dio
          .post(Endpoints.preEntrySafetySubmit, data: submission.toPayload());
      await fetchSafetyByDispatch(submission.dispatchId);
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSafetyChecklist(
    int checkId,
    SafetyChecklistSubmission submission,
  ) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      await api.dio.put(
        '${Endpoints.preEntrySafetyList}/$checkId',
        data: submission.toPayload(),
      );
      await fetchSafetyByDispatch(submission.dispatchId);
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSafetyChecklist(int checkId) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      await api.dio.delete('${Endpoints.preEntrySafetyList}/$checkId');
      safetyDetail = null;
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadSafetyPhoto(File file) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      final form = FormData();
      form.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(file.path,
              filename: file.uri.pathSegments.last),
        ),
      );
      final res = await api.dio.post(
        Endpoints.preEntrySafetyUploadPhoto,
        data: form,
      );
      final data = unwrapData(res.data);
      return data['url']?.toString();
    } catch (e) {
      _setError(e);
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchQueueByWarehouse(String warehouseCode) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      await context.setWarehouse(warehouseCode);
      final res = await api.dio.get(
        Endpoints.loadingQueue,
        queryParameters: {'warehouse': warehouseCode},
      );
      queueRows = unwrapDataList(res.data);
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLoadingDispatchDetail(int dispatchId) async {
    isLoading = true;
    clearError();
    notifyListeners();
    try {
      final res =
          await api.dio.get(Endpoints.loadingDispatchDetail(dispatchId));
      loadingDispatchDetail = unwrapData(res.data);
      await context.setActiveDispatchId(dispatchId);
      await context
          .setActiveQueueId(asInt(loadingDispatchDetail?['queue']?['id']));
      await context
          .setActiveSessionId(asInt(loadingDispatchDetail?['session']?['id']));
    } catch (e) {
      _setError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _setError(Object e) {
    final parsed = parseApiError(e);
    error = parsed.message;
    fieldErrors = parsed.fieldErrors;
    requestId = parsed.requestId;
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _putIfNotEmpty(Map<String, dynamic> qp, String key, String? value) {
    if (value != null && value.trim().isNotEmpty) {
      qp[key] = value.trim();
    }
  }

  String canonicalSafetyStatus(dynamic input) {
    final raw = (input ?? '').toString().toUpperCase();
    switch (raw) {
      case 'PASSED':
      case 'FAILED':
      case 'CONDITIONAL':
      case 'NOT_STARTED':
        return raw;
      case 'PENDING':
      case '':
        return 'NOT_STARTED';
      default:
        return raw;
    }
  }
}
