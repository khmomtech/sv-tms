//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class CustomerControllerApi {
  CustomerControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/customers' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [CustomerDto] customerDto (required):
  Future<Response> createCustomerWithHttpInfo(CustomerDto customerDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers';

    // ignore: prefer_final_locals
    Object? postBody = customerDto;

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
  /// * [CustomerDto] customerDto (required):
  Future<ApiResponseCustomerDto?> createCustomer(CustomerDto customerDto,) async {
    final response = await createCustomerWithHttpInfo(customerDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseCustomerDto',) as ApiResponseCustomerDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/customers/{id}/account' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [CreateAccountRequest] createAccountRequest (required):
  Future<Response> createCustomerAccountWithHttpInfo(int id, CreateAccountRequest createAccountRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers/{id}/account'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = createAccountRequest;

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
  /// * [int] id (required):
  ///
  /// * [CreateAccountRequest] createAccountRequest (required):
  Future<ApiResponseMapStringObject?> createCustomerAccount(int id, CreateAccountRequest createAccountRequest,) async {
    final response = await createCustomerAccountWithHttpInfo(id, createAccountRequest,);
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

  /// Performs an HTTP 'DELETE /api/admin/customers/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteCustomerWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers/{id}'
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
  Future<void> deleteCustomer(int id,) async {
    final response = await deleteCustomerWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/admin/customers/filter' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] customerCode:
  ///
  /// * [String] name:
  ///
  /// * [String] phone:
  ///
  /// * [String] email:
  ///
  /// * [String] type:
  ///
  /// * [String] status:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> filterCustomersWithHttpInfo({ String? customerCode, String? name, String? phone, String? email, String? type, String? status, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers/filter';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (customerCode != null) {
      queryParams.addAll(_queryParams('', 'customerCode', customerCode));
    }
    if (name != null) {
      queryParams.addAll(_queryParams('', 'name', name));
    }
    if (phone != null) {
      queryParams.addAll(_queryParams('', 'phone', phone));
    }
    if (email != null) {
      queryParams.addAll(_queryParams('', 'email', email));
    }
    if (type != null) {
      queryParams.addAll(_queryParams('', 'type', type));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (size != null) {
      queryParams.addAll(_queryParams('', 'size', size));
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
  /// * [String] customerCode:
  ///
  /// * [String] name:
  ///
  /// * [String] phone:
  ///
  /// * [String] email:
  ///
  /// * [String] type:
  ///
  /// * [String] status:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageCustomer?> filterCustomers({ String? customerCode, String? name, String? phone, String? email, String? type, String? status, int? page, int? size, }) async {
    final response = await filterCustomersWithHttpInfo( customerCode: customerCode, name: name, phone: phone, email: email, type: type, status: status, page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageCustomer',) as ApiResponsePageCustomer;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/customers' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getAllCustomersWithHttpInfo({ int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (page != null) {
      queryParams.addAll(_queryParams('', 'page', page));
    }
    if (size != null) {
      queryParams.addAll(_queryParams('', 'size', size));
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
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageCustomer?> getAllCustomers({ int? page, int? size, }) async {
    final response = await getAllCustomersWithHttpInfo( page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageCustomer',) as ApiResponsePageCustomer;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/customers/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getCustomerByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers/{id}'
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
  Future<ApiResponseMapStringObject?> getCustomerById(int id,) async {
    final response = await getCustomerByIdWithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/customers/{id}/addresses' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getCustomerWithAddressesWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers/{id}/addresses'
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
  Future<ApiResponseMapStringObject?> getCustomerWithAddresses(int id,) async {
    final response = await getCustomerWithAddressesWithHttpInfo(id,);
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

  /// Performs an HTTP 'POST /api/admin/customers/import' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> importCustomersWithHttpInfo({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers/import';

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
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<ApiResponseListCustomerDto?> importCustomers({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await importCustomersWithHttpInfo( updateDocumentFileRequest: updateDocumentFileRequest, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListCustomerDto',) as ApiResponseListCustomerDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/customers/search' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] keyword (required):
  Future<Response> searchCustomersWithHttpInfo(String keyword,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'keyword', keyword));

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
  /// * [String] keyword (required):
  Future<ApiResponseListCustomer?> searchCustomers(String keyword,) async {
    final response = await searchCustomersWithHttpInfo(keyword,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListCustomer',) as ApiResponseListCustomer;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/customers/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [CustomerDto] customerDto (required):
  Future<Response> updateCustomerWithHttpInfo(int id, CustomerDto customerDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/customers/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = customerDto;

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
  /// * [CustomerDto] customerDto (required):
  Future<ApiResponseCustomerDto?> updateCustomer(int id, CustomerDto customerDto,) async {
    final response = await updateCustomerWithHttpInfo(id, customerDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseCustomerDto',) as ApiResponseCustomerDto;
    
    }
    return null;
  }
}
