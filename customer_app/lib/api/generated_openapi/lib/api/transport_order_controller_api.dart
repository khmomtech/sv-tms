//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class TransportOrderControllerApi {
  TransportOrderControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/transportorders' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [TransportOrderDto] transportOrderDto (required):
  Future<Response> createOrderWithHttpInfo(TransportOrderDto transportOrderDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders';

    // ignore: prefer_final_locals
    Object? postBody = transportOrderDto;

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
  /// * [TransportOrderDto] transportOrderDto (required):
  Future<ApiResponseTransportOrderDto?> createOrder(TransportOrderDto transportOrderDto,) async {
    final response = await createOrderWithHttpInfo(transportOrderDto,);
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

  /// Performs an HTTP 'DELETE /api/admin/transportorders/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteOrderWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/{id}'
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
  Future<ApiResponseString?> deleteOrder(int id,) async {
    final response = await deleteOrderWithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/transportorders/filter/date' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] startDate (required):
  ///
  /// * [DateTime] endDate (required):
  ///
  /// * [Pageable] pageable (required):
  Future<Response> filterByDateRangeWithHttpInfo(DateTime startDate, DateTime endDate, Pageable pageable,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/filter/date';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'startDate', startDate));
      queryParams.addAll(_queryParams('', 'endDate', endDate));
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
  /// * [DateTime] startDate (required):
  ///
  /// * [DateTime] endDate (required):
  ///
  /// * [Pageable] pageable (required):
  Future<ApiResponsePageTransportOrder?> filterByDateRange(DateTime startDate, DateTime endDate, Pageable pageable,) async {
    final response = await filterByDateRangeWithHttpInfo(startDate, endDate, pageable,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageTransportOrder',) as ApiResponsePageTransportOrder;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/transportorders/filter/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] status (required):
  ///
  /// * [Pageable] pageable (required):
  Future<Response> filterByStatusWithHttpInfo(String status, Pageable pageable,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/filter/status';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'status', status));
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
  /// * [String] status (required):
  ///
  /// * [Pageable] pageable (required):
  Future<ApiResponsePageTransportOrder?> filterByStatus(String status, Pageable pageable,) async {
    final response = await filterByStatusWithHttpInfo(status, pageable,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageTransportOrder',) as ApiResponsePageTransportOrder;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/transportorders/filter' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [String] query:
  ///
  /// * [String] status:
  ///
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  Future<Response> filterOrdersWithHttpInfo(Pageable pageable, { String? query, String? status, DateTime? fromDate, DateTime? toDate, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/filter';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (query != null) {
      queryParams.addAll(_queryParams('', 'query', query));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
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
  /// * [String] query:
  ///
  /// * [String] status:
  ///
  /// * [DateTime] fromDate:
  ///
  /// * [DateTime] toDate:
  Future<ApiResponsePageTransportOrderDto?> filterOrders(Pageable pageable, { String? query, String? status, DateTime? fromDate, DateTime? toDate, }) async {
    final response = await filterOrdersWithHttpInfo(pageable,  query: query, status: status, fromDate: fromDate, toDate: toDate, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageTransportOrderDto',) as ApiResponsePageTransportOrderDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/transportorders/list' operation and returns the [Response].
  Future<Response> getAllOrderListsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/list';

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

  Future<ApiResponseListTransportOrderDto?> getAllOrderLists() async {
    final response = await getAllOrderListsWithHttpInfo();
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

  /// Performs an HTTP 'GET /api/admin/transportorders' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  Future<Response> getAllOrdersWithHttpInfo(Pageable pageable,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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
  Future<ApiResponsePageTransportOrderDto?> getAllOrders(Pageable pageable,) async {
    final response = await getAllOrdersWithHttpInfo(pageable,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageTransportOrderDto',) as ApiResponsePageTransportOrderDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/transportorders/{id}/addresses' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getOrderAddressesWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/{id}/addresses'
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
  Future<ApiResponseListOrderAddress?> getOrderAddresses(int id,) async {
    final response = await getOrderAddressesWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListOrderAddress',) as ApiResponseListOrderAddress;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/transportorders/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getOrderByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/{id}'
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
  Future<ApiResponseTransportOrderDto?> getOrderById(int id,) async {
    final response = await getOrderByIdWithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/transportorders/{id}/items' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getOrderItemsWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/{id}/items'
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
  Future<ApiResponseListOrderItem?> getOrderItems(int id,) async {
    final response = await getOrderItemsWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListOrderItem',) as ApiResponseListOrderItem;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/transportorders/customer/{customerId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] customerId (required):
  Future<Response> getOrdersByCustomerWithHttpInfo(int customerId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/customer/{customerId}'
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

  /// Parameters:
  ///
  /// * [int] customerId (required):
  Future<ApiResponseListTransportOrderDto?> getOrdersByCustomer(int customerId,) async {
    final response = await getOrdersByCustomerWithHttpInfo(customerId,);
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

  /// Performs an HTTP 'GET /api/admin/transportorders/unscheduled' operation and returns the [Response].
  Future<Response> getUnscheduledOrdersWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/unscheduled';

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

  Future<ApiResponseListTransportOrderDto?> getUnscheduledOrders() async {
    final response = await getUnscheduledOrdersWithHttpInfo();
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

  /// Performs an HTTP 'POST /api/admin/transportorders/import-bulk' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> importBulkOrdersWithHttpInfo({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/import-bulk';

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
  Future<ApiResponseObject?> importBulkOrders({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await importBulkOrdersWithHttpInfo( updateDocumentFileRequest: updateDocumentFileRequest, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseObject',) as ApiResponseObject;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/transportorders/search' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] query (required):
  ///
  /// * [Pageable] pageable (required):
  Future<Response> searchOrdersWithHttpInfo(String query, Pageable pageable,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'query', query));
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
  /// * [String] query (required):
  ///
  /// * [Pageable] pageable (required):
  Future<ApiResponsePageTransportOrderDto?> searchOrders(String query, Pageable pageable,) async {
    final response = await searchOrdersWithHttpInfo(query, pageable,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageTransportOrderDto',) as ApiResponsePageTransportOrderDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/transportorders/searchs' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] query (required):
  Future<Response> searchOrderssWithHttpInfo(String query,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/searchs';

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
  Future<ApiResponseListTransportOrderDto?> searchOrderss(String query,) async {
    final response = await searchOrderssWithHttpInfo(query,);
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

  /// Performs an HTTP 'PUT /api/admin/transportorders/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [UpdateTransportOrderDto] updateTransportOrderDto (required):
  Future<Response> updateOrderWithHttpInfo(int id, UpdateTransportOrderDto updateTransportOrderDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = updateTransportOrderDto;

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
  /// * [UpdateTransportOrderDto] updateTransportOrderDto (required):
  Future<ApiResponseTransportOrderDto?> updateOrder(int id, UpdateTransportOrderDto updateTransportOrderDto,) async {
    final response = await updateOrderWithHttpInfo(id, updateTransportOrderDto,);
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

  /// Performs an HTTP 'PUT /api/admin/transportorders/{id}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [String] status (required):
  Future<Response> updateOrderStatusWithHttpInfo(int id, String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/transportorders/{id}/status'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'status', status));

    const contentTypes = <String>[];


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
  /// * [String] status (required):
  Future<ApiResponseTransportOrderDto?> updateOrderStatus(int id, String status,) async {
    final response = await updateOrderStatusWithHttpInfo(id, status,);
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
}
