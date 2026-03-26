//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AboutAppInfoControllerApi {
  AboutAppInfoControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/admin/about-app' operation and returns the [Response].
  Future<Response> getAboutInfoWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/about-app';

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

  Future<AboutAppInfo?> getAboutInfo() async {
    final response = await getAboutInfoWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AboutAppInfo',) as AboutAppInfo;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/about-app' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [AboutAppInfo] aboutAppInfo (required):
  Future<Response> saveAboutInfoWithHttpInfo(AboutAppInfo aboutAppInfo,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/about-app';

    // ignore: prefer_final_locals
    Object? postBody = aboutAppInfo;

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
  /// * [AboutAppInfo] aboutAppInfo (required):
  Future<AboutAppInfo?> saveAboutInfo(AboutAppInfo aboutAppInfo,) async {
    final response = await saveAboutInfoWithHttpInfo(aboutAppInfo,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'AboutAppInfo',) as AboutAppInfo;
    
    }
    return null;
  }
}
