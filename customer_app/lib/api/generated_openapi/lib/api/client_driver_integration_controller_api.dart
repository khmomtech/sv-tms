//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ClientDriverIntegrationControllerApi {
  ClientDriverIntegrationControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/v1/integrations/drivers/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [bool] includeLocationHistory:
  Future<Response> getDriverByIdWithHttpInfo(int id, { bool? includeLocationHistory, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/integrations/drivers/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (includeLocationHistory != null) {
      queryParams.addAll(_queryParams('', 'includeLocationHistory', includeLocationHistory));
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
  /// * [int] id (required):
  ///
  /// * [bool] includeLocationHistory:
  Future<DriverDto?> getDriverById(int id, { bool? includeLocationHistory, }) async {
    final response = await getDriverByIdWithHttpInfo(id,  includeLocationHistory: includeLocationHistory, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DriverDto',) as DriverDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/v1/integrations/drivers/search' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] keyword:
  ///
  /// * [String] truckType:
  ///
  /// * [String] status:
  ///
  /// * [String] zone:
  ///
  /// * [String] licensePlate:
  ///
  /// * [bool] includeLocationHistory:
  Future<Response> searchDriversWithHttpInfo({ String? keyword, String? truckType, String? status, String? zone, String? licensePlate, bool? includeLocationHistory, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/integrations/drivers/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (keyword != null) {
      queryParams.addAll(_queryParams('', 'keyword', keyword));
    }
    if (truckType != null) {
      queryParams.addAll(_queryParams('', 'truckType', truckType));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
    }
    if (licensePlate != null) {
      queryParams.addAll(_queryParams('', 'licensePlate', licensePlate));
    }
    if (includeLocationHistory != null) {
      queryParams.addAll(_queryParams('', 'includeLocationHistory', includeLocationHistory));
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
  /// * [String] truckType:
  ///
  /// * [String] status:
  ///
  /// * [String] zone:
  ///
  /// * [String] licensePlate:
  ///
  /// * [bool] includeLocationHistory:
  Future<List<DriverDto>?> searchDrivers({ String? keyword, String? truckType, String? status, String? zone, String? licensePlate, bool? includeLocationHistory, }) async {
    final response = await searchDriversWithHttpInfo( keyword: keyword, truckType: truckType, status: status, zone: zone, licensePlate: licensePlate, includeLocationHistory: includeLocationHistory, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<DriverDto>') as List)
        .cast<DriverDto>()
        .toList(growable: false);

    }
    return null;
  }
}
