//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverLocationAdminControllerApi {
  DriverLocationAdminControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/admin/drivers/{id}/location-history' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getDriverLocationHistory1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{id}/location-history'
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
  Future<ApiResponseListLocationHistoryDto?> getDriverLocationHistory1(int id,) async {
    final response = await getDriverLocationHistory1WithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/location-history/paginated' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getDriverLocationHistoryPaginated1WithHttpInfo(int driverId, { int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/location-history/paginated'
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
  Future<ApiResponsePageLocationHistoryDto?> getDriverLocationHistoryPaginated1(int driverId, { int? page, int? size, }) async {
    final response = await getDriverLocationHistoryPaginated1WithHttpInfo(driverId,  page: page, size: size, );
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

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/latest-location' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> latestForDriver1WithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/latest-location'
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
  Future<ApiResponseLiveDriverDto?> latestForDriver1(int driverId,) async {
    final response = await latestForDriver1WithHttpInfo(driverId,);
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

  /// Performs an HTTP 'GET /api/admin/drivers/live-drivers' operation and returns the [Response].
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
  Future<Response> liveDrivers1WithHttpInfo({ bool? onlyOnline, int? onlineSeconds, double? south, double? west, double? north, double? east, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/live-drivers';

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
  Future<ApiResponseListLiveDriverDto?> liveDrivers1({ bool? onlyOnline, int? onlineSeconds, double? south, double? west, double? north, double? east, }) async {
    final response = await liveDrivers1WithHttpInfo( onlyOnline: onlyOnline, onlineSeconds: onlineSeconds, south: south, west: west, north: north, east: east, );
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
}
