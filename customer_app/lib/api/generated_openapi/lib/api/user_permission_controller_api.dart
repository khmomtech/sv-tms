//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class UserPermissionControllerApi {
  UserPermissionControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/user-permissions/assign' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  ///
  /// * [int] permissionId (required):
  Future<Response> assignPermissionToUserWithHttpInfo(int userId, int permissionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/user-permissions/assign';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'userId', userId));
      queryParams.addAll(_queryParams('', 'permissionId', permissionId));

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
  /// * [int] userId (required):
  ///
  /// * [int] permissionId (required):
  Future<String?> assignPermissionToUser(int userId, int permissionId,) async {
    final response = await assignPermissionToUserWithHttpInfo(userId, permissionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'String',) as String;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/user-permissions/assign-by-name' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  ///
  /// * [String] permissionName (required):
  Future<Response> assignPermissionToUserByNameWithHttpInfo(int userId, String permissionName,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/user-permissions/assign-by-name';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'userId', userId));
      queryParams.addAll(_queryParams('', 'permissionName', permissionName));

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
  /// * [int] userId (required):
  ///
  /// * [String] permissionName (required):
  Future<String?> assignPermissionToUserByName(int userId, String permissionName,) async {
    final response = await assignPermissionToUserByNameWithHttpInfo(userId, permissionName,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'String',) as String;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/user-permissions/me/effective' operation and returns the [Response].
  Future<Response> getCurrentUserPermissionsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/user-permissions/me/effective';

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

  Future<UserPermissionSummaryDto?> getCurrentUserPermissions() async {
    final response = await getCurrentUserPermissionsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UserPermissionSummaryDto',) as UserPermissionSummaryDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/user-permissions/user/{userId}/effective' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  Future<Response> getEffectivePermissionsWithHttpInfo(int userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/user-permissions/user/{userId}/effective'
      .replaceAll('{userId}', userId.toString());

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
  /// * [int] userId (required):
  Future<UserPermissionSummaryDto?> getEffectivePermissions(int userId,) async {
    final response = await getEffectivePermissionsWithHttpInfo(userId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UserPermissionSummaryDto',) as UserPermissionSummaryDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/user-permissions/user/{userId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  Future<Response> getUserPermissionsWithHttpInfo(int userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/user-permissions/user/{userId}'
      .replaceAll('{userId}', userId.toString());

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
  /// * [int] userId (required):
  Future<Set<Permission>?> getUserPermissions(int userId,) async {
    final response = await getUserPermissionsWithHttpInfo(userId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'Set<Permission>') as List)
        .cast<Permission>()
        .toSet();

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/user-permissions/users-with-permission' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] permissionName (required):
  Future<Response> getUsersWithPermissionWithHttpInfo(String permissionName,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/user-permissions/users-with-permission';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'permissionName', permissionName));

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
  /// * [String] permissionName (required):
  Future<List<User>?> getUsersWithPermission(String permissionName,) async {
    final response = await getUsersWithPermissionWithHttpInfo(permissionName,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<User>') as List)
        .cast<User>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/user-permissions/remove' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  ///
  /// * [int] permissionId (required):
  Future<Response> removePermissionFromUserWithHttpInfo(int userId, int permissionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/user-permissions/remove';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'userId', userId));
      queryParams.addAll(_queryParams('', 'permissionId', permissionId));

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
  /// * [int] userId (required):
  ///
  /// * [int] permissionId (required):
  Future<String?> removePermissionFromUser(int userId, int permissionId,) async {
    final response = await removePermissionFromUserWithHttpInfo(userId, permissionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'String',) as String;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/user-permissions/user/{userId}/has-permission' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  ///
  /// * [String] permissionName (required):
  Future<Response> userHasPermissionWithHttpInfo(int userId, String permissionName,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/user-permissions/user/{userId}/has-permission'
      .replaceAll('{userId}', userId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'permissionName', permissionName));

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
  /// * [int] userId (required):
  ///
  /// * [String] permissionName (required):
  Future<bool?> userHasPermission(int userId, String permissionName,) async {
    final response = await userHasPermissionWithHttpInfo(userId, permissionName,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'bool',) as bool;
    
    }
    return null;
  }
}
