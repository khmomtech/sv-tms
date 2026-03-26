//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class PartsMasterControllerApi {
  PartsMasterControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/admin/parts/stats/active-count' operation and returns the [Response].
  Future<Response> countActivePartsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts/stats/active-count';

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

  Future<int?> countActiveParts() async {
    final response = await countActivePartsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'int',) as int;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/parts' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [PartsMasterDto] partsMasterDto (required):
  Future<Response> createPartWithHttpInfo(PartsMasterDto partsMasterDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts';

    // ignore: prefer_final_locals
    Object? postBody = partsMasterDto;

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
  /// * [PartsMasterDto] partsMasterDto (required):
  Future<PartsMasterDto?> createPart(PartsMasterDto partsMasterDto,) async {
    final response = await createPartWithHttpInfo(partsMasterDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PartsMasterDto',) as PartsMasterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PATCH /api/admin/parts/{id}/deactivate' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deactivatePartWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts/{id}/deactivate'
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
  Future<void> deactivatePart(int id,) async {
    final response = await deactivatePartWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'DELETE /api/admin/parts/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deletePartWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts/{id}'
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
  Future<void> deletePart(int id,) async {
    final response = await deletePartWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/admin/parts/categories' operation and returns the [Response].
  Future<Response> getAllCategoriesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts/categories';

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

  Future<List<String>?> getAllCategories() async {
    final response = await getAllCategoriesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<String>') as List)
        .cast<String>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/parts' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [bool] active:
  Future<Response> getAllPartsWithHttpInfo(Pageable pageable, { bool? active, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (active != null) {
      queryParams.addAll(_queryParams('', 'active', active));
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
  /// * [bool] active:
  Future<PagePartsMasterDto?> getAllParts(Pageable pageable, { bool? active, }) async {
    final response = await getAllPartsWithHttpInfo(pageable,  active: active, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PagePartsMasterDto',) as PagePartsMasterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/parts/code/{partCode}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] partCode (required):
  Future<Response> getPartByCodeWithHttpInfo(String partCode,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts/code/{partCode}'
      .replaceAll('{partCode}', partCode);

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
  /// * [String] partCode (required):
  Future<PartsMasterDto?> getPartByCode(String partCode,) async {
    final response = await getPartByCodeWithHttpInfo(partCode,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PartsMasterDto',) as PartsMasterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/parts/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getPartByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts/{id}'
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
  Future<PartsMasterDto?> getPartById(int id,) async {
    final response = await getPartByIdWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PartsMasterDto',) as PartsMasterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/parts/category/{category}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] category (required):
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [bool] active:
  Future<Response> getPartsByCategoryWithHttpInfo(String category, Pageable pageable, { bool? active, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts/category/{category}'
      .replaceAll('{category}', category);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (active != null) {
      queryParams.addAll(_queryParams('', 'active', active));
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
  /// * [String] category (required):
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [bool] active:
  Future<PagePartsMasterDto?> getPartsByCategory(String category, Pageable pageable, { bool? active, }) async {
    final response = await getPartsByCategoryWithHttpInfo(category, pageable,  active: active, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PagePartsMasterDto',) as PagePartsMasterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/parts/search' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [String] keyword:
  ///
  /// * [String] category:
  Future<Response> searchPartsWithHttpInfo(Pageable pageable, { String? keyword, String? category, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (keyword != null) {
      queryParams.addAll(_queryParams('', 'keyword', keyword));
    }
    if (category != null) {
      queryParams.addAll(_queryParams('', 'category', category));
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
  /// * [String] keyword:
  ///
  /// * [String] category:
  Future<PagePartsMasterDto?> searchParts(Pageable pageable, { String? keyword, String? category, }) async {
    final response = await searchPartsWithHttpInfo(pageable,  keyword: keyword, category: category, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PagePartsMasterDto',) as PagePartsMasterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/parts/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [PartsMasterDto] partsMasterDto (required):
  Future<Response> updatePartWithHttpInfo(int id, PartsMasterDto partsMasterDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/parts/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = partsMasterDto;

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
  /// * [PartsMasterDto] partsMasterDto (required):
  Future<PartsMasterDto?> updatePart(int id, PartsMasterDto partsMasterDto,) async {
    final response = await updatePartWithHttpInfo(id, partsMasterDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PartsMasterDto',) as PartsMasterDto;
    
    }
    return null;
  }
}
