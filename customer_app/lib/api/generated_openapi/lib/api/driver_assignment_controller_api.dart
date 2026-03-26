//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverAssignmentControllerApi {
  DriverAssignmentControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/drivers/assign' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] vehicleId (required):
  Future<Response> assignDriver1WithHttpInfo(int driverId, int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/assign';

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
  Future<ApiResponseDriverAssignment?> assignDriver1(int driverId, int vehicleId,) async {
    final response = await assignDriver1WithHttpInfo(driverId, vehicleId,);
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

  /// Performs an HTTP 'GET /api/admin/drivers/by-driver/{driverId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> getVehiclesByDriver1WithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/by-driver/{driverId}'
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
  Future<ApiResponseListVehicleDto?> getVehiclesByDriver1(int driverId,) async {
    final response = await getVehiclesByDriver1WithHttpInfo(driverId,);
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

  /// Performs an HTTP 'GET /api/admin/drivers/vehicles-with-drivers' operation and returns the [Response].
  Future<Response> getVehiclesWithCurrentDrivers1WithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/vehicles-with-drivers';

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

  Future<ApiResponseListVehicleWithDriverDto?> getVehiclesWithCurrentDrivers1() async {
    final response = await getVehiclesWithCurrentDrivers1WithHttpInfo();
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
}
