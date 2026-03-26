//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class RoleControllerApi {
  RoleControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/roles/{roleId}/permissions/{permissionId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] roleId (required):
  ///
  /// * [int] permissionId (required):
  Future<Response> addPermissionToRoleWithHttpInfo(int roleId, int permissionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/roles/{roleId}/permissions/{permissionId}'
      .replaceAll('{roleId}', roleId.toString())
      .replaceAll('{permissionId}', permissionId.toString());

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

  /// Parameters:
  ///
  /// * [int] roleId (required):
  ///
  /// * [int] permissionId (required):
  Future<Role?> addPermissionToRole(int roleId, int permissionId,) async {
    final response = await addPermissionToRoleWithHttpInfo(roleId, permissionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Role',) as Role;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/roles' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Role] role (required):
  Future<Response> createRoleWithHttpInfo(Role role,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/roles';

    // ignore: prefer_final_locals
    Object? postBody = role;

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
  /// * [Role] role (required):
  Future<Role?> createRole(Role role,) async {
    final response = await createRoleWithHttpInfo(role,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Role',) as Role;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/roles/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteRoleWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/roles/{id}'
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
  Future<void> deleteRole(int id,) async {
    final response = await deleteRoleWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/admin/roles' operation and returns the [Response].
  Future<Response> getAllRolesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/roles';

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

  Future<List<Role>?> getAllRoles() async {
    final response = await getAllRolesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Role>') as List)
        .cast<Role>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/roles/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getRoleByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/roles/{id}'
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
  Future<Role?> getRoleById(int id,) async {
    final response = await getRoleByIdWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Role',) as Role;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/roles/{roleId}/permissions' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] roleId (required):
  Future<Response> getRolePermissionsWithHttpInfo(int roleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/roles/{roleId}/permissions'
      .replaceAll('{roleId}', roleId.toString());

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
  /// * [int] roleId (required):
  Future<Set<Permission>?> getRolePermissions(int roleId,) async {
    final response = await getRolePermissionsWithHttpInfo(roleId,);
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

  /// Performs an HTTP 'DELETE /api/admin/roles/{roleId}/permissions/{permissionId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] roleId (required):
  ///
  /// * [int] permissionId (required):
  Future<Response> removePermissionFromRoleWithHttpInfo(int roleId, int permissionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/roles/{roleId}/permissions/{permissionId}'
      .replaceAll('{roleId}', roleId.toString())
      .replaceAll('{permissionId}', permissionId.toString());

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
  /// * [int] roleId (required):
  ///
  /// * [int] permissionId (required):
  Future<Role?> removePermissionFromRole(int roleId, int permissionId,) async {
    final response = await removePermissionFromRoleWithHttpInfo(roleId, permissionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Role',) as Role;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/roles/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [Role] role (required):
  Future<Response> updateRoleWithHttpInfo(int id, Role role,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/roles/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = role;

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
  /// * [Role] role (required):
  Future<Role?> updateRole(int id, Role role,) async {
    final response = await updateRoleWithHttpInfo(id, role,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Role',) as Role;
    
    }
    return null;
  }
}
