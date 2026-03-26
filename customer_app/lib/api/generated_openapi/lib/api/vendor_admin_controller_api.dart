//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class VendorAdminControllerApi {
  VendorAdminControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/vendor-admins' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [AssignAdminRequest] assignAdminRequest (required):
  Future<Response> assignAdminWithHttpInfo(AssignAdminRequest assignAdminRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vendor-admins';

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
  Future<ApiResponsePartnerAdmin?> assignAdmin(AssignAdminRequest assignAdminRequest,) async {
    final response = await assignAdminWithHttpInfo(assignAdminRequest,);
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

  /// Performs an HTTP 'GET /api/vendor-admins/user/{userId}/companies/{companyId}/can-manage-drivers' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  ///
  /// * [int] companyId (required):
  Future<Response> canManageDriversWithHttpInfo(int userId, int companyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vendor-admins/user/{userId}/companies/{companyId}/can-manage-drivers'
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
  Future<ApiResponseBoolean?> canManageDrivers(int userId, int companyId,) async {
    final response = await canManageDriversWithHttpInfo(userId, companyId,);
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

  /// Performs an HTTP 'GET /api/vendor-admins/company/{companyId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] companyId (required):
  Future<Response> getAdminsByCompanyWithHttpInfo(int companyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vendor-admins/company/{companyId}'
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
  Future<ApiResponseListPartnerAdmin?> getAdminsByCompany(int companyId,) async {
    final response = await getAdminsByCompanyWithHttpInfo(companyId,);
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

  /// Performs an HTTP 'GET /api/vendor-admins/user/{userId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  Future<Response> getCompaniesByUserWithHttpInfo(int userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vendor-admins/user/{userId}'
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
  Future<ApiResponseListPartnerAdmin?> getCompaniesByUser(int userId,) async {
    final response = await getCompaniesByUserWithHttpInfo(userId,);
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

  /// Performs an HTTP 'GET /api/vendor-admins/user/{userId}/managed-companies' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  Future<Response> getManagedCompaniesWithHttpInfo(int userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vendor-admins/user/{userId}/managed-companies'
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
  Future<ApiResponseListLong?> getManagedCompanies(int userId,) async {
    final response = await getManagedCompaniesWithHttpInfo(userId,);
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

  /// Performs an HTTP 'GET /api/vendor-admins/company/{companyId}/primary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] companyId (required):
  Future<Response> getPrimaryAdminWithHttpInfo(int companyId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vendor-admins/company/{companyId}/primary'
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
  Future<ApiResponsePartnerAdmin?> getPrimaryAdmin(int companyId,) async {
    final response = await getPrimaryAdminWithHttpInfo(companyId,);
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

  /// Performs an HTTP 'DELETE /api/vendor-admins/{adminId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] adminId (required):
  Future<Response> removeAdminWithHttpInfo(int adminId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vendor-admins/{adminId}'
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
  Future<ApiResponseVoid?> removeAdmin(int adminId,) async {
    final response = await removeAdminWithHttpInfo(adminId,);
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

  /// Performs an HTTP 'PATCH /api/vendor-admins/{adminId}/permissions' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] adminId (required):
  ///
  /// * [UpdatePermissionsRequest] updatePermissionsRequest (required):
  Future<Response> updatePermissionsWithHttpInfo(int adminId, UpdatePermissionsRequest updatePermissionsRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/vendor-admins/{adminId}/permissions'
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
  Future<ApiResponsePartnerAdmin?> updatePermissions(int adminId, UpdatePermissionsRequest updatePermissionsRequest,) async {
    final response = await updatePermissionsWithHttpInfo(adminId, updatePermissionsRequest,);
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
