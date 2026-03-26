//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DispatchControllerApi {
  DispatchControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/driver/dispatches/{id}/accept' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> acceptDispatchWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/accept'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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
  Future<ApiResponseDispatchDto?> acceptDispatch(int id,) async {
    final response = await acceptDispatchWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches/{id}/assign' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] vehicleId (required):
  Future<Response> assignDispatchWithHttpInfo(int id, int driverId, int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/assign'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'driverId', driverId));
      queryParams.addAll(_queryParams('', 'vehicleId', vehicleId));

    const contentTypes = <String>[];


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
  /// * [int] driverId (required):
  ///
  /// * [int] vehicleId (required):
  Future<ApiResponseDispatchDto?> assignDispatch(int id, int driverId, int vehicleId,) async {
    final response = await assignDispatchWithHttpInfo(id, driverId, vehicleId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches/{id}/assign-driver' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] driverId (required):
  Future<Response> assignDriverOnlyWithHttpInfo(int id, int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/assign-driver'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'driverId', driverId));

    const contentTypes = <String>[];


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
  /// * [int] driverId (required):
  Future<ApiResponseDispatchDto?> assignDriverOnly(int id, int driverId,) async {
    final response = await assignDriverOnlyWithHttpInfo(id, driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches/{id}/assign-truck' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] vehicleId (required):
  Future<Response> assignTruckOnlyWithHttpInfo(int id, int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/assign-truck'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'vehicleId', vehicleId));

    const contentTypes = <String>[];


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
  /// * [int] vehicleId (required):
  Future<ApiResponseDispatchDto?> assignTruckOnly(int id, int vehicleId,) async {
    final response = await assignTruckOnlyWithHttpInfo(id, vehicleId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/driver/dispatches/{id}/change-driver' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] driverId (required):
  Future<Response> changeDriverWithHttpInfo(int id, int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/change-driver'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'driverId', driverId));

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
  /// * [int] driverId (required):
  Future<ApiResponseDispatchDto?> changeDriver(int id, int driverId,) async {
    final response = await changeDriverWithHttpInfo(id, driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/driver/dispatches/{id}/change-truck' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] vehicleId (required):
  Future<Response> changeTruckWithHttpInfo(int id, int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/change-truck'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'vehicleId', vehicleId));

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
  /// * [int] vehicleId (required):
  Future<ApiResponseDispatchDto?> changeTruck(int id, int vehicleId,) async {
    final response = await changeTruckWithHttpInfo(id, vehicleId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DispatchDto] dispatchDto (required):
  Future<Response> createDispatchWithHttpInfo(DispatchDto dispatchDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches';

    // ignore: prefer_final_locals
    Object? postBody = dispatchDto;

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
  /// * [DispatchDto] dispatchDto (required):
  Future<ApiResponseDispatchDto?> createDispatch(DispatchDto dispatchDto,) async {
    final response = await createDispatchWithHttpInfo(dispatchDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/driver/dispatches/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteDispatchWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}'
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
  Future<ApiResponseVoid?> deleteDispatch(int id,) async {
    final response = await deleteDispatchWithHttpInfo(id,);
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

  /// Performs an HTTP 'POST /api/driver/dispatches/driver/load-proof/{dispatchId}/load' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] dispatchId (required):
  ///
  /// * [String] remarks:
  ///
  /// * [List<MultipartFile>] images:
  ///
  /// * [MultipartFile] signature:
  Future<Response> driverSubmitLoadProofWithHttpInfo(int dispatchId, { String? remarks, List<MultipartFile>? images, MultipartFile? signature, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/driver/load-proof/{dispatchId}/load'
      .replaceAll('{dispatchId}', dispatchId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (remarks != null) {
      queryParams.addAll(_queryParams('', 'remarks', remarks));
    }

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (images != null) {
      hasFields = true;
      mp.fields[r'images'] = images.field;
      mp.files.add(images);
    }
    if (signature != null) {
      hasFields = true;
      mp.fields[r'signature'] = signature.field;
      mp.files.add(signature);
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
  /// * [int] dispatchId (required):
  ///
  /// * [String] remarks:
  ///
  /// * [List<MultipartFile>] images:
  ///
  /// * [MultipartFile] signature:
  Future<ApiResponseLoadProofDto?> driverSubmitLoadProof(int dispatchId, { String? remarks, List<MultipartFile>? images, MultipartFile? signature, }) async {
    final response = await driverSubmitLoadProofWithHttpInfo(dispatchId,  remarks: remarks, images: images, signature: signature, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseLoadProofDto',) as ApiResponseLoadProofDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/dispatches/filter' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [int] driverId:
  ///
  /// * [int] vehicleId:
  ///
  /// * [String] status:
  ///
  /// * [String] driverName:
  ///
  /// * [String] routeCode:
  ///
  /// * [String] q:
  ///
  /// * [String] customerName:
  ///
  /// * [String] destinationTo:
  ///
  /// * [String] truckPlate:
  ///
  /// * [String] tripNo:
  ///
  /// * [DateTime] start:
  ///
  /// * [DateTime] end:
  Future<Response> filterDispatchesWithHttpInfo(Pageable pageable, { int? driverId, int? vehicleId, String? status, String? driverName, String? routeCode, String? q, String? customerName, String? destinationTo, String? truckPlate, String? tripNo, DateTime? start, DateTime? end, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/filter';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (driverId != null) {
      queryParams.addAll(_queryParams('', 'driverId', driverId));
    }
    if (vehicleId != null) {
      queryParams.addAll(_queryParams('', 'vehicleId', vehicleId));
    }
    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
    }
    if (driverName != null) {
      queryParams.addAll(_queryParams('', 'driverName', driverName));
    }
    if (routeCode != null) {
      queryParams.addAll(_queryParams('', 'routeCode', routeCode));
    }
    if (q != null) {
      queryParams.addAll(_queryParams('', 'q', q));
    }
    if (customerName != null) {
      queryParams.addAll(_queryParams('', 'customerName', customerName));
    }
    if (destinationTo != null) {
      queryParams.addAll(_queryParams('', 'destinationTo', destinationTo));
    }
    if (truckPlate != null) {
      queryParams.addAll(_queryParams('', 'truckPlate', truckPlate));
    }
    if (tripNo != null) {
      queryParams.addAll(_queryParams('', 'tripNo', tripNo));
    }
    if (start != null) {
      queryParams.addAll(_queryParams('', 'start', start));
    }
    if (end != null) {
      queryParams.addAll(_queryParams('', 'end', end));
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
  /// * [int] driverId:
  ///
  /// * [int] vehicleId:
  ///
  /// * [String] status:
  ///
  /// * [String] driverName:
  ///
  /// * [String] routeCode:
  ///
  /// * [String] q:
  ///
  /// * [String] customerName:
  ///
  /// * [String] destinationTo:
  ///
  /// * [String] truckPlate:
  ///
  /// * [String] tripNo:
  ///
  /// * [DateTime] start:
  ///
  /// * [DateTime] end:
  Future<ApiResponsePageDispatchDto?> filterDispatches(Pageable pageable, { int? driverId, int? vehicleId, String? status, String? driverName, String? routeCode, String? q, String? customerName, String? destinationTo, String? truckPlate, String? tripNo, DateTime? start, DateTime? end, }) async {
    final response = await filterDispatchesWithHttpInfo(pageable,  driverId: driverId, vehicleId: vehicleId, status: status, driverName: driverName, routeCode: routeCode, q: q, customerName: customerName, destinationTo: destinationTo, truckPlate: truckPlate, tripNo: tripNo, start: start, end: end, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageDispatchDto',) as ApiResponsePageDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/dispatches' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  Future<Response> getAllDispatchesWithHttpInfo(Pageable pageable,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches';

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
  Future<ApiResponsePageDispatchDto?> getAllDispatches(Pageable pageable,) async {
    final response = await getAllDispatchesWithHttpInfo(pageable,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageDispatchDto',) as ApiResponsePageDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/dispatches/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getDispatchByIdWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}'
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
  Future<ApiResponseDispatchDto?> getDispatchById(int id,) async {
    final response = await getDispatchByIdWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/dispatches/{id}/status-history' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getDispatchStatusHistoryWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/status-history'
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
  Future<ApiResponseListDispatchStatusHistoryDto?> getDispatchStatusHistory(int id,) async {
    final response = await getDispatchStatusHistoryWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDispatchStatusHistoryDto',) as ApiResponseListDispatchStatusHistoryDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/dispatches/driver/{driverId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [DateTime] from:
  ///
  /// * [DateTime] to:
  Future<Response> getDispatchesByDriverWithDateRangeWithHttpInfo(int driverId, Pageable pageable, { DateTime? from, DateTime? to, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/driver/{driverId}'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (from != null) {
      queryParams.addAll(_queryParams('', 'from', from));
    }
    if (to != null) {
      queryParams.addAll(_queryParams('', 'to', to));
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
  /// * [DateTime] from:
  ///
  /// * [DateTime] to:
  Future<PageDispatchDto?> getDispatchesByDriverWithDateRange(int driverId, Pageable pageable, { DateTime? from, DateTime? to, }) async {
    final response = await getDispatchesByDriverWithDateRangeWithHttpInfo(driverId, pageable,  from: from, to: to, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PageDispatchDto',) as PageDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/dispatches/driver/{driverId}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [String] status:
  Future<Response> getDispatchesByDriverWithStatusFilterWithHttpInfo(int driverId, Pageable pageable, { String? status, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/driver/{driverId}/status'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (status != null) {
      queryParams.addAll(_queryParams('', 'status', status));
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
  Future<PageDispatchDto?> getDispatchesByDriverWithStatusFilter(int driverId, Pageable pageable, { String? status, }) async {
    final response = await getDispatchesByDriverWithStatusFilterWithHttpInfo(driverId, pageable,  status: status, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PageDispatchDto',) as PageDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/dispatches/proofs/load' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] search:
  ///
  /// * [String] driver:
  ///
  /// * [String] route:
  ///
  /// * [DateTime] from:
  ///
  /// * [DateTime] to:
  Future<Response> getFilteredLoadProofsWithHttpInfo({ String? search, String? driver, String? route, DateTime? from, DateTime? to, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/proofs/load';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (search != null) {
      queryParams.addAll(_queryParams('', 'search', search));
    }
    if (driver != null) {
      queryParams.addAll(_queryParams('', 'driver', driver));
    }
    if (route != null) {
      queryParams.addAll(_queryParams('', 'route', route));
    }
    if (from != null) {
      queryParams.addAll(_queryParams('', 'from', from));
    }
    if (to != null) {
      queryParams.addAll(_queryParams('', 'to', to));
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
  /// * [String] search:
  ///
  /// * [String] driver:
  ///
  /// * [String] route:
  ///
  /// * [DateTime] from:
  ///
  /// * [DateTime] to:
  Future<ApiResponseListLoadProofDto?> getFilteredLoadProofs({ String? search, String? driver, String? route, DateTime? from, DateTime? to, }) async {
    final response = await getFilteredLoadProofsWithHttpInfo( search: search, driver: driver, route: route, from: from, to: to, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListLoadProofDto',) as ApiResponseListLoadProofDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches/import-bulk' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  Future<Response> importBulkDispatchesWithHttpInfo(MultipartFile file,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/import-bulk';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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
  Future<ApiResponseString?> importBulkDispatches(MultipartFile file,) async {
    final response = await importBulkDispatchesWithHttpInfo(file,);
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

  /// Performs an HTTP 'POST /api/driver/dispatches/{dispatchId}/unload' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] dispatchId (required):
  ///
  /// * [String] remarks:
  ///
  /// * [String] address:
  ///
  /// * [double] latitude:
  ///
  /// * [double] longitude:
  ///
  /// * [MarkAsUnloadedRequest] markAsUnloadedRequest:
  Future<Response> markAsUnloadedWithHttpInfo(int dispatchId, { String? remarks, String? address, double? latitude, double? longitude, MarkAsUnloadedRequest? markAsUnloadedRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{dispatchId}/unload'
      .replaceAll('{dispatchId}', dispatchId.toString());

    // ignore: prefer_final_locals
    Object? postBody = markAsUnloadedRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (remarks != null) {
      queryParams.addAll(_queryParams('', 'remarks', remarks));
    }
    if (address != null) {
      queryParams.addAll(_queryParams('', 'address', address));
    }
    if (latitude != null) {
      queryParams.addAll(_queryParams('', 'latitude', latitude));
    }
    if (longitude != null) {
      queryParams.addAll(_queryParams('', 'longitude', longitude));
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
  /// * [int] dispatchId (required):
  ///
  /// * [String] remarks:
  ///
  /// * [String] address:
  ///
  /// * [double] latitude:
  ///
  /// * [double] longitude:
  ///
  /// * [MarkAsUnloadedRequest] markAsUnloadedRequest:
  Future<Object?> markAsUnloaded(int dispatchId, { String? remarks, String? address, double? latitude, double? longitude, MarkAsUnloadedRequest? markAsUnloadedRequest, }) async {
    final response = await markAsUnloadedWithHttpInfo(dispatchId,  remarks: remarks, address: address, latitude: latitude, longitude: longitude, markAsUnloadedRequest: markAsUnloadedRequest, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Object',) as Object;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches/{id}/notify-assigned-driver' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> notifyAssignedDriverWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/notify-assigned-driver'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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
  Future<ApiResponseDispatchDto?> notifyAssignedDriver(int id,) async {
    final response = await notifyAssignedDriverWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches/plan-trip' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody (required):
  Future<Response> planTripWithHttpInfo(Map<String, Object> requestBody,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/plan-trip';

    // ignore: prefer_final_locals
    Object? postBody = requestBody;

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
  /// * [Map<String, Object>] requestBody (required):
  Future<ApiResponseDispatchDto?> planTrip(Map<String, Object> requestBody,) async {
    final response = await planTripWithHttpInfo(requestBody,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches/{id}/reject' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [String] reason (required):
  Future<Response> rejectDispatchWithHttpInfo(int id, String reason,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/reject'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'reason', reason));

    const contentTypes = <String>[];


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
  /// * [String] reason (required):
  Future<ApiResponseDispatchDto?> rejectDispatch(int id, String reason,) async {
    final response = await rejectDispatchWithHttpInfo(id, reason,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches/{dispatchId}/load' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] dispatchId (required):
  ///
  /// * [String] remarks:
  ///
  /// * [List<MultipartFile>] images:
  ///
  /// * [MultipartFile] signature:
  Future<Response> submitLoadProofWithHttpInfo(int dispatchId, { String? remarks, List<MultipartFile>? images, MultipartFile? signature, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{dispatchId}/load'
      .replaceAll('{dispatchId}', dispatchId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (remarks != null) {
      queryParams.addAll(_queryParams('', 'remarks', remarks));
    }

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (images != null) {
      hasFields = true;
      mp.fields[r'images'] = images.field;
      mp.files.add(images);
    }
    if (signature != null) {
      hasFields = true;
      mp.fields[r'signature'] = signature.field;
      mp.files.add(signature);
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
  /// * [int] dispatchId (required):
  ///
  /// * [String] remarks:
  ///
  /// * [List<MultipartFile>] images:
  ///
  /// * [MultipartFile] signature:
  Future<ApiResponseLoadProofDto?> submitLoadProof(int dispatchId, { String? remarks, List<MultipartFile>? images, MultipartFile? signature, }) async {
    final response = await submitLoadProofWithHttpInfo(dispatchId,  remarks: remarks, images: images, signature: signature, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseLoadProofDto',) as ApiResponseLoadProofDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/dispatches/driver/unload-proof/{dispatchId}/unload' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] dispatchId (required):
  ///
  /// * [String] remarks:
  ///
  /// * [String] address:
  ///
  /// * [double] latitude:
  ///
  /// * [double] longitude:
  ///
  /// * [List<MultipartFile>] images:
  ///
  /// * [MultipartFile] signature:
  Future<Response> submitUnloadProofWithHttpInfo(int dispatchId, { String? remarks, String? address, double? latitude, double? longitude, List<MultipartFile>? images, MultipartFile? signature, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/driver/unload-proof/{dispatchId}/unload'
      .replaceAll('{dispatchId}', dispatchId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (remarks != null) {
      queryParams.addAll(_queryParams('', 'remarks', remarks));
    }
    if (address != null) {
      queryParams.addAll(_queryParams('', 'address', address));
    }
    if (latitude != null) {
      queryParams.addAll(_queryParams('', 'latitude', latitude));
    }
    if (longitude != null) {
      queryParams.addAll(_queryParams('', 'longitude', longitude));
    }

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (images != null) {
      hasFields = true;
      mp.fields[r'images'] = images.field;
      mp.files.add(images);
    }
    if (signature != null) {
      hasFields = true;
      mp.fields[r'signature'] = signature.field;
      mp.files.add(signature);
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
  /// * [int] dispatchId (required):
  ///
  /// * [String] remarks:
  ///
  /// * [String] address:
  ///
  /// * [double] latitude:
  ///
  /// * [double] longitude:
  ///
  /// * [List<MultipartFile>] images:
  ///
  /// * [MultipartFile] signature:
  Future<ApiResponseUnloadProofDto?> submitUnloadProof(int dispatchId, { String? remarks, String? address, double? latitude, double? longitude, List<MultipartFile>? images, MultipartFile? signature, }) async {
    final response = await submitUnloadProofWithHttpInfo(dispatchId,  remarks: remarks, address: address, latitude: latitude, longitude: longitude, images: images, signature: signature, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseUnloadProofDto',) as ApiResponseUnloadProofDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/driver/dispatches/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [DispatchDto] dispatchDto (required):
  Future<Response> updateDispatchWithHttpInfo(int id, DispatchDto dispatchDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = dispatchDto;

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
  /// * [DispatchDto] dispatchDto (required):
  Future<ApiResponseDispatchDto?> updateDispatch(int id, DispatchDto dispatchDto,) async {
    final response = await updateDispatchWithHttpInfo(id, dispatchDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PATCH /api/driver/dispatches/{id}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [String] status (required):
  Future<Response> updateDispatchStatusWithHttpInfo(int id, String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/dispatches/{id}/status'
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
  /// * [String] status (required):
  Future<ApiResponseDispatchDto?> updateDispatchStatus(int id, String status,) async {
    final response = await updateDispatchStatusWithHttpInfo(id, status,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDispatchDto',) as ApiResponseDispatchDto;
    
    }
    return null;
  }
}
