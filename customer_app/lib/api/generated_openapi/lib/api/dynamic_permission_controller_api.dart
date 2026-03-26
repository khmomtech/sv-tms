//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DynamicPermissionControllerApi {
  DynamicPermissionControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/admin/dynamic-permissions/exists/{name}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] name (required):
  Future<Response> checkPermissionExistsWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dynamic-permissions/exists/{name}'
      .replaceAll('{name}', name);

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
  /// * [String] name (required):
  Future<ApiResponseMapStringBoolean?> checkPermissionExists(String name,) async {
    final response = await checkPermissionExistsWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMapStringBoolean',) as ApiResponseMapStringBoolean;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/dynamic-permissions/clear-cache' operation and returns the [Response].
  Future<Response> clearCacheWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dynamic-permissions/clear-cache';

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

  Future<ApiResponseString?> clearCache() async {
    final response = await clearCacheWithHttpInfo();
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

  /// Performs an HTTP 'POST /api/admin/dynamic-permissions' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [CreatePermissionRequest] createPermissionRequest (required):
  Future<Response> createPermission1WithHttpInfo(CreatePermissionRequest createPermissionRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dynamic-permissions';

    // ignore: prefer_final_locals
    Object? postBody = createPermissionRequest;

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
  /// * [CreatePermissionRequest] createPermissionRequest (required):
  Future<ApiResponsePermission?> createPermission1(CreatePermissionRequest createPermissionRequest,) async {
    final response = await createPermission1WithHttpInfo(createPermissionRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePermission',) as ApiResponsePermission;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/dynamic-permissions/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deletePermission1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dynamic-permissions/{id}'
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
  Future<ApiResponseString?> deletePermission1(int id,) async {
    final response = await deletePermission1WithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/dynamic-permissions/names' operation and returns the [Response].
  Future<Response> getAllPermissionNamesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dynamic-permissions/names';

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

  Future<ApiResponseSetString?> getAllPermissionNames() async {
    final response = await getAllPermissionNamesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseSetString',) as ApiResponseSetString;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/dynamic-permissions/by-resource/{resourceType}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] resourceType (required):
  Future<Response> getPermissionsByResourceWithHttpInfo(String resourceType,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dynamic-permissions/by-resource/{resourceType}'
      .replaceAll('{resourceType}', resourceType);

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
  /// * [String] resourceType (required):
  Future<ApiResponseListPermission?> getPermissionsByResource(String resourceType,) async {
    final response = await getPermissionsByResourceWithHttpInfo(resourceType,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListPermission',) as ApiResponseListPermission;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/dynamic-permissions/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [UpdatePermissionRequest] updatePermissionRequest (required):
  Future<Response> updatePermission1WithHttpInfo(int id, UpdatePermissionRequest updatePermissionRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dynamic-permissions/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = updatePermissionRequest;

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
  /// * [UpdatePermissionRequest] updatePermissionRequest (required):
  Future<ApiResponsePermission?> updatePermission1(int id, UpdatePermissionRequest updatePermissionRequest,) async {
    final response = await updatePermission1WithHttpInfo(id, updatePermissionRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePermission',) as ApiResponsePermission;
    
    }
    return null;
  }
}
