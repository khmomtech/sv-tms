//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class MaintenanceTaskTypeControllerApi {
  MaintenanceTaskTypeControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/maintenance-task-types' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [MaintenanceTaskTypeDto] maintenanceTaskTypeDto (required):
  Future<Response> create1WithHttpInfo(MaintenanceTaskTypeDto maintenanceTaskTypeDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-task-types';

    // ignore: prefer_final_locals
    Object? postBody = maintenanceTaskTypeDto;

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
  /// * [MaintenanceTaskTypeDto] maintenanceTaskTypeDto (required):
  Future<ApiResponseMaintenanceTaskTypeDto?> create1(MaintenanceTaskTypeDto maintenanceTaskTypeDto,) async {
    final response = await create1WithHttpInfo(maintenanceTaskTypeDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMaintenanceTaskTypeDto',) as ApiResponseMaintenanceTaskTypeDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/maintenance-task-types/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> delete1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-task-types/{id}'
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
  Future<ApiResponseVoid?> delete1(int id,) async {
    final response = await delete1WithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/maintenance-task-types/list' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] search:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getAll1WithHttpInfo({ String? search, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-task-types/list';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (search != null) {
      queryParams.addAll(_queryParams('', 'search', search));
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
  /// * [String] search:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageMaintenanceTaskTypeDto?> getAll1({ String? search, int? page, int? size, }) async {
    final response = await getAll1WithHttpInfo( search: search, page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageMaintenanceTaskTypeDto',) as ApiResponsePageMaintenanceTaskTypeDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/maintenance-task-types/all' operation and returns the [Response].
  Future<Response> getAllNoPageWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-task-types/all';

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

  Future<ApiResponseListMaintenanceTaskTypeDto?> getAllNoPage() async {
    final response = await getAllNoPageWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListMaintenanceTaskTypeDto',) as ApiResponseListMaintenanceTaskTypeDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/maintenance-task-types/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getById2WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-task-types/{id}'
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
  Future<ApiResponseMaintenanceTaskTypeDto?> getById2(int id,) async {
    final response = await getById2WithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMaintenanceTaskTypeDto',) as ApiResponseMaintenanceTaskTypeDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/maintenance-task-types/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [MaintenanceTaskTypeDto] maintenanceTaskTypeDto (required):
  Future<Response> update1WithHttpInfo(int id, MaintenanceTaskTypeDto maintenanceTaskTypeDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/maintenance-task-types/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = maintenanceTaskTypeDto;

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
  /// * [MaintenanceTaskTypeDto] maintenanceTaskTypeDto (required):
  Future<ApiResponseMaintenanceTaskTypeDto?> update1(int id, MaintenanceTaskTypeDto maintenanceTaskTypeDto,) async {
    final response = await update1WithHttpInfo(id, maintenanceTaskTypeDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMaintenanceTaskTypeDto',) as ApiResponseMaintenanceTaskTypeDto;
    
    }
    return null;
  }
}
