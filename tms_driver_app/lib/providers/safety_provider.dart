import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';
import 'package:tms_driver_app/models/safety_check_model.dart';

class SafetyProvider with ChangeNotifier {
  final DioClient _dio = DioClient();
  SafetyCheck? _today;
  List<SafetyCheck> _history = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  Timer? _pollTimer;
  bool _disposed = false;
  int? _currentVehicleId;

  static const _draftKeyPrefix = 'safety_draft';
  static const _attachmentQueueKeyPrefix = 'safety_attach_queue';

  SafetyCheck? get today => _today;
  List<SafetyCheck> get history => _history;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  bool get canEdit {
    final status = _normalizeStatus(_today?.status);
    return status == 'NOT_STARTED' || status == 'DRAFT' || status == 'REJECTED';
  }

  String? get status => _normalizeStatus(_today?.status);

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }

  void _notifySafely() {
    if (_disposed) return;
    scheduleMicrotask(() {
      if (_disposed) return;
      notifyListeners();
    });
  }

  String _normalizeStatus(String? raw) {
    if (raw == null || raw.isEmpty) return 'NOT_STARTED';
    final v = raw.toUpperCase();
    if (v == 'WAITING') return 'WAITING_APPROVAL';
    return v;
  }

  Future<void> loadTodaySafety(int vehicleId) async {
    _currentVehicleId = vehicleId;
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final path = _dio.resolvePath('/driver/safety-checks/today');
      final response = await _dio.dio.get(
        path,
        queryParameters: {'vehicleId': vehicleId},
      );

      if (!_isSuccess(response)) {
        _errorMessage =
            _extractMessage(response.data, response.statusCode ?? 0);
        await _loadLocalDraft(vehicleId);
        _isLoading = false;
        _notifySafely();
        return;
      }

      final data = _unwrapData(response.data) as Map<String, dynamic>;
      final serverCheck = SafetyCheck.fromJson(data);

      // Prefer local draft if it is newer and server is not waiting/approved
      final local = await _readLocalDraft(vehicleId, serverCheck.checkDate);
      bool usedLocal = false;
      if (local != null) {
        final serverStatus = _normalizeStatus(serverCheck.status);
        if (serverStatus == 'NOT_STARTED' || serverStatus == 'DRAFT') {
          final localUpdated = local.updatedAt ?? local.createdAt;
          final serverUpdated = serverCheck.updatedAt ?? serverCheck.createdAt;
          if (localUpdated != null && serverUpdated != null) {
            if (localUpdated.isAfter(serverUpdated)) {
              _today = local;
              usedLocal = true;
            } else {
              _today = serverCheck;
            }
          } else {
            _today = local;
            usedLocal = true;
          }
        } else {
          _today = serverCheck;
        }
      } else {
        _today = serverCheck;
      }

      await _bindPendingAttachmentsToCheck(_today?.id);
      await uploadPendingAttachments();
      if (usedLocal && await _isOnline()) {
        await saveDraft();
      }
      pollStatusIfWaiting(vehicleId);
    } catch (e) {
      _errorMessage = e.toString();
      await _loadLocalDraft(vehicleId);
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> saveDraft() async {
    if (_today == null) return;
    _errorMessage = null;
    _isSubmitting = true;
    _notifySafely();

    try {
      if (!await _isOnline()) {
        await _saveLocalDraft(_today!);
        return;
      }

      final path = _dio.resolvePath('/driver/safety-checks/draft');
      final response = await _dio.dio.post(
        path,
        data: jsonEncode(_today!.toJson()),
        options: Options(contentType: 'application/json'),
      );

      if (!_isSuccess(response)) {
        final msg = _extractMessage(response.data, response.statusCode ?? 0);
        _errorMessage = msg;
        await _saveLocalDraft(_today!);
        return;
      }

      final data = _unwrapData(response.data) as Map<String, dynamic>;
      _today = SafetyCheck.fromJson(data);
      await _clearLocalDraft();
      await _bindPendingAttachmentsToCheck(_today?.id);
      await uploadPendingAttachments();
    } catch (e) {
      _errorMessage = e.toString();
      await _saveLocalDraft(_today!);
    } finally {
      _isSubmitting = false;
      _notifySafely();
    }
  }

  void updateItem(
    String category,
    String key,
    String? result,
    String? severity,
    String? remark, {
    String? labelKm,
  }) {
    final check = _ensureToday();
    if (check.vehicleId == null && _currentVehicleId != null) {
      check.vehicleId = _currentVehicleId;
    }
    final idx = check.items
        .indexWhere((item) => item.category == category && item.itemKey == key);

    SafetyCheckItem item;
    if (idx == -1) {
      item = SafetyCheckItem(
          category: category, itemKey: key, itemLabelKm: labelKm);
      check.items.add(item);
    } else {
      item = check.items[idx];
    }

    item.itemLabelKm = labelKm ?? item.itemLabelKm;
    item.result = result ?? item.result;
    item.severity = severity ?? item.severity;
    item.remark = remark ?? item.remark;

    final status = _normalizeStatus(check.status);
    if (status == 'NOT_STARTED' || status == 'REJECTED') {
      check.status = 'DRAFT';
    }

    unawaited(_saveLocalDraft(check));
    _notifySafely();
  }

  void updateNotes(String? value) {
    final check = _ensureToday();
    if (check.vehicleId == null && _currentVehicleId != null) {
      check.vehicleId = _currentVehicleId;
    }
    check.notes = (value ?? '').trim();
    final status = _normalizeStatus(check.status);
    if (status == 'NOT_STARTED' || status == 'REJECTED') {
      check.status = 'DRAFT';
    }
    unawaited(_saveLocalDraft(check));
    _notifySafely();
  }

  Future<void> addAttachment(File file, {int? itemId}) async {
    if (_today == null) return;
    final pending = PendingSafetyAttachment(
      filePath: file.path,
      itemId: itemId,
      safetyCheckId: _today!.id,
    );
    await _enqueueAttachment(pending);
    await uploadPendingAttachments();
  }

  Future<void> uploadPendingAttachments() async {
    if (!await _isOnline()) return;
    final pending = await _readAttachmentQueue();
    if (pending.isEmpty) return;

    final remaining = <PendingSafetyAttachment>[];

    for (final item in pending) {
      if (item.safetyCheckId == null) {
        remaining.add(item);
        continue;
      }
      try {
        final file = File(item.filePath);
        if (!file.existsSync()) {
          continue;
        }
        final form = FormData();
        form.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(file.path,
              filename: file.path.split('/').last),
        ));
        if (item.itemId != null) {
          form.fields.add(MapEntry('itemId', item.itemId.toString()));
        }
        final path = _dio.resolvePath(
            '/driver/safety-checks/${item.safetyCheckId}/attachments');
        final response = await _dio.dio.post(
          path,
          data: form,
          options: Options(contentType: 'multipart/form-data'),
        );
        if (!_isSuccess(response)) {
          remaining.add(item);
        } else {
          final data = _unwrapData(response.data);
          if (data is Map<String, dynamic>) {
            final attachment =
                SafetyCheckAttachment.fromJson(Map<String, dynamic>.from(data));
            _today?.attachments.add(attachment);
          }
        }
      } catch (_) {
        remaining.add(item);
      }
    }

    await _writeAttachmentQueue(remaining);
    _notifySafely();
  }

  Future<void> submitSafetyCheck() async {
    if (_today == null) return;

    // Always sync latest draft before submit so recent edits/notes are not lost.
    await saveDraft();
    if (_today?.id == null) return;
    _errorMessage = null;
    _isSubmitting = true;
    _notifySafely();
    try {
      final path =
          _dio.resolvePath('/driver/safety-checks/${_today!.id}/submit');
      final response = await _dio.dio.post(path);
      if (!_isSuccess(response)) {
        _errorMessage =
            _extractMessage(response.data, response.statusCode ?? 0);
        return;
      }
      final data = _unwrapData(response.data) as Map<String, dynamic>;
      _today = SafetyCheck.fromJson(data);
      await _clearLocalDraft();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSubmitting = false;
      _notifySafely();
    }
  }

  Future<void> loadHistory({DateTime? from, DateTime? to}) async {
    _errorMessage = null;
    _isLoading = true;
    _notifySafely();

    try {
      final path = _dio.resolvePath('/driver/safety-checks');
      final response = await _dio.dio.get(
        path,
        queryParameters: {
          if (from != null) 'from': _formatDate(from),
          if (to != null) 'to': _formatDate(to),
        },
      );

      if (!_isSuccess(response)) {
        _errorMessage =
            _extractMessage(response.data, response.statusCode ?? 0);
        _history = [];
        return;
      }

      final data = _unwrapData(response.data);
      if (data is List) {
        _history = data
            .map((e) => SafetyCheck.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _history = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  void pollStatusIfWaiting(int vehicleId) {
    _pollTimer?.cancel();
    if (_normalizeStatus(_today?.status) != 'WAITING_APPROVAL') return;
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadTodaySafety(vehicleId);
    });
  }

  // ---------- Helpers ----------
  SafetyCheck _ensureToday() {
    if (_today != null) return _today!;
    _today = SafetyCheck(
      status: 'DRAFT',
      checkDate: DateTime.now(),
      vehicleId: _currentVehicleId,
    );
    return _today!;
  }

  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  bool _isSuccess(Response<dynamic> response) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) return false;
    final body = response.data;
    if (body is Map && body.containsKey('success')) {
      return body['success'] == true;
    }
    return true;
  }

  dynamic _unwrapData(dynamic body) {
    if (body is Map && body['data'] != null) {
      return body['data'];
    }
    return body;
  }

  String _extractMessage(dynamic body, int statusCode, {String? fallback}) {
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    if (body is String && body.isNotEmpty) {
      return body;
    }
    return fallback ?? 'Request failed (HTTP $statusCode)';
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<String> _draftKey(int vehicleId, DateTime? date) async {
    final useDate = date ?? DateTime.now();
    return '${_draftKeyPrefix}_${vehicleId}_${_formatDate(useDate)}';
  }

  Future<void> _saveLocalDraft(SafetyCheck check) async {
    if (check.vehicleId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key =
        await _draftKey(check.vehicleId!, check.checkDate ?? DateTime.now());
    await prefs.setString(key, check.toDraftJsonString());
  }

  Future<SafetyCheck?> _readLocalDraft(int vehicleId, DateTime? date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _draftKey(vehicleId, date ?? DateTime.now());
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SafetyCheck.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadLocalDraft(int vehicleId) async {
    final local = await _readLocalDraft(vehicleId, DateTime.now());
    if (local != null) {
      _today = local;
    }
  }

  Future<void> _clearLocalDraft() async {
    if (_today?.vehicleId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = await _draftKey(
        _today!.vehicleId!, _today!.checkDate ?? DateTime.now());
    await prefs.remove(key);
  }

  Future<String> _attachmentQueueKey() async {
    return _attachmentQueueKeyPrefix;
  }

  Future<List<PendingSafetyAttachment>> _readAttachmentQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _attachmentQueueKey();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              PendingSafetyAttachment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeAttachmentQueue(List<PendingSafetyAttachment> list) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _attachmentQueueKey();
    await prefs.setString(
        key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> _enqueueAttachment(PendingSafetyAttachment attachment) async {
    final queue = await _readAttachmentQueue();
    queue.add(attachment);
    await _writeAttachmentQueue(queue);
  }

  Future<void> _bindPendingAttachmentsToCheck(int? safetyCheckId) async {
    if (safetyCheckId == null) return;
    final queue = await _readAttachmentQueue();
    final updated = queue
        .map((e) => e.safetyCheckId == null
            ? PendingSafetyAttachment(
                filePath: e.filePath,
                itemId: e.itemId,
                safetyCheckId: safetyCheckId,
              )
            : e)
        .toList();
    await _writeAttachmentQueue(updated);
  }

  String calculateRiskLevel() {
    final check = _today;
    if (check == null) return 'LOW';
    final hasHigh = check.items
        .any((item) => (item.severity ?? '').toUpperCase() == 'HIGH');
    final issues = check.items
        .where((item) =>
            (item.result ?? '').toUpperCase() != 'OK' &&
            (item.result ?? '').isNotEmpty)
        .length;
    if (hasHigh) return 'HIGH';
    if (issues >= 3) return 'MEDIUM';
    return 'LOW';
  }

  List<SafetyCheckItem> issues() {
    final check = _today;
    if (check == null) return [];
    return check.items
        .where((item) =>
            (item.result ?? '').toUpperCase() != 'OK' &&
            (item.result ?? '').isNotEmpty)
        .toList();
  }
}
