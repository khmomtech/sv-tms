//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class UserSettingControllerApi {
  UserSettingControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/user-settings' operation and returns the [Response].
  Future<Response> getSettingsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/user-settings';

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

  Future<ApiResponseListUserSetting?> getSettings() async {
    final response = await getSettingsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListUserSetting',) as ApiResponseListUserSetting;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/user-settings/key/{key}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] key (required):
  Future<Response> getUserSettingByKeyWithHttpInfo(String key,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/user-settings/key/{key}'
      .replaceAll('{key}', key);

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
  /// * [String] key (required):
  Future<ApiResponseUserSetting?> getUserSettingByKey(String key,) async {
    final response = await getUserSettingByKeyWithHttpInfo(key,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseUserSetting',) as ApiResponseUserSetting;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/user-settings/update' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Map<String, String>] requestBody (required):
  Future<Response> updateUserSettingWithHttpInfo(Map<String, String> requestBody,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/user-settings/update';

    // ignore: prefer_final_locals
    Object? postBody = requestBody;

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
  /// * [Map<String, String>] requestBody (required):
  Future<ApiResponseUserSetting?> updateUserSetting(Map<String, String> requestBody,) async {
    final response = await updateUserSettingWithHttpInfo(requestBody,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseUserSetting',) as ApiResponseUserSetting;
    
    }
    return null;
  }
}
