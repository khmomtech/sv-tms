//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class PartnerCompanyControllerApi {
  PartnerCompanyControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/partners' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [PartnerCompany] partnerCompany (required):
  Future<Response> createPartnerWithHttpInfo(PartnerCompany partnerCompany,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners';

    // ignore: prefer_final_locals
    Object? postBody = partnerCompany;

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
  /// * [PartnerCompany] partnerCompany (required):
  Future<ApiResponsePartnerCompany?> createPartner(PartnerCompany partnerCompany,) async {
    final response = await createPartnerWithHttpInfo(partnerCompany,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePartnerCompany',) as ApiResponsePartnerCompany;
    
    }
    return null;
  }

  /// Performs an HTTP 'PATCH /api/partners/{id}/deactivate' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deactivatePartnerWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/{id}/deactivate'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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
  Future<ApiResponseVoid?> deactivatePartner(int id,) async {
    final response = await deactivatePartnerWithHttpInfo(id,);
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

  /// Performs an HTTP 'DELETE /api/partners/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deletePartnerWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/{id}'
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
  Future<ApiResponseVoid?> deletePartner(int id,) async {
    final response = await deletePartnerWithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/partners/generate-code' operation and returns the [Response].
  Future<Response> generateCompanyCodeWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/generate-code';

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

  Future<ApiResponseString?> generateCompanyCode() async {
    final response = await generateCompanyCodeWithHttpInfo();
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

  /// Performs an HTTP 'GET /api/partners/active' operation and returns the [Response].
  Future<Response> getActivePartnersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/active';

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

  Future<ApiResponseListPartnerCompany?> getActivePartners() async {
    final response = await getActivePartnersWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListPartnerCompany',) as ApiResponseListPartnerCompany;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/partners' operation and returns the [Response].
  Future<Response> getAllPartnersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners';

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

  Future<ApiResponseListPartnerCompany?> getAllPartners() async {
    final response = await getAllPartnersWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListPartnerCompany',) as ApiResponseListPartnerCompany;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/partners/code/{code}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] code (required):
  Future<Response> getPartnerByCodeWithHttpInfo(String code,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/code/{code}'
      .replaceAll('{code}', code);

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
  /// * [String] code (required):
  Future<ApiResponsePartnerCompany?> getPartnerByCode(String code,) async {
    final response = await getPartnerByCodeWithHttpInfo(code,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePartnerCompany',) as ApiResponsePartnerCompany;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/partners/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getPartnerByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/{id}'
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
  Future<ApiResponsePartnerCompany?> getPartnerById(int id,) async {
    final response = await getPartnerByIdWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePartnerCompany',) as ApiResponsePartnerCompany;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/partners/type/{type}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] type (required):
  Future<Response> getPartnersByTypeWithHttpInfo(String type,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/type/{type}'
      .replaceAll('{type}', type);

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
  /// * [String] type (required):
  Future<ApiResponseListPartnerCompany?> getPartnersByType(String type,) async {
    final response = await getPartnersByTypeWithHttpInfo(type,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListPartnerCompany',) as ApiResponseListPartnerCompany;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/partners/search' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] query (required):
  Future<Response> searchPartnersWithHttpInfo(String query,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'query', query));

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
  /// * [String] query (required):
  Future<ApiResponseListPartnerCompany?> searchPartners(String query,) async {
    final response = await searchPartnersWithHttpInfo(query,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListPartnerCompany',) as ApiResponseListPartnerCompany;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/partners/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [PartnerCompany] partnerCompany (required):
  Future<Response> updatePartnerWithHttpInfo(int id, PartnerCompany partnerCompany,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/partners/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = partnerCompany;

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
  /// * [PartnerCompany] partnerCompany (required):
  Future<ApiResponsePartnerCompany?> updatePartner(int id, PartnerCompany partnerCompany,) async {
    final response = await updatePartnerWithHttpInfo(id, partnerCompany,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePartnerCompany',) as ApiResponsePartnerCompany;
    
    }
    return null;
  }
}
