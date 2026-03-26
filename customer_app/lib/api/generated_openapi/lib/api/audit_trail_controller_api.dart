//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AuditTrailControllerApi {
  AuditTrailControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/audit-trails' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [AuditTrail] auditTrail (required):
  Future<Response> createAuditTrailWithHttpInfo(AuditTrail auditTrail,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit-trails';

    // ignore: prefer_final_locals
    Object? postBody = auditTrail;

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
  /// * [AuditTrail] auditTrail (required):
  Future<AuditTrail?> createAuditTrail(AuditTrail auditTrail,) async {
    final response = await createAuditTrailWithHttpInfo(auditTrail,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AuditTrail',) as AuditTrail;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/audit-trails/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteAuditTrailWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit-trails/{id}'
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
  Future<void> deleteAuditTrail(int id,) async {
    final response = await deleteAuditTrailWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/admin/audit-trails' operation and returns the [Response].
  Future<Response> getAllAuditTrailsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit-trails';

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

  Future<List<AuditTrail>?> getAllAuditTrails() async {
    final response = await getAllAuditTrailsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AuditTrail>') as List)
        .cast<AuditTrail>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/audit-trails/action/{action}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] action (required):
  Future<Response> getAuditTrailsByActionWithHttpInfo(String action,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit-trails/action/{action}'
      .replaceAll('{action}', action);

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
  /// * [String] action (required):
  Future<List<AuditTrail>?> getAuditTrailsByAction(String action,) async {
    final response = await getAuditTrailsByActionWithHttpInfo(action,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AuditTrail>') as List)
        .cast<AuditTrail>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/audit-trails/date-range' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] startDate (required):
  ///
  /// * [String] endDate (required):
  Future<Response> getAuditTrailsByDateRangeWithHttpInfo(String startDate, String endDate,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit-trails/date-range';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'startDate', startDate));
      queryParams.addAll(_queryParams('', 'endDate', endDate));

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
  /// * [String] startDate (required):
  ///
  /// * [String] endDate (required):
  Future<List<AuditTrail>?> getAuditTrailsByDateRange(String startDate, String endDate,) async {
    final response = await getAuditTrailsByDateRangeWithHttpInfo(startDate, endDate,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AuditTrail>') as List)
        .cast<AuditTrail>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/audit-trails/resource/{resourceType}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] resourceType (required):
  Future<Response> getAuditTrailsByResourceTypeWithHttpInfo(String resourceType,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit-trails/resource/{resourceType}'
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
  Future<List<AuditTrail>?> getAuditTrailsByResourceType(String resourceType,) async {
    final response = await getAuditTrailsByResourceTypeWithHttpInfo(resourceType,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AuditTrail>') as List)
        .cast<AuditTrail>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/audit-trails/user/{userId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] userId (required):
  Future<Response> getAuditTrailsByUserWithHttpInfo(int userId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit-trails/user/{userId}'
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
  Future<List<AuditTrail>?> getAuditTrailsByUser(int userId,) async {
    final response = await getAuditTrailsByUserWithHttpInfo(userId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AuditTrail>') as List)
        .cast<AuditTrail>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/audit-trails/username/{username}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] username (required):
  Future<Response> getAuditTrailsByUsernameWithHttpInfo(String username,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit-trails/username/{username}'
      .replaceAll('{username}', username);

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
  /// * [String] username (required):
  Future<List<AuditTrail>?> getAuditTrailsByUsername(String username,) async {
    final response = await getAuditTrailsByUsernameWithHttpInfo(username,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AuditTrail>') as List)
        .cast<AuditTrail>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/audit-trails/user/{username}/action/{action}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] username (required):
  ///
  /// * [String] action (required):
  Future<Response> getAuditTrailsByUsernameAndActionWithHttpInfo(String username, String action,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/audit-trails/user/{username}/action/{action}'
      .replaceAll('{username}', username)
      .replaceAll('{action}', action);

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
  /// * [String] username (required):
  ///
  /// * [String] action (required):
  Future<List<AuditTrail>?> getAuditTrailsByUsernameAndAction(String username, String action,) async {
    final response = await getAuditTrailsByUsernameAndActionWithHttpInfo(username, action,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<AuditTrail>') as List)
        .cast<AuditTrail>()
        .toList(growable: false);

    }
    return null;
  }
}
