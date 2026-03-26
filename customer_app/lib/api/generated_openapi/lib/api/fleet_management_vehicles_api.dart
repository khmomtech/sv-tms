//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class FleetManagementVehiclesApi {
  FleetManagementVehiclesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a new vehicle
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [VehicleDto] vehicleDto (required):
  Future<Response> addVehicleWithHttpInfo(VehicleDto vehicleDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles';

    // ignore: prefer_final_locals
    Object? postBody = vehicleDto;

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

  /// Create a new vehicle
  ///
  /// Parameters:
  ///
  /// * [VehicleDto] vehicleDto (required):
  Future<ApiResponseVehicleDto?> addVehicle(VehicleDto vehicleDto,) async {
    final response = await addVehicleWithHttpInfo(vehicleDto,);
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

  /// Delete a vehicle
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteVehicleWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/{id}'
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

  /// Delete a vehicle
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<ApiResponseVoid?> deleteVehicle(int id,) async {
    final response = await deleteVehicleWithHttpInfo(id,);
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

  /// Filter vehicles (legacy endpoint)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] search:
  ///
  /// * [String] truckSize:
  ///
  /// * [String] status:
  ///
  /// * [String] zone:
  ///
  /// * [String] driverAssignment:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> filterVehiclesWithHttpInfo({ String? search, String? truckSize, String? status, String? zone, String? driverAssignment, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/filter';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (search != null) {
      queryParams.addAll(_queryParams('', 'search', search));
    }
    if (truckSize != null) {
      queryParams.addAll(_queryParams('', 'truckSize', truckSize));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
    }
    if (driverAssignment != null) {
      queryParams.addAll(_queryParams('', 'driverAssignment', driverAssignment));
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

  /// Filter vehicles (legacy endpoint)
  ///
  /// Parameters:
  ///
  /// * [String] search:
  ///
  /// * [String] truckSize:
  ///
  /// * [String] status:
  ///
  /// * [String] zone:
  ///
  /// * [String] driverAssignment:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageVehicleDto?> filterVehicles({ String? search, String? truckSize, String? status, String? zone, String? driverAssignment, int? page, int? size, }) async {
    final response = await filterVehiclesWithHttpInfo( search: search, truckSize: truckSize, status: status, zone: zone, driverAssignment: driverAssignment, page: page, size: size, );
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

  /// Get all vehicles with pagination
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getAllVehiclesWithHttpInfo({ int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/list';

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

  /// Get all vehicles with pagination
  ///
  /// Parameters:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageVehicleDto?> getAllVehicles({ int? page, int? size, }) async {
    final response = await getAllVehiclesWithHttpInfo( page: page, size: size, );
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

  /// Get all vehicles without pagination
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAllVehiclesNoPageWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/all';

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

  /// Get all vehicles without pagination
  Future<ApiResponseListVehicleDto?> getAllVehiclesNoPage() async {
    final response = await getAllVehiclesNoPageWithHttpInfo();
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

  /// Get vehicle by license plate
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] licensePlate (required):
  Future<Response> getByLicensePlateWithHttpInfo(String licensePlate,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/license/{licensePlate}'
      .replaceAll('{licensePlate}', licensePlate);

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

  /// Get vehicle by license plate
  ///
  /// Parameters:
  ///
  /// * [String] licensePlate (required):
  Future<ApiResponseVehicleDto?> getByLicensePlate(String licensePlate,) async {
    final response = await getByLicensePlateWithHttpInfo(licensePlate,);
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

  /// Get comprehensive fleet statistics
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getFleetStatisticsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/statistics';

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

  /// Get comprehensive fleet statistics
  Future<ApiResponseVehicleStatisticsDto?> getFleetStatistics() async {
    final response = await getFleetStatisticsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseVehicleStatisticsDto',) as ApiResponseVehicleStatisticsDto;
    
    }
    return null;
  }

  /// Get all trailers
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getTrailersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/trailers';

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

  /// Get all trailers
  Future<ApiResponseListVehicleDto?> getTrailers() async {
    final response = await getTrailersWithHttpInfo();
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

  /// Get all unassigned vehicles
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getUnassignedVehiclesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/unassigned';

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

  /// Get all unassigned vehicles
  Future<ApiResponseListVehicleDto?> getUnassignedVehicles() async {
    final response = await getUnassignedVehiclesWithHttpInfo();
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

  /// Get vehicle by ID
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getVehicleByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/{id}'
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

  /// Get vehicle by ID
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<ApiResponseVehicleDto?> getVehicleById(int id,) async {
    final response = await getVehicleByIdWithHttpInfo(id,);
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

  /// Get vehicles by status
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] status (required):
  Future<Response> getVehiclesByStatusWithHttpInfo(String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/status/{status}'
      .replaceAll('{status}', status);

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

  /// Get vehicles by status
  ///
  /// Parameters:
  ///
  /// * [String] status (required):
  Future<ApiResponseListVehicleDto?> getVehiclesByStatus(String status,) async {
    final response = await getVehiclesByStatusWithHttpInfo(status,);
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

  /// Get vehicles requiring service
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getVehiclesRequiringServiceWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/service-due';

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

  /// Get vehicles requiring service
  Future<ApiResponseListVehicleDto?> getVehiclesRequiringService() async {
    final response = await getVehiclesRequiringServiceWithHttpInfo();
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

  /// Advanced vehicle search with multiple criteria
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] search:
  ///   Search term for license plate, model, or manufacturer
  ///
  /// * [String] status:
  ///   Filter by vehicle status
  ///
  /// * [String] type:
  ///   Filter by vehicle type
  ///
  /// * [String] truckSize:
  ///   Filter by truck size
  ///
  /// * [String] zone:
  ///   Filter by assigned zone
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> searchVehiclesWithHttpInfo({ String? search, String? status, String? type, String? truckSize, String? zone, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/search';

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
    if (type != null) {
      queryParams.addAll(_queryParams('', 'type', type));
    }
    if (truckSize != null) {
      queryParams.addAll(_queryParams('', 'truckSize', truckSize));
    }
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
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

  /// Advanced vehicle search with multiple criteria
  ///
  /// Parameters:
  ///
  /// * [String] search:
  ///   Search term for license plate, model, or manufacturer
  ///
  /// * [String] status:
  ///   Filter by vehicle status
  ///
  /// * [String] type:
  ///   Filter by vehicle type
  ///
  /// * [String] truckSize:
  ///   Filter by truck size
  ///
  /// * [String] zone:
  ///   Filter by assigned zone
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageVehicleDto?> searchVehicles({ String? search, String? status, String? type, String? truckSize, String? zone, int? page, int? size, }) async {
    final response = await searchVehiclesWithHttpInfo( search: search, status: status, type: type, truckSize: truckSize, zone: zone, page: page, size: size, );
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

  /// Update an existing vehicle
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [VehicleDto] vehicleDto (required):
  Future<Response> updateVehicleWithHttpInfo(int id, VehicleDto vehicleDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/vehicles/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = vehicleDto;

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

  /// Update an existing vehicle
  ///
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [VehicleDto] vehicleDto (required):
  Future<ApiResponseVehicleDto?> updateVehicle(int id, VehicleDto vehicleDto,) async {
    final response = await updateVehicleWithHttpInfo(id, vehicleDto,);
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
