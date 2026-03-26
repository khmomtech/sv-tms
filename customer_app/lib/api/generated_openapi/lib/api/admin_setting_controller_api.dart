//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AdminSettingControllerApi {
  AdminSettingControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/settings/bulk' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SettingBulkWriteRequest] settingBulkWriteRequest (required):
  Future<Response> bulkWithHttpInfo(SettingBulkWriteRequest settingBulkWriteRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/settings/bulk';

    // ignore: prefer_final_locals
    Object? postBody = settingBulkWriteRequest;

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
  /// * [SettingBulkWriteRequest] settingBulkWriteRequest (required):
  Future<List<SettingReadResponse>?> bulk(SettingBulkWriteRequest settingBulkWriteRequest,) async {
    final response = await bulkWithHttpInfo(settingBulkWriteRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<SettingReadResponse>') as List)
        .cast<SettingReadResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/settings/value' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] groupCode (required):
  ///
  /// * [String] keyCode (required):
  ///
  /// * [String] scope:
  ///
  /// * [String] scopeRef:
  Future<Response> getValueWithHttpInfo(String groupCode, String keyCode, { String? scope, String? scopeRef, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/settings/value';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'groupCode', groupCode));
      queryParams.addAll(_queryParams('', 'keyCode', keyCode));
    if (scope != null) {
      queryParams.addAll(_queryParams('', 'scope', scope));
    }
    if (scopeRef != null) {
      queryParams.addAll(_queryParams('', 'scopeRef', scopeRef));
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
  /// * [String] groupCode (required):
  ///
  /// * [String] keyCode (required):
  ///
  /// * [String] scope:
  ///
  /// * [String] scopeRef:
  Future<Object?> getValue(String groupCode, String keyCode, { String? scope, String? scopeRef, }) async {
    final response = await getValueWithHttpInfo(groupCode, keyCode,  scope: scope, scopeRef: scopeRef, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Object',) as Object;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/settings/import' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] body (required):
  ///
  /// * [String] scope:
  ///
  /// * [String] scopeRef:
  ///
  /// * [bool] apply:
  Future<Response> importJsonWithHttpInfo(String body, { String? scope, String? scopeRef, bool? apply, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/settings/import';

    // ignore: prefer_final_locals
    Object? postBody = body;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (scope != null) {
      queryParams.addAll(_queryParams('', 'scope', scope));
    }
    if (scopeRef != null) {
      queryParams.addAll(_queryParams('', 'scopeRef', scopeRef));
    }
    if (apply != null) {
      queryParams.addAll(_queryParams('', 'apply', apply));
    }

    const contentTypes = <String>['application/octet-stream'];


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
  /// * [String] body (required):
  ///
  /// * [String] scope:
  ///
  /// * [String] scopeRef:
  ///
  /// * [bool] apply:
  Future<List<SettingWriteRequest>?> importJson(String body, { String? scope, String? scopeRef, bool? apply, }) async {
    final response = await importJsonWithHttpInfo(body,  scope: scope, scopeRef: scopeRef, apply: apply, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<SettingWriteRequest>') as List)
        .cast<SettingWriteRequest>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/settings/values' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] groupCode (required):
  ///
  /// * [String] scope:
  ///
  /// * [String] scopeRef:
  ///
  /// * [bool] includeSecrets:
  Future<Response> listValuesWithHttpInfo(String groupCode, { String? scope, String? scopeRef, bool? includeSecrets, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/settings/values';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'groupCode', groupCode));
    if (scope != null) {
      queryParams.addAll(_queryParams('', 'scope', scope));
    }
    if (scopeRef != null) {
      queryParams.addAll(_queryParams('', 'scopeRef', scopeRef));
    }
    if (includeSecrets != null) {
      queryParams.addAll(_queryParams('', 'includeSecrets', includeSecrets));
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
  /// * [String] groupCode (required):
  ///
  /// * [String] scope:
  ///
  /// * [String] scopeRef:
  ///
  /// * [bool] includeSecrets:
  Future<List<SettingReadResponse>?> listValues(String groupCode, { String? scope, String? scopeRef, bool? includeSecrets, }) async {
    final response = await listValuesWithHttpInfo(groupCode,  scope: scope, scopeRef: scopeRef, includeSecrets: includeSecrets, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<SettingReadResponse>') as List)
        .cast<SettingReadResponse>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/settings/value' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SettingWriteRequest] settingWriteRequest (required):
  Future<Response> upsertWithHttpInfo(SettingWriteRequest settingWriteRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/settings/value';

    // ignore: prefer_final_locals
    Object? postBody = settingWriteRequest;

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
  /// * [SettingWriteRequest] settingWriteRequest (required):
  Future<SettingReadResponse?> upsert(SettingWriteRequest settingWriteRequest,) async {
    final response = await upsertWithHttpInfo(settingWriteRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'SettingReadResponse',) as SettingReadResponse;
    
    }
    return null;
  }
}
