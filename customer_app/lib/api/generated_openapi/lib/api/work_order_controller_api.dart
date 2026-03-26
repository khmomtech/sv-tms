//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class WorkOrderControllerApi {
  WorkOrderControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/work-orders/{id}/parts' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [WorkOrderPartDto] workOrderPartDto (required):
  Future<Response> addPartWithHttpInfo(int id, WorkOrderPartDto workOrderPartDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/{id}/parts'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = workOrderPartDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [WorkOrderPartDto] workOrderPartDto (required):
  Future<WorkOrderDto?> addPart(int id, WorkOrderPartDto workOrderPartDto,) async {
    final response = await addPartWithHttpInfo(id, workOrderPartDto,);
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

  /// Performs an HTTP 'POST /api/admin/work-orders/{id}/tasks' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [WorkOrderTaskDto] workOrderTaskDto (required):
  Future<Response> addTaskWithHttpInfo(int id, WorkOrderTaskDto workOrderTaskDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/{id}/tasks'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = workOrderTaskDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [WorkOrderTaskDto] workOrderTaskDto (required):
  Future<WorkOrderDto?> addTask(int id, WorkOrderTaskDto workOrderTaskDto,) async {
    final response = await addTaskWithHttpInfo(id, workOrderTaskDto,);
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

  /// Performs an HTTP 'POST /api/admin/work-orders/{id}/approve' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> approveWorkOrderWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/{id}/approve'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [int] id (required):
  Future<WorkOrderDto?> approveWorkOrder(int id,) async {
    final response = await approveWorkOrderWithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/work-orders/stats/by-status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] status (required):
  Future<Response> countByStatusWithHttpInfo(String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/stats/by-status';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'status', status));

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
  /// * [String] status (required):
  Future<int?> countByStatus(String status,) async {
    final response = await countByStatusWithHttpInfo(status,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'int',) as int;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/work-orders/stats/by-type' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] type (required):
  Future<Response> countByTypeWithHttpInfo(String type,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/stats/by-type';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'type', type));

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
  /// * [String] type (required):
  Future<int?> countByType(String type,) async {
    final response = await countByTypeWithHttpInfo(type,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'int',) as int;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/work-orders' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [WorkOrderDto] workOrderDto (required):
  Future<Response> createWorkOrderWithHttpInfo(WorkOrderDto workOrderDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders';

    // ignore: prefer_final_locals
    Object? postBody = workOrderDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [WorkOrderDto] workOrderDto (required):
  Future<WorkOrderDto?> createWorkOrder(WorkOrderDto workOrderDto,) async {
    final response = await createWorkOrderWithHttpInfo(workOrderDto,);
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

  /// Performs an HTTP 'DELETE /api/admin/work-orders/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteWorkOrderWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [int] id (required):
  Future<void> deleteWorkOrder(int id,) async {
    final response = await deleteWorkOrderWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/admin/work-orders/filter' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [String] status:
  ///
  /// * [String] type:
  ///
  /// * [String] priority:
  ///
  /// * [int] vehicleId:
  ///
  /// * [int] technicianId:
  ///
  /// * [DateTime] scheduledAfter:
  ///
  /// * [DateTime] scheduledBefore:
  Future<Response> filterWorkOrdersWithHttpInfo(Pageable pageable, { String? status, String? type, String? priority, int? vehicleId, int? technicianId, DateTime? scheduledAfter, DateTime? scheduledBefore, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/filter';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (type != null) {
      queryParams.addAll(_queryParams('', 'type', type));
    }
    if (priority != null) {
      queryParams.addAll(_queryParams('', 'priority', priority));
    }
    if (vehicleId != null) {
      queryParams.addAll(_queryParams('', 'vehicleId', vehicleId));
    }
    if (technicianId != null) {
      queryParams.addAll(_queryParams('', 'technicianId', technicianId));
    }
    if (scheduledAfter != null) {
      queryParams.addAll(_queryParams('', 'scheduledAfter', scheduledAfter));
    }
    if (scheduledBefore != null) {
      queryParams.addAll(_queryParams('', 'scheduledBefore', scheduledBefore));
    }
      queryParams.addAll(_queryParams('', 'pageable', pageable));

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
  /// * [Pageable] pageable (required):
  ///
  /// * [String] status:
  ///
  /// * [String] type:
  ///
  /// * [String] priority:
  ///
  /// * [int] vehicleId:
  ///
  /// * [int] technicianId:
  ///
  /// * [DateTime] scheduledAfter:
  ///
  /// * [DateTime] scheduledBefore:
  Future<PageWorkOrderDto?> filterWorkOrders(Pageable pageable, { String? status, String? type, String? priority, int? vehicleId, int? technicianId, DateTime? scheduledAfter, DateTime? scheduledBefore, }) async {
    final response = await filterWorkOrdersWithHttpInfo(pageable,  status: status, type: type, priority: priority, vehicleId: vehicleId, technicianId: technicianId, scheduledAfter: scheduledAfter, scheduledBefore: scheduledBefore, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PageWorkOrderDto',) as PageWorkOrderDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/work-orders' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  Future<Response> getAllWorkOrdersWithHttpInfo(Pageable pageable,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'pageable', pageable));

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
  /// * [Pageable] pageable (required):
  Future<PageWorkOrderDto?> getAllWorkOrders(Pageable pageable,) async {
    final response = await getAllWorkOrdersWithHttpInfo(pageable,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PageWorkOrderDto',) as PageWorkOrderDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/work-orders/pending-approval' operation and returns the [Response].
  Future<Response> getPendingApprovalWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/pending-approval';

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

  Future<List<WorkOrderDto>?> getPendingApproval() async {
    final response = await getPendingApprovalWithHttpInfo();
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

  /// Performs an HTTP 'GET /api/technician/work-orders/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getTechnicianWorkOrderWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/technician/work-orders/{id}'
      .replaceAll('{id}', id.toString());

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
  /// * [int] id (required):
  Future<WorkOrderDto?> getTechnicianWorkOrder(int id,) async {
    final response = await getTechnicianWorkOrderWithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/work-orders/urgent' operation and returns the [Response].
  Future<Response> getUrgentWorkOrdersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/urgent';

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

  Future<List<WorkOrderDto>?> getUrgentWorkOrders() async {
    final response = await getUrgentWorkOrdersWithHttpInfo();
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

  /// Performs an HTTP 'GET /api/admin/work-orders/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getWorkOrderByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/{id}'
      .replaceAll('{id}', id.toString());

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
  /// * [int] id (required):
  Future<WorkOrderDto?> getWorkOrderById(int id,) async {
    final response = await getWorkOrderByIdWithHttpInfo(id,);
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

  /// Performs an HTTP 'PATCH /api/technician/work-orders/{id}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [String] status (required):
  Future<Response> technicianUpdateStatusWithHttpInfo(int id, String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/technician/work-orders/{id}/status'
      .replaceAll('{id}', id.toString());

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
  /// * [int] id (required):
  ///
  /// * [String] status (required):
  Future<WorkOrderDto?> technicianUpdateStatus(int id, String status,) async {
    final response = await technicianUpdateStatusWithHttpInfo(id, status,);
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

  /// Performs an HTTP 'PATCH /api/admin/work-orders/{id}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [String] status (required):
  Future<Response> updateStatus1WithHttpInfo(int id, String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/work-orders/{id}/status'
      .replaceAll('{id}', id.toString());

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
  /// * [int] id (required):
  ///
  /// * [String] status (required):
  Future<WorkOrderDto?> updateStatus1(int id, String status,) async {
    final response = await updateStatus1WithHttpInfo(id, status,);
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
}
