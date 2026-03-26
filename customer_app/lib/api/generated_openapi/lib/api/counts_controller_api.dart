//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class CountsControllerApi {
  CountsControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/public/counts/drivers' operation and returns the [Response].
  Future<Response> driversCountWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/counts/drivers';

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

  Future<Map<String, int>?> driversCount() async {
    final response = await driversCountWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return Map<String, int>.from(await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Map<String, int>'),);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/drivers/count' operation and returns the [Response].
  Future<Response> driversCount1WithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/drivers/count';

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

  Future<Map<String, int>?> driversCount1() async {
    final response = await driversCount1WithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return Map<String, int>.from(await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Map<String, int>'),);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/public/counts/vehicles' operation and returns the [Response].
  Future<Response> vehiclesCountWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/counts/vehicles';

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

  Future<Map<String, int>?> vehiclesCount() async {
    final response = await vehiclesCountWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return Map<String, int>.from(await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Map<String, int>'),);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/vehicles/count' operation and returns the [Response].
  Future<Response> vehiclesCount1WithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/vehicles/count';

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

  Future<Map<String, int>?> vehiclesCount1() async {
    final response = await vehiclesCount1WithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return Map<String, int>.from(await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Map<String, int>'),);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/maintenance/work-orders/count' operation and returns the [Response].
  Future<Response> workOrdersCountWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/maintenance/work-orders/count';

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

  Future<Map<String, int>?> workOrdersCount() async {
    final response = await workOrdersCountWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return Map<String, int>.from(await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Map<String, int>'),);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/public/counts/work-orders' operation and returns the [Response].
  Future<Response> workOrdersCount1WithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/public/counts/work-orders';

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

  Future<Map<String, int>?> workOrdersCount1() async {
    final response = await workOrdersCount1WithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return Map<String, int>.from(await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Map<String, int>'),);

    }
    return null;
  }
}
