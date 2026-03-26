//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MaintenanceTaskControllerApi {
  MaintenanceTaskControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/maintenance-tasks/{id}/complete' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> completeTaskWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-tasks/{id}/complete'
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
  Future<ApiResponseMaintenanceTaskDto?> completeTask(int id,) async {
    final response = await completeTaskWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMaintenanceTaskDto',) as ApiResponseMaintenanceTaskDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/maintenance-tasks' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [MaintenanceTaskDto] maintenanceTaskDto (required):
  Future<Response> createTaskWithHttpInfo(MaintenanceTaskDto maintenanceTaskDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-tasks';

    // ignore: prefer_final_locals
    Object? postBody = maintenanceTaskDto;

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
  /// * [MaintenanceTaskDto] maintenanceTaskDto (required):
  Future<ApiResponseMaintenanceTaskDto?> createTask(MaintenanceTaskDto maintenanceTaskDto,) async {
    final response = await createTaskWithHttpInfo(maintenanceTaskDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMaintenanceTaskDto',) as ApiResponseMaintenanceTaskDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/maintenance-tasks/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteTaskWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-tasks/{id}'
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
  Future<ApiResponseVoid?> deleteTask(int id,) async {
    final response = await deleteTaskWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseVoid',) as ApiResponseVoid;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/maintenance-tasks/overdue' operation and returns the [Response].
  Future<Response> getOverdueTasksWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-tasks/overdue';

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

  Future<ApiResponseListMaintenanceTaskDto?> getOverdueTasks() async {
    final response = await getOverdueTasksWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListMaintenanceTaskDto',) as ApiResponseListMaintenanceTaskDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/maintenance-tasks/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getTaskWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-tasks/{id}'
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
  Future<ApiResponseMaintenanceTaskDto?> getTask(int id,) async {
    final response = await getTaskWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMaintenanceTaskDto',) as ApiResponseMaintenanceTaskDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/maintenance-tasks/vehicle/{vehicleId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] vehicleId (required):
  Future<Response> getTasksByVehicleWithHttpInfo(int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-tasks/vehicle/{vehicleId}'
      .replaceAll('{vehicleId}', vehicleId.toString());

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
  /// * [int] vehicleId (required):
  Future<ApiResponseListMaintenanceTaskDto?> getTasksByVehicle(int vehicleId,) async {
    final response = await getTasksByVehicleWithHttpInfo(vehicleId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListMaintenanceTaskDto',) as ApiResponseListMaintenanceTaskDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/maintenance-tasks/upcoming' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] days:
  Future<Response> getUpcomingTasksWithHttpInfo({ int? days, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-tasks/upcoming';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (days != null) {
      queryParams.addAll(_queryParams('', 'days', days));
    }

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
  /// * [int] days:
  Future<ApiResponseListMaintenanceTaskDto?> getUpcomingTasks({ int? days, }) async {
    final response = await getUpcomingTasksWithHttpInfo( days: days, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListMaintenanceTaskDto',) as ApiResponseListMaintenanceTaskDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/maintenance-tasks' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] keyword:
  ///
  /// * [String] status:
  ///
  /// * [int] vehicleId:
  ///
  /// * [DateTime] dueBefore:
  ///
  /// * [DateTime] dueAfter:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> listTasksWithHttpInfo({ String? keyword, String? status, int? vehicleId, DateTime? dueBefore, DateTime? dueAfter, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-tasks';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (keyword != null) {
      queryParams.addAll(_queryParams('', 'keyword', keyword));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (vehicleId != null) {
      queryParams.addAll(_queryParams('', 'vehicleId', vehicleId));
    }
    if (dueBefore != null) {
      queryParams.addAll(_queryParams('', 'dueBefore', dueBefore));
    }
    if (dueAfter != null) {
      queryParams.addAll(_queryParams('', 'dueAfter', dueAfter));
    }
    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (size != null) {
      queryParams.addAll(_queryParams('', 'size', size));
    }

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
  /// * [String] keyword:
  ///
  /// * [String] status:
  ///
  /// * [int] vehicleId:
  ///
  /// * [DateTime] dueBefore:
  ///
  /// * [DateTime] dueAfter:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageMaintenanceTaskDto?> listTasks({ String? keyword, String? status, int? vehicleId, DateTime? dueBefore, DateTime? dueAfter, int? page, int? size, }) async {
    final response = await listTasksWithHttpInfo( keyword: keyword, status: status, vehicleId: vehicleId, dueBefore: dueBefore, dueAfter: dueAfter, page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageMaintenanceTaskDto',) as ApiResponsePageMaintenanceTaskDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/maintenance-tasks/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [MaintenanceTaskDto] maintenanceTaskDto (required):
  Future<Response> updateTaskWithHttpInfo(int id, MaintenanceTaskDto maintenanceTaskDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-tasks/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = maintenanceTaskDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
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
  /// * [MaintenanceTaskDto] maintenanceTaskDto (required):
  Future<ApiResponseMaintenanceTaskDto?> updateTask(int id, MaintenanceTaskDto maintenanceTaskDto,) async {
    final response = await updateTaskWithHttpInfo(id, maintenanceTaskDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMaintenanceTaskDto',) as ApiResponseMaintenanceTaskDto;
    
    }
    return null;
  }
}
