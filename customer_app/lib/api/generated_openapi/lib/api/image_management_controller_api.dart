//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ImageManagementControllerApi {
  ImageManagementControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'DELETE /api/admin/images/{imageId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] imageId (required):
  Future<Response> deleteImageWithHttpInfo(String imageId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/images/{imageId}'
      .replaceAll('{imageId}', imageId);

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
  /// * [String] imageId (required):
  Future<ApiResponseString?> deleteImage(String imageId,) async {
    final response = await deleteImageWithHttpInfo(imageId,);
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

  /// Performs an HTTP 'GET /api/admin/images' operation and returns the [Response].
  Future<Response> getAllImagesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/images';

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

  Future<ApiResponseListMapStringObject?> getAllImages() async {
    final response = await getAllImagesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListMapStringObject',) as ApiResponseListMapStringObject;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/images/category/{category}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] category (required):
  Future<Response> getImagesByCategoryWithHttpInfo(String category,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/images/category/{category}'
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
  /// * [String] category (required):
  Future<ApiResponseListMapStringObject?> getImagesByCategory(String category,) async {
    final response = await getImagesByCategoryWithHttpInfo(category,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListMapStringObject',) as ApiResponseListMapStringObject;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/images/{imageId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] imageId (required):
  ///
  /// * [Map<String, Object>] requestBody (required):
  Future<Response> updateImageMetadataWithHttpInfo(String imageId, Map<String, Object> requestBody,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/images/{imageId}'
      .replaceAll('{imageId}', imageId);

    // ignore: prefer_final_locals
    Object? postBody = requestBody;

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
  /// * [String] imageId (required):
  ///
  /// * [Map<String, Object>] requestBody (required):
  Future<ApiResponseMapStringObject?> updateImageMetadata(String imageId, Map<String, Object> requestBody,) async {
    final response = await updateImageMetadataWithHttpInfo(imageId, requestBody,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMapStringObject',) as ApiResponseMapStringObject;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/images/upload' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///
  /// * [String] category:
  ///
  /// * [String] description:
  Future<Response> uploadImageWithHttpInfo(MultipartFile file, { String? category, String? description, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/images/upload';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (category != null) {
      queryParams.addAll(_queryParams('', 'category', category));
    }
    if (description != null) {
      queryParams.addAll(_queryParams('', 'description', description));
    }

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (file != null) {
      hasFields = true;
      mp.fields[r'file'] = file.field;
      mp.files.add(file);
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
  /// * [MultipartFile] file (required):
  ///
  /// * [String] category:
  ///
  /// * [String] description:
  Future<ApiResponseMapStringObject?> uploadImage(MultipartFile file, { String? category, String? description, }) async {
    final response = await uploadImageWithHttpInfo(file,  category: category, description: description, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseMapStringObject',) as ApiResponseMapStringObject;
    
    }
    return null;
  }
}
