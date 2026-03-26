//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DashboardControllerApi {
  DashboardControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/admin/dashboard/cache-stats' operation and returns the [Response].
  Future<Response> getCacheStatsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dashboard/cache-stats';

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

  Future<ApiResponseMapStringObject?> getCacheStats() async {
    final response = await getCacheStatsWithHttpInfo();
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

  /// Performs an HTTP 'GET /api/admin/dashboard/summary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  Future<Response> getDashboardSummaryWithHttpInfo({ DateTime? fromDate, DateTime? toDate, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dashboard/summary';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (fromDate != null) {
      queryParams.addAll(_queryParams('', 'fromDate', fromDate));
    }
    if (toDate != null) {
      queryParams.addAll(_queryParams('', 'toDate', toDate));
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
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  Future<ApiResponseDashboardSummaryResponse?> getDashboardSummary({ DateTime? fromDate, DateTime? toDate, }) async {
    final response = await getDashboardSummaryWithHttpInfo( fromDate: fromDate, toDate: toDate, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDashboardSummaryResponse',) as ApiResponseDashboardSummaryResponse;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/dashboard/live-drivers-cached' operation and returns the [Response].
  Future<Response> getLiveDriversCachedOnlyWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dashboard/live-drivers-cached';

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

  Future<ApiResponseListDriverDto?> getLiveDriversCachedOnly() async {
    final response = await getLiveDriversCachedOnlyWithHttpInfo();
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

  /// Performs an HTTP 'GET /api/admin/dashboard/summary-stats' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  ///
  /// * [String] customerName:
  ///
  /// * [String] truckType:
  Future<Response> getSummaryStatsOnlyWithHttpInfo({ DateTime? fromDate, DateTime? toDate, String? customerName, String? truckType, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dashboard/summary-stats';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (fromDate != null) {
      queryParams.addAll(_queryParams('', 'fromDate', fromDate));
    }
    if (toDate != null) {
      queryParams.addAll(_queryParams('', 'toDate', toDate));
    }
    if (customerName != null) {
      queryParams.addAll(_queryParams('', 'customerName', customerName));
    }
    if (truckType != null) {
      queryParams.addAll(_queryParams('', 'truckType', truckType));
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
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  ///
  /// * [String] customerName:
  ///
  /// * [String] truckType:
  Future<ApiResponseListLoadingSummaryRowDto?> getSummaryStatsOnly({ DateTime? fromDate, DateTime? toDate, String? customerName, String? truckType, }) async {
    final response = await getSummaryStatsOnlyWithHttpInfo( fromDate: fromDate, toDate: toDate, customerName: customerName, truckType: truckType, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListLoadingSummaryRowDto',) as ApiResponseListLoadingSummaryRowDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/dashboard/top-drivers' operation and returns the [Response].
  Future<Response> getTopDriversWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dashboard/top-drivers';

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

  Future<ApiResponseListTopDriverDto?> getTopDrivers() async {
    final response = await getTopDriversWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListTopDriverDto',) as ApiResponseListTopDriverDto;
    
    }
    return null;
  }
}
