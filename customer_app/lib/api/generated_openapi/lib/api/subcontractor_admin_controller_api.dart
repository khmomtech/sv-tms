//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class SubcontractorAdminControllerApi {
  SubcontractorAdminControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/subcontractor-admins' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [AssignAdminRequest] assignAdminRequest (required):
  Future<Response> assignAdmin1WithHttpInfo(AssignAdminRequest assignAdminRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/subcontractor-admins';

    // ignore: prefer_final_locals
    Object? postBody = assignAdminRequest;

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
  /// * [AssignAdminRequest] assignAdminRequest (required):
  Future<ApiResponsePartnerAdmin?> assignAdmin1(AssignAdminRequest assignAdminRequest,) async {
    final response = await assignAdmin1WithHttpInfo(assignAdminRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePartnerAdmin',) as ApiResponsePartnerAdmin;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/subcontractor-admins/user/{userId}/companies/{companyId}/can-manage-drivers' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  ///
  /// * [int] companyId (required):
  Future<Response> canManageDrivers1WithHttpInfo(int userId, int companyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/subcontractor-admins/user/{userId}/companies/{companyId}/can-manage-drivers'
      .replaceAll('{userId}', userId.toString())
      .replaceAll('{companyId}', companyId.toString());

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
  ///
  /// * [int] companyId (required):
  Future<ApiResponseBoolean?> canManageDrivers1(int userId, int companyId,) async {
    final response = await canManageDrivers1WithHttpInfo(userId, companyId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseBoolean',) as ApiResponseBoolean;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/subcontractor-admins/company/{companyId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] companyId (required):
  Future<Response> getAdminsByCompany1WithHttpInfo(int companyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/subcontractor-admins/company/{companyId}'
      .replaceAll('{companyId}', companyId.toString());

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
  /// * [int] companyId (required):
  Future<ApiResponseListPartnerAdmin?> getAdminsByCompany1(int companyId,) async {
    final response = await getAdminsByCompany1WithHttpInfo(companyId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListPartnerAdmin',) as ApiResponseListPartnerAdmin;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/subcontractor-admins/user/{userId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  Future<Response> getCompaniesByUser1WithHttpInfo(int userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/subcontractor-admins/user/{userId}'
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
  Future<ApiResponseListPartnerAdmin?> getCompaniesByUser1(int userId,) async {
    final response = await getCompaniesByUser1WithHttpInfo(userId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListPartnerAdmin',) as ApiResponseListPartnerAdmin;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/subcontractor-admins/user/{userId}/managed-companies' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  Future<Response> getManagedCompanies1WithHttpInfo(int userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/subcontractor-admins/user/{userId}/managed-companies'
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
  Future<ApiResponseListLong?> getManagedCompanies1(int userId,) async {
    final response = await getManagedCompanies1WithHttpInfo(userId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListLong',) as ApiResponseListLong;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/subcontractor-admins/company/{companyId}/primary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] companyId (required):
  Future<Response> getPrimaryAdmin1WithHttpInfo(int companyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/subcontractor-admins/company/{companyId}/primary'
      .replaceAll('{companyId}', companyId.toString());

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
  /// * [int] companyId (required):
  Future<ApiResponsePartnerAdmin?> getPrimaryAdmin1(int companyId,) async {
    final response = await getPrimaryAdmin1WithHttpInfo(companyId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePartnerAdmin',) as ApiResponsePartnerAdmin;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/subcontractor-admins/{adminId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] adminId (required):
  Future<Response> removeAdmin1WithHttpInfo(int adminId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/subcontractor-admins/{adminId}'
      .replaceAll('{adminId}', adminId.toString());

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
  /// * [int] adminId (required):
  Future<ApiResponseVoid?> removeAdmin1(int adminId,) async {
    final response = await removeAdmin1WithHttpInfo(adminId,);
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

  /// Performs an HTTP 'PATCH /api/subcontractor-admins/{adminId}/permissions' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] adminId (required):
  ///
  /// * [UpdatePermissionsRequest] updatePermissionsRequest (required):
  Future<Response> updatePermissions1WithHttpInfo(int adminId, UpdatePermissionsRequest updatePermissionsRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/subcontractor-admins/{adminId}/permissions'
      .replaceAll('{adminId}', adminId.toString());

    // ignore: prefer_final_locals
    Object? postBody = updatePermissionsRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [int] adminId (required):
  ///
  /// * [UpdatePermissionsRequest] updatePermissionsRequest (required):
  Future<ApiResponsePartnerAdmin?> updatePermissions1(int adminId, UpdatePermissionsRequest updatePermissionsRequest,) async {
    final response = await updatePermissions1WithHttpInfo(adminId, updatePermissionsRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePartnerAdmin',) as ApiResponsePartnerAdmin;
    
    }
    return null;
  }
}
