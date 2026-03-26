//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class PmScheduleControllerApi {
  PmScheduleControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/pm-schedules' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [PMScheduleDto] pMScheduleDto (required):
  Future<Response> createScheduleWithHttpInfo(PMScheduleDto pMScheduleDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules';

    // ignore: prefer_final_locals
    Object? postBody = pMScheduleDto;

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
  /// * [PMScheduleDto] pMScheduleDto (required):
  Future<PMScheduleDto?> createSchedule(PMScheduleDto pMScheduleDto,) async {
    final response = await createScheduleWithHttpInfo(pMScheduleDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PMScheduleDto',) as PMScheduleDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/pm-schedules/{id}/create-work-order' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> createWorkOrderFromPMWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/{id}/create-work-order'
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
  Future<WorkOrderDto?> createWorkOrderFromPM(int id,) async {
    final response = await createWorkOrderFromPMWithHttpInfo(id,);
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

  /// Performs an HTTP 'PATCH /api/admin/pm-schedules/{id}/deactivate' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deactivateScheduleWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/{id}/deactivate'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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
  Future<void> deactivateSchedule(int id,) async {
    final response = await deactivateScheduleWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'DELETE /api/admin/pm-schedules/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteScheduleWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/{id}'
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
  Future<void> deleteSchedule(int id,) async {
    final response = await deleteScheduleWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/admin/pm-schedules' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [bool] active:
  Future<Response> getAllSchedulesWithHttpInfo(Pageable pageable, { bool? active, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (active != null) {
      queryParams.addAll(_queryParams('', 'active', active));
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
  /// * [bool] active:
  Future<PagePMScheduleDto?> getAllSchedules(Pageable pageable, { bool? active, }) async {
    final response = await getAllSchedulesWithHttpInfo(pageable,  active: active, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PagePMScheduleDto',) as PagePMScheduleDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/pm-schedules/due-soon' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] daysAhead:
  Future<Response> getDueSoonSchedulesWithHttpInfo({ int? daysAhead, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/due-soon';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (daysAhead != null) {
      queryParams.addAll(_queryParams('', 'daysAhead', daysAhead));
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
  /// * [int] daysAhead:
  Future<List<PMScheduleDto>?> getDueSoonSchedules({ int? daysAhead, }) async {
    final response = await getDueSoonSchedulesWithHttpInfo( daysAhead: daysAhead, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PMScheduleDto>') as List)
        .cast<PMScheduleDto>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/pm-schedules/overdue' operation and returns the [Response].
  Future<Response> getOverdueSchedulesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/overdue';

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

  Future<List<PMScheduleDto>?> getOverdueSchedules() async {
    final response = await getOverdueSchedulesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PMScheduleDto>') as List)
        .cast<PMScheduleDto>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/pm-schedules/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getScheduleByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/{id}'
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
  Future<PMScheduleDto?> getScheduleById(int id,) async {
    final response = await getScheduleByIdWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PMScheduleDto',) as PMScheduleDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/pm-schedules/vehicle/{vehicleId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] vehicleId (required):
  Future<Response> getSchedulesByVehicleWithHttpInfo(int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/vehicle/{vehicleId}'
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
  Future<List<PMScheduleDto>?> getSchedulesByVehicle(int vehicleId,) async {
    final response = await getSchedulesByVehicleWithHttpInfo(vehicleId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PMScheduleDto>') as List)
        .cast<PMScheduleDto>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/pm-schedules/vehicle-type/{vehicleType}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] vehicleType (required):
  Future<Response> getSchedulesByVehicleTypeWithHttpInfo(String vehicleType,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/vehicle-type/{vehicleType}'
      .replaceAll('{vehicleType}', vehicleType);

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
  /// * [String] vehicleType (required):
  Future<List<PMScheduleDto>?> getSchedulesByVehicleType(String vehicleType,) async {
    final response = await getSchedulesByVehicleTypeWithHttpInfo(vehicleType,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<PMScheduleDto>') as List)
        .cast<PMScheduleDto>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/pm-schedules/{id}/record-completion' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] workOrderId (required):
  ///
  /// * [int] performedAtKm:
  ///
  /// * [DateTime] performedDate:
  ///
  /// * [int] performedEngineHours:
  Future<Response> recordPMCompletionWithHttpInfo(int id, int workOrderId, { int? performedAtKm, DateTime? performedDate, int? performedEngineHours, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/{id}/record-completion'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'workOrderId', workOrderId));
    if (performedAtKm != null) {
      queryParams.addAll(_queryParams('', 'performedAtKm', performedAtKm));
    }
    if (performedDate != null) {
      queryParams.addAll(_queryParams('', 'performedDate', performedDate));
    }
    if (performedEngineHours != null) {
      queryParams.addAll(_queryParams('', 'performedEngineHours', performedEngineHours));
    }

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
  ///
  /// * [int] workOrderId (required):
  ///
  /// * [int] performedAtKm:
  ///
  /// * [DateTime] performedDate:
  ///
  /// * [int] performedEngineHours:
  Future<void> recordPMCompletion(int id, int workOrderId, { int? performedAtKm, DateTime? performedDate, int? performedEngineHours, }) async {
    final response = await recordPMCompletionWithHttpInfo(id, workOrderId,  performedAtKm: performedAtKm, performedDate: performedDate, performedEngineHours: performedEngineHours, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'POST /api/admin/pm-schedules/trigger-check' operation and returns the [Response].
  Future<Response> triggerManualPMCheckWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/trigger-check';

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

  Future<List<WorkOrderDto>?> triggerManualPMCheck() async {
    final response = await triggerManualPMCheckWithHttpInfo();
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

  /// Performs an HTTP 'PUT /api/admin/pm-schedules/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [PMScheduleDto] pMScheduleDto (required):
  Future<Response> updateScheduleWithHttpInfo(int id, PMScheduleDto pMScheduleDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/pm-schedules/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = pMScheduleDto;

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
  /// * [PMScheduleDto] pMScheduleDto (required):
  Future<PMScheduleDto?> updateSchedule(int id, PMScheduleDto pMScheduleDto,) async {
    final response = await updateScheduleWithHttpInfo(id, pMScheduleDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PMScheduleDto',) as PMScheduleDto;
    
    }
    return null;
  }
}
