//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class CustomerPublicApi {
  CustomerPublicApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get a single order for a customer
  ///
  /// Returns a single transport order if it belongs to the customer
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] customerId (required):
  ///
  /// * [int] orderId (required):
  Future<Response> getOrderForCustomerWithHttpInfo(int customerId, int orderId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/customer/{customerId}/orders/{orderId}'
      .replaceAll('{customerId}', customerId.toString())
      .replaceAll('{orderId}', orderId.toString());

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

  /// Get a single order for a customer
  ///
  /// Returns a single transport order if it belongs to the customer
  ///
  /// Parameters:
  ///
  /// * [int] customerId (required):
  ///
  /// * [int] orderId (required):
  Future<ApiResponseTransportOrderDto?> getOrderForCustomer(int customerId, int orderId,) async {
    final response = await getOrderForCustomerWithHttpInfo(customerId, orderId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseTransportOrderDto',) as ApiResponseTransportOrderDto;
    
    }
    return null;
  }

  /// List addresses for a customer
  ///
  /// Returns order addresses registered under the specified customer
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] customerId (required):
  Future<Response> listAddressesForCustomerWithHttpInfo(int customerId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/customer/{customerId}/addresses'
      .replaceAll('{customerId}', customerId.toString());

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

  /// List addresses for a customer
  ///
  /// Returns order addresses registered under the specified customer
  ///
  /// Parameters:
  ///
  /// * [int] customerId (required):
  Future<ApiResponseListOrderAddressDto?> listAddressesForCustomer(int customerId,) async {
    final response = await listAddressesForCustomerWithHttpInfo(customerId,);
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

  /// List orders for a customer
  ///
  /// Returns transport orders belonging to the specified customer
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] customerId (required):
  Future<Response> listOrdersForCustomerWithHttpInfo(int customerId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/customer/{customerId}/orders'
      .replaceAll('{customerId}', customerId.toString());

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

  /// List orders for a customer
  ///
  /// Returns transport orders belonging to the specified customer
  ///
  /// Parameters:
  ///
  /// * [int] customerId (required):
  Future<ApiResponseListTransportOrderDto?> listOrdersForCustomer(int customerId,) async {
    final response = await listOrdersForCustomerWithHttpInfo(customerId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListTransportOrderDto',) as ApiResponseListTransportOrderDto;
    
    }
    return null;
  }
}
