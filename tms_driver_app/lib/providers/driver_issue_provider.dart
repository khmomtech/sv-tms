import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:tms_driver_app/core/network/dio_client.dart';
import 'package:tms_driver_app/models/driver_issue_model.dart';
import 'package:tms_driver_app/utils/error_handler.dart';

class DriverIssueProvider with ChangeNotifier {
  final DioClient _dio = DioClient();
  final List<DriverIssue> _issues = [];
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  static const String _basePath = '/driver-app/incidents';

  static const int _pageSize = 10;
  bool _disposed = false;

  String? _errorMessage;

  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  List<DriverIssue> get issues => _issues;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  void _notifySafely() {
    if (_disposed) return;
    // Defer notifications to avoid triggering rebuilds during the build phase
    scheduleMicrotask(() {
      if (_disposed) return;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // driverId is inferred from auth on backend
  Future<DriverIssue> submitIssue({
    required String title,
    required String description,
    String? dispatchId,
    List<File>? images,
  }) async {
    _errorMessage = null;
    try {
      final payload = jsonEncode({
        'dispatchId': dispatchId == null
            ? null
            : (int.tryParse(dispatchId) ?? dispatchId),
        'title': title,
        'description': description,
      });
      final form = FormData();
      // JSON payload part with correct content-type
      form.files.add(MapEntry(
        'payload',
        MultipartFile.fromBytes(
          utf8.encode(payload),
          filename: 'payload.json',
          contentType: MediaType('application', 'json'),
        ),
      ));

      if (images != null && images.isNotEmpty) {
        for (final file in images) {
          form.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ));
        }
      }

      final path = _dio.resolvePath(_basePath);
      final res = await _dio.dio.post(
        path,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (!_isSuccess(res)) {
        final message = _extractMessage(res.data, res.statusCode ?? 0);
        _errorMessage = message;
        throw Exception('Failed to submit issue: $message');
      }

      final data = _unwrapData(res.data);
      final created =
          DriverIssue.fromJson(data as Map<String, dynamic>);
      // Prepend newest issue so UI can show it without a refetch
      _issues.insert(0, created);
      _notifySafely();
      return created;
    } catch (e) {
      _errorMessage = e is DioException ? _friendlyError(e) : ErrorHandler.getFriendlyMessage(e);
      rethrow;
    }
  }

  Future<void> fetchDriverIssuesPaginated({
    bool refresh = false,
    String? status,
    String? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    if (_isLoading) return;

    if (refresh) {
      _page = 0;
      _hasMore = true;
      _issues.clear();
      _errorMessage = null;
      _notifySafely();
    }

    if (!_hasMore) return;
    _isLoading = true;
    _notifySafely();

    try {
      // Backend uses authenticated driver; no driverId query needed.
      _errorMessage = null;
      final path = _dio.resolvePath(_basePath);
      final response = await _dio.dio.get(
        path,
        queryParameters: {
          'page': '$_page',
          'size': '$_pageSize',
      if (status != null && status.isNotEmpty)
            'status': _toBackendStatus(status),
          if (fromDate != null) 'fromDate': _formatDate(fromDate)!,
          if (toDate != null) 'toDate': _formatDate(toDate)!,
        },
        options: Options(responseType: ResponseType.json),
      );

      if (!_isSuccess(response)) {
        final message =
            _extractMessage(response.data, response.statusCode ?? 0);
        _errorMessage = 'Failed to fetch issues: $message';
        _notifySafely();
        return;
      }

      final jsonData = response.data;
      final data = _unwrapData(jsonData);

      List<dynamic> content;
      if (data is List) {
        content = data;
      } else if (data is Map && data['content'] is List) {
        content = data['content'] as List;
      } else {
        content = const [];
      }

      final List<DriverIssue> fetched =
          content.map((item) => DriverIssue.fromJson(item)).toList();

      // Prefer backend paging flags when available
      if (data is Map && data.containsKey('last')) {
        _hasMore = !(data['last'] == true);
      } else if (data is Map &&
          data.containsKey('totalPages') &&
          data.containsKey('number')) {
        final totalPages = (data['totalPages'] as num?)?.toInt();
        final number = (data['number'] as num?)?.toInt() ?? _page;
        _hasMore = totalPages == null
            ? fetched.length == _pageSize
            : (number + 1) < totalPages;
      } else {
        // When totals are unknown, assume "has more" only if we received a full page.
        _hasMore = fetched.length == _pageSize;
      }

      // If first page returns empty, stop further paging attempts.
      if (_page == 0 && fetched.isEmpty) {
        _hasMore = false;
      }

      _issues.addAll(fetched);

      _page++;
      _notifySafely();
    } on DioException catch (e) {
      _errorMessage = _friendlyError(e);
      _notifySafely();
    } catch (e) {
      _errorMessage = ErrorHandler.getFriendlyMessage(e);
      _notifySafely();
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<DriverIssue> getIssueById(int id) async {
    final path = _dio.resolvePath('$_basePath/$id');
    final response = await _dio.dio.get(path);

    if (_isSuccess(response)) {
      final data = _unwrapData(response.data);
      return DriverIssue.fromJson(data as Map<String, dynamic>);
    }
    final error = _extractMessage(response.data, response.statusCode ?? 0);
    _errorMessage = error;
    throw Exception('Failed to fetch issue: $error');
  }

  Future<void> updateIssueStatus(int issueId, String status) async {
    final mappedStatus = _toBackendStatus(status) ?? status;
    final uri = _dio.resolvePath('/driver-app/incidents/$issueId/status');
    final response = await _dio.dio.patch(
      uri,
      data: jsonEncode({'status': mappedStatus}),
      options: Options(contentType: 'application/json'),
    );

    if (_isSuccess(response)) {
      final data = _unwrapData(response.data);
      final updated =
          DriverIssue.fromJson((data as Map<String, dynamic>));
      final index = _issues.indexWhere((i) => i.id == issueId);
      if (index != -1) {
        _issues[index] = updated;
        _notifySafely();
      }
      return;
    }
    final error = _extractMessage(response.data, response.statusCode ?? 0);
    _errorMessage = error;
    throw Exception('Failed to update issue status: $error');
  }

  Future<void> deleteIssue(int issueId) async {
    final uri = _dio.resolvePath('/driver-app/incidents/$issueId');
    final response = await _dio.dio.delete(uri);

    if (response.statusCode == 204 || _isSuccess(response)) {
      _issues.removeWhere((i) => i.id == issueId);
      _notifySafely();
      return;
    }
    final error = _extractMessage(response.data, response.statusCode ?? 0);
    _errorMessage = error;
    throw Exception('Failed to delete issue: $error');
  }

  void resetIssues() {
    _issues.clear();
    _page = 0;
    _hasMore = true;
    _notifySafely();
  }

  Future<void> updateIssue({
    required int issueId,
    required String title,
    required String description,
  }) async {
    final uri = _dio.resolvePath('/driver-app/incidents/$issueId');
    final response = await _dio.dio.put(
      uri,
      data: json.encode({
        'title': title,
        'description': description,
      }),
      options: Options(contentType: 'application/json'),
    );

    if (_isSuccess(response)) {
      final updated =
          DriverIssue.fromJson(_unwrapData(response.data) as Map<String, dynamic>);
      final index = _issues.indexWhere((i) => i.id == issueId);
      if (index != -1) {
        _issues[index] = updated;
        _notifySafely();
      }
      return;
    }
    final error = _extractMessage(response.data, response.statusCode ?? 0);
    _errorMessage = error;
    throw Exception('Failed to update issue: $error');
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

  String _friendlyError(DioException e) {
    final status = e.response?.statusCode;
    if (status != null) {
      return ErrorHandler.fromStatusCode(status);
    }

    final body = e.response?.data;
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ErrorHandler.getFriendlyMessage(e.error ?? e.message ?? e);
    }

    return ErrorHandler.getFriendlyMessage(e);
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return date.toIso8601String().split('T').first;
  }

  String? _toBackendStatus(String? status) {
    if (status == null) return null;
    final normalized = status.toUpperCase();
    switch (normalized) {
      case 'OPEN':
        return 'NEW';
      case 'IN_PROGRESS':
        return 'VALIDATED';
      case 'RESOLVED':
        return 'CLOSED';
      case 'CLOSED':
        return 'CLOSED';
      default:
        return normalized;
    }
  }
}
