//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverVTwoControllerApi {
  DriverVTwoControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/driver/add' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DriverCreateRequest] driverCreateRequest (required):
  Future<Response> addDriverWithHttpInfo(DriverCreateRequest driverCreateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/add';

    // ignore: prefer_final_locals
    Object? postBody = driverCreateRequest;

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
  /// * [DriverCreateRequest] driverCreateRequest (required):
  Future<ApiResponseDriverDto?> addDriver(DriverCreateRequest driverCreateRequest,) async {
    final response = await addDriverWithHttpInfo(driverCreateRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverDto',) as ApiResponseDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/location/update/batch' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [List<DriverLocationUpdateDto>] driverLocationUpdateDto (required):
  Future<Response> adminUpdateDriverLocationBatchWithHttpInfo(List<DriverLocationUpdateDto> driverLocationUpdateDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/location/update/batch';

    // ignore: prefer_final_locals
    Object? postBody = driverLocationUpdateDto;

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
  /// * [List<DriverLocationUpdateDto>] driverLocationUpdateDto (required):
  Future<ApiResponseString?> adminUpdateDriverLocationBatch(List<DriverLocationUpdateDto> driverLocationUpdateDto,) async {
    final response = await adminUpdateDriverLocationBatchWithHttpInfo(driverLocationUpdateDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/advanced-search' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DriverFilterRequest] driverFilterRequest (required):
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> advancedSearchDriversWithHttpInfo(DriverFilterRequest driverFilterRequest, { int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/advanced-search';

    // ignore: prefer_final_locals
    Object? postBody = driverFilterRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (size != null) {
      queryParams.addAll(_queryParams('', 'size', size));
    }

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
  /// * [DriverFilterRequest] driverFilterRequest (required):
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageResponseDriverDto?> advancedSearchDrivers(DriverFilterRequest driverFilterRequest, { int? page, int? size, }) async {
    final response = await advancedSearchDriversWithHttpInfo(driverFilterRequest,  page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageResponseDriverDto',) as ApiResponsePageResponseDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/assign' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] vehicleId (required):
  Future<Response> assignDriverWithHttpInfo(int driverId, int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/assign';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'driverId', driverId));
      queryParams.addAll(_queryParams('', 'vehicleId', vehicleId));

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
  /// * [int] driverId (required):
  ///
  /// * [int] vehicleId (required):
  Future<ApiResponseDriverAssignment?> assignDriver(int driverId, int vehicleId,) async {
    final response = await assignDriverWithHttpInfo(driverId, vehicleId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverAssignment',) as ApiResponseDriverAssignment;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/broadcast-notification' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [BroadcastNotificationRequest] broadcastNotificationRequest (required):
  Future<Response> broadcastNotificationWithHttpInfo(BroadcastNotificationRequest broadcastNotificationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/broadcast-notification';

    // ignore: prefer_final_locals
    Object? postBody = broadcastNotificationRequest;

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
  /// * [BroadcastNotificationRequest] broadcastNotificationRequest (required):
  Future<ApiResponseString?> broadcastNotification(BroadcastNotificationRequest broadcastNotificationRequest,) async {
    final response = await broadcastNotificationWithHttpInfo(broadcastNotificationRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/driver/delete/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteDriverWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/delete/{id}'
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
  Future<ApiResponseString?> deleteDriver(int id,) async {
    final response = await deleteDriverWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/driver/{driverId}/notifications/{notificationId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<Response> deleteDriverNotification1WithHttpInfo(int driverId, int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{driverId}/notifications/{notificationId}'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{notificationId}', notificationId.toString());

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
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<ApiResponseString?> deleteDriverNotification1(int driverId, int notificationId,) async {
    final response = await deleteDriverNotification1WithHttpInfo(driverId, notificationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/{driverId}/heartbeat' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [HeartbeatDto] heartbeatDto (required):
  Future<Response> driverHeartbeatWithHttpInfo(int driverId, HeartbeatDto heartbeatDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{driverId}/heartbeat'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = heartbeatDto;

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
  /// * [int] driverId (required):
  ///
  /// * [HeartbeatDto] heartbeatDto (required):
  Future<ApiResponseString?> driverHeartbeat(int driverId, HeartbeatDto heartbeatDto,) async {
    final response = await driverHeartbeatWithHttpInfo(driverId, heartbeatDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/{driverId}/force-open' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> forceOpenDriverAppWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{driverId}/force-open'
      .replaceAll('{driverId}', driverId.toString());

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
  /// * [int] driverId (required):
  Future<ApiResponseString?> forceOpenDriverApp(int driverId,) async {
    final response = await forceOpenDriverAppWithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/list' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getAllDriversWithHttpInfo({ int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/list';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageResponseDriverDto?> getAllDrivers({ int? page, int? size, }) async {
    final response = await getAllDriversWithHttpInfo( page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageResponseDriverDto',) as ApiResponsePageResponseDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/all' operation and returns the [Response].
  Future<Response> getAllDriversNoPagWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/all';

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

  Future<ApiResponseListDriverDto?> getAllDriversNoPag() async {
    final response = await getAllDriversNoPagWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDriverDto',) as ApiResponseListDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/alllists' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getAllListDriversWithHttpInfo({ int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/alllists';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageResponseDriverDto?> getAllListDrivers({ int? page, int? size, }) async {
    final response = await getAllListDriversWithHttpInfo( page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageResponseDriverDto',) as ApiResponsePageResponseDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/{id}/device-token' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getDeviceTokenWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{id}/device-token'
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
  Future<ApiResponseString?> getDeviceToken(int id,) async {
    final response = await getDeviceTokenWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getDriverById1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{id}'
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
  Future<ApiResponseDriverDto?> getDriverById1(int id,) async {
    final response = await getDriverById1WithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverDto',) as ApiResponseDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/{id}/location-history' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getDriverLocationHistoryWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{id}/location-history'
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
  Future<ApiResponseListLocationHistoryDto?> getDriverLocationHistory(int id,) async {
    final response = await getDriverLocationHistoryWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListLocationHistoryDto',) as ApiResponseListLocationHistoryDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/{driverId}/location-history/paginated' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getDriverLocationHistoryPaginatedWithHttpInfo(int driverId, { int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{driverId}/location-history/paginated'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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
  /// * [int] driverId (required):
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageLocationHistoryDto?> getDriverLocationHistoryPaginated(int driverId, { int? page, int? size, }) async {
    final response = await getDriverLocationHistoryPaginatedWithHttpInfo(driverId,  page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageLocationHistoryDto',) as ApiResponsePageLocationHistoryDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/{driverId}/notifications' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [String] order:
  ///
  /// * [bool] unreadOnly:
  ///
  /// * [DateTime] since:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getDriverNotifications1WithHttpInfo(int driverId, { String? order, bool? unreadOnly, DateTime? since, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{driverId}/notifications'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (order != null) {
      queryParams.addAll(_queryParams('', 'order', order));
    }
    if (unreadOnly != null) {
      queryParams.addAll(_queryParams('', 'unreadOnly', unreadOnly));
    }
    if (since != null) {
      queryParams.addAll(_queryParams('', 'since', since));
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
  /// * [int] driverId (required):
  ///
  /// * [String] order:
  ///
  /// * [bool] unreadOnly:
  ///
  /// * [DateTime] since:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponseMapStringObject?> getDriverNotifications1(int driverId, { String? order, bool? unreadOnly, DateTime? since, int? page, int? size, }) async {
    final response = await getDriverNotifications1WithHttpInfo(driverId,  order: order, unreadOnly: unreadOnly, since: since, page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMapStringObject',) as ApiResponseMapStringObject;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/by-driver/{driverId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> getVehiclesByDriverWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/by-driver/{driverId}'
      .replaceAll('{driverId}', driverId.toString());

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
  /// * [int] driverId (required):
  Future<ApiResponseListVehicleDto?> getVehiclesByDriver(int driverId,) async {
    final response = await getVehiclesByDriverWithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListVehicleDto',) as ApiResponseListVehicleDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/vehicles-with-drivers' operation and returns the [Response].
  Future<Response> getVehiclesWithCurrentDriversWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/vehicles-with-drivers';

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

  Future<ApiResponseListVehicleWithDriverDto?> getVehiclesWithCurrentDrivers() async {
    final response = await getVehiclesWithCurrentDriversWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListVehicleWithDriverDto',) as ApiResponseListVehicleWithDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/{driverId}/latest-location' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> latestForDriverWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{driverId}/latest-location'
      .replaceAll('{driverId}', driverId.toString());

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
  /// * [int] driverId (required):
  Future<ApiResponseLiveDriverDto?> latestForDriver(int driverId,) async {
    final response = await latestForDriverWithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseLiveDriverDto',) as ApiResponseLiveDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/live-drivers' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [bool] onlyOnline:
  ///
  /// * [int] onlineSeconds:
  ///
  /// * [double] south:
  ///
  /// * [double] west:
  ///
  /// * [double] north:
  ///
  /// * [double] east:
  Future<Response> liveDriversWithHttpInfo({ bool? onlyOnline, int? onlineSeconds, double? south, double? west, double? north, double? east, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/live-drivers';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (onlyOnline != null) {
      queryParams.addAll(_queryParams('', 'onlyOnline', onlyOnline));
    }
    if (onlineSeconds != null) {
      queryParams.addAll(_queryParams('', 'onlineSeconds', onlineSeconds));
    }
    if (south != null) {
      queryParams.addAll(_queryParams('', 'south', south));
    }
    if (west != null) {
      queryParams.addAll(_queryParams('', 'west', west));
    }
    if (north != null) {
      queryParams.addAll(_queryParams('', 'north', north));
    }
    if (east != null) {
      queryParams.addAll(_queryParams('', 'east', east));
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
  /// * [bool] onlyOnline:
  ///
  /// * [int] onlineSeconds:
  ///
  /// * [double] south:
  ///
  /// * [double] west:
  ///
  /// * [double] north:
  ///
  /// * [double] east:
  Future<ApiResponseListLiveDriverDto?> liveDrivers({ bool? onlyOnline, int? onlineSeconds, double? south, double? west, double? north, double? east, }) async {
    final response = await liveDriversWithHttpInfo( onlyOnline: onlyOnline, onlineSeconds: onlineSeconds, south: south, west: west, north: north, east: east, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListLiveDriverDto',) as ApiResponseListLiveDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PATCH /api/driver/{driverId}/notifications/mark-all-read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> markAllAsRead1WithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{driverId}/notifications/mark-all-read'
      .replaceAll('{driverId}', driverId.toString());

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
  /// * [int] driverId (required):
  Future<ApiResponseString?> markAllAsRead1(int driverId,) async {
    final response = await markAllAsRead1WithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/driver/{driverId}/notifications/{notificationId}/read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<Response> markAsRead1WithHttpInfo(int driverId, int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{driverId}/notifications/{notificationId}/read'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{notificationId}', notificationId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<ApiResponseString?> markAsRead1(int driverId, int notificationId,) async {
    final response = await markAsRead1WithHttpInfo(driverId, notificationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/driver/notifications/{notificationId}/read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] notificationId (required):
  Future<Response> markAsReadLegacy1WithHttpInfo(int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/notifications/{notificationId}/read'
      .replaceAll('{notificationId}', notificationId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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
  /// * [int] notificationId (required):
  Future<ApiResponseString?> markAsReadLegacy1(int notificationId,) async {
    final response = await markAsReadLegacy1WithHttpInfo(notificationId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/search' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] query (required):
  Future<Response> searchDrivers1WithHttpInfo(String query,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'query', query));

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
  /// * [String] query (required):
  Future<ApiResponseListDriverDto?> searchDrivers1(String query,) async {
    final response = await searchDrivers1WithHttpInfo(query,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDriverDto',) as ApiResponseListDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/send-notification' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [CreateNotificationRequest] createNotificationRequest (required):
  Future<Response> sendNotificationWithHttpInfo(CreateNotificationRequest createNotificationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/send-notification';

    // ignore: prefer_final_locals
    Object? postBody = createNotificationRequest;

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
  /// * [CreateNotificationRequest] createNotificationRequest (required):
  Future<ApiResponseString?> sendNotification(CreateNotificationRequest createNotificationRequest,) async {
    final response = await sendNotificationWithHttpInfo(createNotificationRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/update-device-token' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DeviceTokenRequest] deviceTokenRequest (required):
  Future<Response> updateDeviceTokenWithHttpInfo(DeviceTokenRequest deviceTokenRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/update-device-token';

    // ignore: prefer_final_locals
    Object? postBody = deviceTokenRequest;

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
  /// * [DeviceTokenRequest] deviceTokenRequest (required):
  Future<ApiResponseString?> updateDeviceToken(DeviceTokenRequest deviceTokenRequest,) async {
    final response = await updateDeviceTokenWithHttpInfo(deviceTokenRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/driver/update/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [DriverUpdateRequest] driverUpdateRequest (required):
  Future<Response> updateDriverWithHttpInfo(int id, DriverUpdateRequest driverUpdateRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/update/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = driverUpdateRequest;

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
  /// * [DriverUpdateRequest] driverUpdateRequest (required):
  Future<ApiResponseDriverDto?> updateDriver(int id, DriverUpdateRequest driverUpdateRequest,) async {
    final response = await updateDriverWithHttpInfo(id, driverUpdateRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverDto',) as ApiResponseDriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/{driverId}/upload-profile' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [MultipartFile] profilePicture (required):
  Future<Response> uploadProfilePictureAdminWithHttpInfo(int driverId, MultipartFile profilePicture,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/{driverId}/upload-profile'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (profilePicture != null) {
      hasFields = true;
      mp.fields[r'profilePicture'] = profilePicture.field;
      mp.files.add(profilePicture);
    }
    if (hasFields) {
      postBody = mp;
    }

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
  /// * [int] driverId (required):
  ///
  /// * [MultipartFile] profilePicture (required):
  Future<ApiResponseString?> uploadProfilePictureAdmin(int driverId, MultipartFile profilePicture,) async {
    final response = await uploadProfilePictureAdminWithHttpInfo(driverId, profilePicture,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseString',) as ApiResponseString;
    
    }
    return null;
  }
}
