//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverIssueControllerApi {
  DriverIssueControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'DELETE /api/driver/issues/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteIssueWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/issues/{id}'
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
  Future<ApiResponseVoid?> deleteIssue(int id,) async {
    final response = await deleteIssueWithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/driver/issues/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getById1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/issues/{id}'
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
  Future<ApiResponseDriverIssueDto?> getById1(int id,) async {
    final response = await getById1WithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverIssueDto',) as ApiResponseDriverIssueDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/issues/{driverId}/paged' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [String] status:
  ///
  /// * [String] type:
  ///
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  Future<Response> getIssuesByDriverIdPagedWithHttpInfo(int driverId, Pageable pageable, { String? status, String? type, DateTime? fromDate, DateTime? toDate, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/issues/{driverId}/paged'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (type != null) {
      queryParams.addAll(_queryParams('', 'type', type));
    }
    if (fromDate != null) {
      queryParams.addAll(_queryParams('', 'fromDate', fromDate));
    }
    if (toDate != null) {
      queryParams.addAll(_queryParams('', 'toDate', toDate));
    }
      queryParams.addAll(_queryParams('', 'pageable', pageable));

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
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [String] status:
  ///
  /// * [String] type:
  ///
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  Future<ApiResponsePageDriverIssueDto?> getIssuesByDriverIdPaged(int driverId, Pageable pageable, { String? status, String? type, DateTime? fromDate, DateTime? toDate, }) async {
    final response = await getIssuesByDriverIdPagedWithHttpInfo(driverId, pageable,  status: status, type: type, fromDate: fromDate, toDate: toDate, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageDriverIssueDto',) as ApiResponsePageDriverIssueDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/issues/paged' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [String] status:
  ///
  /// * [String] type:
  ///
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  Future<Response> getIssuesByDriverPagedWithHttpInfo(Pageable pageable, { String? status, String? type, DateTime? fromDate, DateTime? toDate, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/issues/paged';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (type != null) {
      queryParams.addAll(_queryParams('', 'type', type));
    }
    if (fromDate != null) {
      queryParams.addAll(_queryParams('', 'fromDate', fromDate));
    }
    if (toDate != null) {
      queryParams.addAll(_queryParams('', 'toDate', toDate));
    }
      queryParams.addAll(_queryParams('', 'pageable', pageable));

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
  /// * [Pageable] pageable (required):
  ///
  /// * [String] status:
  ///
  /// * [String] type:
  ///
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  Future<ApiResponsePageDriverIssueDto?> getIssuesByDriverPaged(Pageable pageable, { String? status, String? type, DateTime? fromDate, DateTime? toDate, }) async {
    final response = await getIssuesByDriverPagedWithHttpInfo(pageable,  status: status, type: type, fromDate: fromDate, toDate: toDate, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageDriverIssueDto',) as ApiResponsePageDriverIssueDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/issues' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [SubmitIssueRequest] payload (required):
  ///
  /// * [List<MultipartFile>] images:
  Future<Response> submitIssueWithHttpInfo(SubmitIssueRequest payload, { List<MultipartFile>? images, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/issues';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (payload != null) {
      hasFields = true;
      mp.fields[r'payload'] = parameterToString(payload);
    }
    if (images != null) {
      hasFields = true;
      mp.fields[r'images'] = images.field;
      mp.files.add(images);
    }
    if (hasFields) {
      postBody = mp;
    }

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
  /// * [SubmitIssueRequest] payload (required):
  ///
  /// * [List<MultipartFile>] images:
  Future<ApiResponseDriverIssueDto?> submitIssue(SubmitIssueRequest payload, { List<MultipartFile>? images, }) async {
    final response = await submitIssueWithHttpInfo(payload,  images: images, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverIssueDto',) as ApiResponseDriverIssueDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/driver/issues/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [UpdateIssueRequest] updateIssueRequest (required):
  Future<Response> updateIssueWithHttpInfo(int id, UpdateIssueRequest updateIssueRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/issues/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = updateIssueRequest;

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
  /// * [UpdateIssueRequest] updateIssueRequest (required):
  Future<ApiResponseDriverIssueDto?> updateIssue(int id, UpdateIssueRequest updateIssueRequest,) async {
    final response = await updateIssueWithHttpInfo(id, updateIssueRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverIssueDto',) as ApiResponseDriverIssueDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PATCH /api/driver/issues/{id}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [UpdateStatusRequest] updateStatusRequest (required):
  Future<Response> updateStatusWithHttpInfo(int id, UpdateStatusRequest updateStatusRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/issues/{id}/status'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = updateStatusRequest;

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
  /// * [int] id (required):
  ///
  /// * [UpdateStatusRequest] updateStatusRequest (required):
  Future<ApiResponseDriverIssueDto?> updateStatus(int id, UpdateStatusRequest updateStatusRequest,) async {
    final response = await updateStatusWithHttpInfo(id, updateStatusRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverIssueDto',) as ApiResponseDriverIssueDto;
    
    }
    return null;
  }
}
