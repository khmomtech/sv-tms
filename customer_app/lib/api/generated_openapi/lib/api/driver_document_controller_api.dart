//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverDocumentControllerApi {
  DriverDocumentControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/drivers/{driverId}/documents' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [DriverDocumentCreateDto] driverDocumentCreateDto (required):
  Future<Response> createDocumentWithHttpInfo(int driverId, DriverDocumentCreateDto driverDocumentCreateDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = driverDocumentCreateDto;

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
  /// * [DriverDocumentCreateDto] driverDocumentCreateDto (required):
  Future<ApiResponseDriverDocument?> createDocument(int driverId, DriverDocumentCreateDto driverDocumentCreateDto,) async {
    final response = await createDocumentWithHttpInfo(driverId, driverDocumentCreateDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverDocument',) as ApiResponseDriverDocument;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/drivers/{driverId}/documents/{documentId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] documentId (required):
  Future<Response> deleteDocumentWithHttpInfo(int driverId, int documentId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/{documentId}'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{documentId}', documentId.toString());

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
  /// * [int] driverId (required):
  ///
  /// * [int] documentId (required):
  Future<ApiResponseString?> deleteDocument(int driverId, int documentId,) async {
    final response = await deleteDocumentWithHttpInfo(driverId, documentId,);
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

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/documents/{documentId}/download' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] documentId (required):
  ///
  /// * [String] disposition:
  Future<Response> downloadDriverDocumentWithHttpInfo(int driverId, int documentId, { String? disposition, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/{documentId}/download'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{documentId}', documentId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (disposition != null) {
      queryParams.addAll(_queryParams('', 'disposition', disposition));
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
  /// * [int] driverId (required):
  ///
  /// * [int] documentId (required):
  ///
  /// * [String] disposition:
  Future<MultipartFile?> downloadDriverDocument(int driverId, int documentId, { String? disposition, }) async {
    final response = await downloadDriverDocumentWithHttpInfo(driverId, documentId,  disposition: disposition, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MultipartFile',) as MultipartFile;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/documents/{documentId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] documentId (required):
  Future<Response> getDocumentWithHttpInfo(int documentId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/documents/{documentId}'
      .replaceAll('{documentId}', documentId.toString());

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
  /// * [int] documentId (required):
  Future<ApiResponseDriverDocument?> getDocument(int documentId,) async {
    final response = await getDocumentWithHttpInfo(documentId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverDocument',) as ApiResponseDriverDocument;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/documents/{documentId}/audit' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] documentId (required):
  Future<Response> getDocumentAuditWithHttpInfo(int driverId, int documentId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/{documentId}/audit'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{documentId}', documentId.toString());

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
  ///
  /// * [int] documentId (required):
  Future<ApiResponseDocumentAuditDto?> getDocumentAudit(int driverId, int documentId,) async {
    final response = await getDocumentAuditWithHttpInfo(driverId, documentId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDocumentAuditDto',) as ApiResponseDocumentAuditDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/documents/category/{category}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [String] category (required):
  Future<Response> getDocumentsByCategoryWithHttpInfo(int driverId, String category,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/category/{category}'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{category}', category);

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
  ///
  /// * [String] category (required):
  Future<ApiResponseListDriverDocument?> getDocumentsByCategory(int driverId, String category,) async {
    final response = await getDocumentsByCategoryWithHttpInfo(driverId, category,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDriverDocument',) as ApiResponseListDriverDocument;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/documents' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> getDriverDocumentsWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents'
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
  Future<ApiResponseListDriverDocument?> getDriverDocuments(int driverId,) async {
    final response = await getDriverDocumentsWithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDriverDocument',) as ApiResponseListDriverDocument;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/documents/expired' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> getExpiredDocumentsWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/expired'
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
  Future<ApiResponseListDriverDocument?> getExpiredDocuments(int driverId,) async {
    final response = await getExpiredDocumentsWithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDriverDocument',) as ApiResponseListDriverDocument;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/documents/expiring' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> getExpiringDocumentsWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/expiring'
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
  Future<ApiResponseListDriverDocument?> getExpiringDocuments(int driverId,) async {
    final response = await getExpiringDocumentsWithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDriverDocument',) as ApiResponseListDriverDocument;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/documents/required' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> getRequiredDocumentsWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/required'
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
  Future<ApiResponseListDriverDocument?> getRequiredDocuments(int driverId,) async {
    final response = await getRequiredDocumentsWithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDriverDocument',) as ApiResponseListDriverDocument;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/drivers/{driverId}/documents/{documentId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] documentId (required):
  ///
  /// * [DriverDocumentUpdateDto] driverDocumentUpdateDto (required):
  Future<Response> updateDocumentWithHttpInfo(int driverId, int documentId, DriverDocumentUpdateDto driverDocumentUpdateDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/{documentId}'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{documentId}', documentId.toString());

    // ignore: prefer_final_locals
    Object? postBody = driverDocumentUpdateDto;

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
  /// * [int] documentId (required):
  ///
  /// * [DriverDocumentUpdateDto] driverDocumentUpdateDto (required):
  Future<ApiResponseDriverDocument?> updateDocument(int driverId, int documentId, DriverDocumentUpdateDto driverDocumentUpdateDto,) async {
    final response = await updateDocumentWithHttpInfo(driverId, documentId, driverDocumentUpdateDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverDocument',) as ApiResponseDriverDocument;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/drivers/{driverId}/documents/{documentId}/file' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] documentId (required):
  ///
  /// * [String] name:
  ///
  /// * [String] category:
  ///
  /// * [String] expiryDate:
  ///
  /// * [String] description:
  ///
  /// * [bool] isRequired:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> updateDocumentFileWithHttpInfo(int driverId, int documentId, { String? name, String? category, String? expiryDate, String? description, bool? isRequired, UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/{documentId}/file'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{documentId}', documentId.toString());

    // ignore: prefer_final_locals
    Object? postBody = updateDocumentFileRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (name != null) {
      queryParams.addAll(_queryParams('', 'name', name));
    }
    if (category != null) {
      queryParams.addAll(_queryParams('', 'category', category));
    }
    if (expiryDate != null) {
      queryParams.addAll(_queryParams('', 'expiryDate', expiryDate));
    }
    if (description != null) {
      queryParams.addAll(_queryParams('', 'description', description));
    }
    if (isRequired != null) {
      queryParams.addAll(_queryParams('', 'isRequired', isRequired));
    }

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
  /// * [int] documentId (required):
  ///
  /// * [String] name:
  ///
  /// * [String] category:
  ///
  /// * [String] expiryDate:
  ///
  /// * [String] description:
  ///
  /// * [bool] isRequired:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<ApiResponseDriverDocument?> updateDocumentFile(int driverId, int documentId, { String? name, String? category, String? expiryDate, String? description, bool? isRequired, UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await updateDocumentFileWithHttpInfo(driverId, documentId,  name: name, category: category, expiryDate: expiryDate, description: description, isRequired: isRequired, updateDocumentFileRequest: updateDocumentFileRequest, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverDocument',) as ApiResponseDriverDocument;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/drivers/{driverId}/documents/upload' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [String] name:
  ///
  /// * [String] category:
  ///
  /// * [String] expiryDate:
  ///
  /// * [String] description:
  ///
  /// * [bool] isRequired:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> uploadDocumentWithHttpInfo(int driverId, { String? name, String? category, String? expiryDate, String? description, bool? isRequired, UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/documents/upload'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = updateDocumentFileRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (name != null) {
      queryParams.addAll(_queryParams('', 'name', name));
    }
    if (category != null) {
      queryParams.addAll(_queryParams('', 'category', category));
    }
    if (expiryDate != null) {
      queryParams.addAll(_queryParams('', 'expiryDate', expiryDate));
    }
    if (description != null) {
      queryParams.addAll(_queryParams('', 'description', description));
    }
    if (isRequired != null) {
      queryParams.addAll(_queryParams('', 'isRequired', isRequired));
    }

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
  /// * [String] name:
  ///
  /// * [String] category:
  ///
  /// * [String] expiryDate:
  ///
  /// * [String] description:
  ///
  /// * [bool] isRequired:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<ApiResponseDriverDocument?> uploadDocument(int driverId, { String? name, String? category, String? expiryDate, String? description, bool? isRequired, UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await uploadDocumentWithHttpInfo(driverId,  name: name, category: category, expiryDate: expiryDate, description: description, isRequired: isRequired, updateDocumentFileRequest: updateDocumentFileRequest, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDriverDocument',) as ApiResponseDriverDocument;
    
    }
    return null;
  }
}
