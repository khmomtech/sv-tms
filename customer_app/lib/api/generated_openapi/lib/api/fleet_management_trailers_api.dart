//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class FleetManagementTrailersApi {
  FleetManagementTrailersApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Assign trailer to a truck
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] trailerId (required):
  ///
  /// * [int] vehicleId (required):
  Future<Response> assignTrailerToTruckWithHttpInfo(int trailerId, int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/trailers/{trailerId}/assign/{vehicleId}'
      .replaceAll('{trailerId}', trailerId.toString())
      .replaceAll('{vehicleId}', vehicleId.toString());

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

  /// Assign trailer to a truck
  ///
  /// Parameters:
  ///
  /// * [int] trailerId (required):
  ///
  /// * [int] vehicleId (required):
  Future<ApiResponseVehicleDto?> assignTrailerToTruck(int trailerId, int vehicleId,) async {
    final response = await assignTrailerToTruckWithHttpInfo(trailerId, vehicleId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseVehicleDto',) as ApiResponseVehicleDto;
    
    }
    return null;
  }

  /// Get all trailers with pagination
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getAllTrailersWithHttpInfo({ int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/trailers/list';

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

  /// Get all trailers with pagination
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageVehicleDto?> getAllTrailers({ int? page, int? size, }) async {
    final response = await getAllTrailersWithHttpInfo( page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageVehicleDto',) as ApiResponsePageVehicleDto;
    
    }
    return null;
  }

  /// Get all trailers without pagination
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAllTrailersNoPageWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/trailers/all';

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

  /// Get all trailers without pagination
  Future<ApiResponseListVehicleDto?> getAllTrailersNoPage() async {
    final response = await getAllTrailersNoPageWithHttpInfo();
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

  /// Get all available trailers (not assigned to any truck)
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAvailableTrailersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/trailers/available';

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

  /// Get all available trailers (not assigned to any truck)
  Future<ApiResponseListVehicleDto?> getAvailableTrailers() async {
    final response = await getAvailableTrailersWithHttpInfo();
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

  /// Get trailers assigned to a specific truck
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] vehicleId (required):
  Future<Response> getTrailersByTruckWithHttpInfo(int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/trailers/by-truck/{vehicleId}'
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

  /// Get trailers assigned to a specific truck
  ///
  /// Parameters:
  ///
  /// * [int] vehicleId (required):
  Future<ApiResponseListVehicleDto?> getTrailersByTruck(int vehicleId,) async {
    final response = await getTrailersByTruckWithHttpInfo(vehicleId,);
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

  /// Search trailers with filters
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] search:
  ///   Search term for license plate, model, or manufacturer
  ///
  /// * [String] status:
  ///   Filter by trailer status
  ///
  /// * [String] zone:
  ///   Filter by assigned zone
  ///
  /// * [bool] assigned:
  ///   Filter by assignment status (true=assigned to truck, false=unassigned)
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> searchTrailersWithHttpInfo({ String? search, String? status, String? zone, bool? assigned, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/trailers/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (search != null) {
      queryParams.addAll(_queryParams('', 'search', search));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
    }
    if (assigned != null) {
      queryParams.addAll(_queryParams('', 'assigned', assigned));
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

  /// Search trailers with filters
  ///
  /// Parameters:
  ///
  /// * [String] search:
  ///   Search term for license plate, model, or manufacturer
  ///
  /// * [String] status:
  ///   Filter by trailer status
  ///
  /// * [String] zone:
  ///   Filter by assigned zone
  ///
  /// * [bool] assigned:
  ///   Filter by assignment status (true=assigned to truck, false=unassigned)
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageVehicleDto?> searchTrailers({ String? search, String? status, String? zone, bool? assigned, int? page, int? size, }) async {
    final response = await searchTrailersWithHttpInfo( search: search, status: status, zone: zone, assigned: assigned, page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageVehicleDto',) as ApiResponsePageVehicleDto;
    
    }
    return null;
  }

  /// Unassign trailer from its current truck
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] trailerId (required):
  Future<Response> unassignTrailerWithHttpInfo(int trailerId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/trailers/{trailerId}/unassign'
      .replaceAll('{trailerId}', trailerId.toString());

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

  /// Unassign trailer from its current truck
  ///
  /// Parameters:
  ///
  /// * [int] trailerId (required):
  Future<ApiResponseVehicleDto?> unassignTrailer(int trailerId,) async {
    final response = await unassignTrailerWithHttpInfo(trailerId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseVehicleDto',) as ApiResponseVehicleDto;
    
    }
    return null;
  }
}
