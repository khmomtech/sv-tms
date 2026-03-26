//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverLicenseControllerApi {
  DriverLicenseControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/driver-licenses/{driverId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [DriverLicenseDto] driverLicenseDto (required):
  Future<Response> addDriverLicenseWithHttpInfo(int driverId, DriverLicenseDto driverLicenseDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/driver-licenses/{driverId}'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = driverLicenseDto;

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
  /// * [int] driverId (required):
  ///
  /// * [DriverLicenseDto] driverLicenseDto (required):
  Future<ApiResponseDriverLicenseDto?> addDriverLicense(int driverId, DriverLicenseDto driverLicenseDto,) async {
    final response = await addDriverLicenseWithHttpInfo(driverId, driverLicenseDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverLicenseDto',) as ApiResponseDriverLicenseDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/driver-licenses/by-id/{licenseId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] licenseId (required):
  Future<Response> deleteLicenseByIdWithHttpInfo(int licenseId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/driver-licenses/by-id/{licenseId}'
      .replaceAll('{licenseId}', licenseId.toString());

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
  /// * [int] licenseId (required):
  Future<ApiResponseString?> deleteLicenseById(int licenseId,) async {
    final response = await deleteLicenseByIdWithHttpInfo(licenseId,);
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

  /// Performs an HTTP 'GET /api/admin/driver-licenses' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [bool] includeDeleted:
  Future<Response> getAllLicensesWithHttpInfo({ bool? includeDeleted, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/driver-licenses';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (includeDeleted != null) {
      queryParams.addAll(_queryParams('', 'includeDeleted', includeDeleted));
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
  /// * [bool] includeDeleted:
  Future<ApiResponseListDriverLicenseDto?> getAllLicenses({ bool? includeDeleted, }) async {
    final response = await getAllLicensesWithHttpInfo( includeDeleted: includeDeleted, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDriverLicenseDto',) as ApiResponseListDriverLicenseDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/driver-licenses/{driverId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> getLicenseByDriverIdWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/driver-licenses/{driverId}'
      .replaceAll('{driverId}', driverId.toString());

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
  /// * [int] driverId (required):
  Future<ApiResponseDriverLicenseDto?> getLicenseByDriverId(int driverId,) async {
    final response = await getLicenseByDriverIdWithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverLicenseDto',) as ApiResponseDriverLicenseDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/driver-licenses/{driverId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [DriverLicenseDto] driverLicenseDto (required):
  Future<Response> updateDriverLicenseWithHttpInfo(int driverId, DriverLicenseDto driverLicenseDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/driver-licenses/{driverId}'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = driverLicenseDto;

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
  /// * [int] driverId (required):
  ///
  /// * [DriverLicenseDto] driverLicenseDto (required):
  Future<ApiResponseDriverLicenseDto?> updateDriverLicense(int driverId, DriverLicenseDto driverLicenseDto,) async {
    final response = await updateDriverLicenseWithHttpInfo(driverId, driverLicenseDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverLicenseDto',) as ApiResponseDriverLicenseDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/driver-licenses/{driverId}/upload-back' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> uploadBackImageWithHttpInfo(int driverId, { UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/driver-licenses/{driverId}/upload-back'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = updateDocumentFileRequest;

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
  /// * [int] driverId (required):
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<ApiResponseString?> uploadBackImage(int driverId, { UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await uploadBackImageWithHttpInfo(driverId,  updateDocumentFileRequest: updateDocumentFileRequest, );
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

  /// Performs an HTTP 'POST /api/admin/driver-licenses/{driverId}/upload-front' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> uploadFrontImageWithHttpInfo(int driverId, { UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/driver-licenses/{driverId}/upload-front'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = updateDocumentFileRequest;

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
  /// * [int] driverId (required):
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<ApiResponseString?> uploadFrontImage(int driverId, { UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await uploadFrontImageWithHttpInfo(driverId,  updateDocumentFileRequest: updateDocumentFileRequest, );
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
}
