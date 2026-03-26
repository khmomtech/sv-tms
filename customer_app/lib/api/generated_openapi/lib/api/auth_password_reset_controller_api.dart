//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AuthPasswordResetControllerApi {
  AuthPasswordResetControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/auth/forgot-password' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [ForgotPasswordRequest] forgotPasswordRequest (required):
  Future<Response> forgotPasswordWithHttpInfo(ForgotPasswordRequest forgotPasswordRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/forgot-password';

    // ignore: prefer_final_locals
    Object? postBody = forgotPasswordRequest;

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
  /// * [ForgotPasswordRequest] forgotPasswordRequest (required):
  Future<Object?> forgotPassword(ForgotPasswordRequest forgotPasswordRequest,) async {
    final response = await forgotPasswordWithHttpInfo(forgotPasswordRequest,);
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

  /// Performs an HTTP 'POST /api/auth/reset-password' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [ResetPasswordRequest] resetPasswordRequest (required):
  Future<Response> resetPasswordWithHttpInfo(ResetPasswordRequest resetPasswordRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/auth/reset-password';

    // ignore: prefer_final_locals
    Object? postBody = resetPasswordRequest;

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
  /// * [ResetPasswordRequest] resetPasswordRequest (required):
  Future<Object?> resetPassword(ResetPasswordRequest resetPasswordRequest,) async {
    final response = await resetPasswordWithHttpInfo(resetPasswordRequest,);
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
}
