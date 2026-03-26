//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class TechnicianControllerApi {
  TechnicianControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/technician/tasks/pending' operation and returns the [Response].
  Future<Response> getMyPendingTasksWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/technician/tasks/pending';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  Future<List<WorkOrderTaskDto>?> getMyPendingTasks() async {
    final response = await getMyPendingTasksWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<WorkOrderTaskDto>') as List)
        .cast<WorkOrderTaskDto>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/technician/tasks' operation and returns the [Response].
  Future<Response> getMyTasksWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/technician/tasks';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  Future<List<WorkOrderTaskDto>?> getMyTasks() async {
    final response = await getMyTasksWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<WorkOrderTaskDto>') as List)
        .cast<WorkOrderTaskDto>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/technician/work-orders/{woId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] woId (required):
  Future<Response> getMyWorkOrderDetailsWithHttpInfo(int woId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/technician/work-orders/{woId}'
      .replaceAll('{woId}', woId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [int] woId (required):
  Future<WorkOrderDto?> getMyWorkOrderDetails(int woId,) async {
    final response = await getMyWorkOrderDetailsWithHttpInfo(woId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'WorkOrderDto',) as WorkOrderDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/technician/work-orders' operation and returns the [Response].
  Future<Response> getMyWorkOrdersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/technician/work-orders';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  Future<List<WorkOrderDto>?> getMyWorkOrders() async {
    final response = await getMyWorkOrdersWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<WorkOrderDto>') as List)
        .cast<WorkOrderDto>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'PATCH /api/technician/work-orders/{woId}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] woId (required):
  ///
  /// * [String] status (required):
  Future<Response> updateMyWorkOrderStatusWithHttpInfo(int woId, String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/technician/work-orders/{woId}/status'
      .replaceAll('{woId}', woId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'status', status));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [int] woId (required):
  ///
  /// * [String] status (required):
  Future<WorkOrderDto?> updateMyWorkOrderStatus(int woId, String status,) async {
    final response = await updateMyWorkOrderStatusWithHttpInfo(woId, status,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'WorkOrderDto',) as WorkOrderDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PATCH /api/technician/tasks/{taskId}/hours' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///
  /// * [double] actualHours (required):
  Future<Response> updateTaskHoursWithHttpInfo(int taskId, double actualHours,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/technician/tasks/{taskId}/hours'
      .replaceAll('{taskId}', taskId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'actualHours', actualHours));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///
  /// * [double] actualHours (required):
  Future<WorkOrderTaskDto?> updateTaskHours(int taskId, double actualHours,) async {
    final response = await updateTaskHoursWithHttpInfo(taskId, actualHours,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'WorkOrderTaskDto',) as WorkOrderTaskDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PATCH /api/technician/tasks/{taskId}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///
  /// * [String] status (required):
  Future<Response> updateTaskStatusWithHttpInfo(int taskId, String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/technician/tasks/{taskId}/status'
      .replaceAll('{taskId}', taskId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'status', status));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///
  /// * [String] status (required):
  Future<WorkOrderTaskDto?> updateTaskStatus(int taskId, String status,) async {
    final response = await updateTaskStatusWithHttpInfo(taskId, status,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'WorkOrderTaskDto',) as WorkOrderTaskDto;
    
    }
    return null;
  }
}
