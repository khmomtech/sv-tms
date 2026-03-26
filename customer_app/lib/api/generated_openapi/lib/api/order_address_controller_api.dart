//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class OrderAddressControllerApi {
  OrderAddressControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/order-address' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [OrderAddressDto] orderAddressDto (required):
  Future<Response> createAddressWithHttpInfo(OrderAddressDto orderAddressDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/order-address';

    // ignore: prefer_final_locals
    Object? postBody = orderAddressDto;

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
  /// * [OrderAddressDto] orderAddressDto (required):
  Future<ApiResponseOrderAddressDto?> createAddress(OrderAddressDto orderAddressDto,) async {
    final response = await createAddressWithHttpInfo(orderAddressDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseOrderAddressDto',) as ApiResponseOrderAddressDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/order-address/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteAddressWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/order-address/{id}'
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
  Future<ApiResponseString?> deleteAddress(int id,) async {
    final response = await deleteAddressWithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/order-address/export' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] customerId (required):
  Future<Response> exportAddressesWithHttpInfo(int customerId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/order-address/export';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'customerId', customerId));

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
  /// * [int] customerId (required):
  Future<MultipartFile?> exportAddresses(int customerId,) async {
    final response = await exportAddressesWithHttpInfo(customerId,);
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

  /// Performs an HTTP 'GET /api/admin/order-address/detail/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getAddressByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/order-address/detail/{id}'
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
  Future<ApiResponseOrderAddressDto?> getAddressById(int id,) async {
    final response = await getAddressByIdWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseOrderAddressDto',) as ApiResponseOrderAddressDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/order-address/import' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] customerId (required):
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> importAddressesWithHttpInfo(int customerId, { UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/order-address/import';

    // ignore: prefer_final_locals
    Object? postBody = updateDocumentFileRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'customerId', customerId));

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
  /// * [int] customerId (required):
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<ApiResponseString?> importAddresses(int customerId, { UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await importAddressesWithHttpInfo(customerId,  updateDocumentFileRequest: updateDocumentFileRequest, );
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

  /// Performs an HTTP 'GET /api/admin/order-address/search' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] name (required):
  Future<Response> searchLocationsWithHttpInfo(String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/order-address/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'name', name));

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
  /// * [String] name (required):
  Future<ApiResponseListOrderAddressDto?> searchLocations(String name,) async {
    final response = await searchLocationsWithHttpInfo(name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListOrderAddressDto',) as ApiResponseListOrderAddressDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/order-address/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [OrderAddressDto] orderAddressDto (required):
  Future<Response> updateAddressWithHttpInfo(int id, OrderAddressDto orderAddressDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/order-address/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = orderAddressDto;

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
  /// * [OrderAddressDto] orderAddressDto (required):
  Future<ApiResponseOrderAddressDto?> updateAddress(int id, OrderAddressDto orderAddressDto,) async {
    final response = await updateAddressWithHttpInfo(id, orderAddressDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseOrderAddressDto',) as ApiResponseOrderAddressDto;
    
    }
    return null;
  }
}
