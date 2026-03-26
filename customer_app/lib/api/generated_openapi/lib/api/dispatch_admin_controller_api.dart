//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DispatchAdminControllerApi {
  DispatchAdminControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/dispatches/{id}/accept' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> acceptDispatch1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/accept'
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
  Future<ApiResponseDispatchDto?> acceptDispatch1(int id,) async {
    final response = await acceptDispatch1WithHttpInfo(id,);
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

  /// Performs an HTTP 'POST /api/admin/dispatches/{id}/assign' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] vehicleId (required):
  Future<Response> assignDispatch1WithHttpInfo(int id, int driverId, int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/assign'
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
  Future<ApiResponseDispatchDto?> assignDispatch1(int id, int driverId, int vehicleId,) async {
    final response = await assignDispatch1WithHttpInfo(id, driverId, vehicleId,);
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

  /// Performs an HTTP 'POST /api/admin/dispatches/{id}/assign-driver' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] driverId (required):
  Future<Response> assignDriverOnly1WithHttpInfo(int id, int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/assign-driver'
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
  Future<ApiResponseDispatchDto?> assignDriverOnly1(int id, int driverId,) async {
    final response = await assignDriverOnly1WithHttpInfo(id, driverId,);
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

  /// Performs an HTTP 'POST /api/admin/dispatches/{id}/assign-truck' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] vehicleId (required):
  Future<Response> assignTruckOnly1WithHttpInfo(int id, int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/assign-truck'
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
  Future<ApiResponseDispatchDto?> assignTruckOnly1(int id, int vehicleId,) async {
    final response = await assignTruckOnly1WithHttpInfo(id, vehicleId,);
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

  /// Performs an HTTP 'PUT /api/admin/dispatches/{id}/change-driver' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] driverId (required):
  Future<Response> changeDriver1WithHttpInfo(int id, int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/change-driver'
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
  Future<ApiResponseDispatchDto?> changeDriver1(int id, int driverId,) async {
    final response = await changeDriver1WithHttpInfo(id, driverId,);
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

  /// Performs an HTTP 'PUT /api/admin/dispatches/{id}/change-truck' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [int] vehicleId (required):
  Future<Response> changeTruck1WithHttpInfo(int id, int vehicleId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/change-truck'
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
  Future<ApiResponseDispatchDto?> changeTruck1(int id, int vehicleId,) async {
    final response = await changeTruck1WithHttpInfo(id, vehicleId,);
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

  /// Performs an HTTP 'POST /api/admin/dispatches' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DispatchDto] dispatchDto (required):
  Future<Response> createDispatch1WithHttpInfo(DispatchDto dispatchDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches';

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
  Future<ApiResponseDispatchDto?> createDispatch1(DispatchDto dispatchDto,) async {
    final response = await createDispatch1WithHttpInfo(dispatchDto,);
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

  /// Performs an HTTP 'DELETE /api/admin/dispatches/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteDispatch1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}'
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
  Future<ApiResponseVoid?> deleteDispatch1(int id,) async {
    final response = await deleteDispatch1WithHttpInfo(id,);
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

  /// Performs an HTTP 'POST /api/admin/dispatches/driver/load-proof/{dispatchId}/load' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] dispatchId (required):
  ///
  /// * [List<MultipartFile>] images (required):
  ///
  /// * [String] remarks:
  ///
  /// * [MultipartFile] signature:
  Future<Response> driverSubmitLoadProof1WithHttpInfo(int dispatchId, List<MultipartFile> images, { String? remarks, MultipartFile? signature, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/driver/load-proof/{dispatchId}/load'
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
  /// * [List<MultipartFile>] images (required):
  ///
  /// * [String] remarks:
  ///
  /// * [MultipartFile] signature:
  Future<ApiResponseLoadProofDto?> driverSubmitLoadProof1(int dispatchId, List<MultipartFile> images, { String? remarks, MultipartFile? signature, }) async {
    final response = await driverSubmitLoadProof1WithHttpInfo(dispatchId, images,  remarks: remarks, signature: signature, );
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

  /// Performs an HTTP 'GET /api/admin/dispatches/filter' operation and returns the [Response].
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
  Future<Response> filterDispatches1WithHttpInfo(Pageable pageable, { int? driverId, int? vehicleId, String? status, String? driverName, String? routeCode, String? q, String? customerName, String? destinationTo, String? truckPlate, String? tripNo, DateTime? start, DateTime? end, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/filter';

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
  Future<ApiResponsePageDispatchDto?> filterDispatches1(Pageable pageable, { int? driverId, int? vehicleId, String? status, String? driverName, String? routeCode, String? q, String? customerName, String? destinationTo, String? truckPlate, String? tripNo, DateTime? start, DateTime? end, }) async {
    final response = await filterDispatches1WithHttpInfo(pageable,  driverId: driverId, vehicleId: vehicleId, status: status, driverName: driverName, routeCode: routeCode, q: q, customerName: customerName, destinationTo: destinationTo, truckPlate: truckPlate, tripNo: tripNo, start: start, end: end, );
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

  /// Performs an HTTP 'GET /api/admin/dispatches' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Pageable] pageable (required):
  Future<Response> getAllDispatches1WithHttpInfo(Pageable pageable,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches';

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
  Future<ApiResponsePageDispatchDto?> getAllDispatches1(Pageable pageable,) async {
    final response = await getAllDispatches1WithHttpInfo(pageable,);
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

  /// Performs an HTTP 'GET /api/admin/dispatches/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getDispatchById1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}'
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
  Future<ApiResponseDispatchDto?> getDispatchById1(int id,) async {
    final response = await getDispatchById1WithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/dispatches/{id}/status-history' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getDispatchStatusHistory1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/status-history'
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
  Future<ApiResponseListDispatchStatusHistoryDto?> getDispatchStatusHistory1(int id,) async {
    final response = await getDispatchStatusHistory1WithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/dispatches/driver/{driverId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [DateTime] from:
  ///
  /// * [DateTime] to:
  Future<Response> getDispatchesByDriverWithDateRange1WithHttpInfo(int driverId, Pageable pageable, { DateTime? from, DateTime? to, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/driver/{driverId}'
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
  Future<PageDispatchDto?> getDispatchesByDriverWithDateRange1(int driverId, Pageable pageable, { DateTime? from, DateTime? to, }) async {
    final response = await getDispatchesByDriverWithDateRange1WithHttpInfo(driverId, pageable,  from: from, to: to, );
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

  /// Performs an HTTP 'GET /api/admin/dispatches/driver/{driverId}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [Pageable] pageable (required):
  ///
  /// * [String] status:
  Future<Response> getDispatchesByDriverWithStatusFilter1WithHttpInfo(int driverId, Pageable pageable, { String? status, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/driver/{driverId}/status'
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
  Future<PageDispatchDto?> getDispatchesByDriverWithStatusFilter1(int driverId, Pageable pageable, { String? status, }) async {
    final response = await getDispatchesByDriverWithStatusFilter1WithHttpInfo(driverId, pageable,  status: status, );
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

  /// Performs an HTTP 'GET /api/admin/dispatches/proofs/load' operation and returns the [Response].
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
  Future<Response> getFilteredLoadProofs1WithHttpInfo({ String? search, String? driver, String? route, DateTime? from, DateTime? to, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/proofs/load';

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
  Future<ApiResponseListLoadProofDto?> getFilteredLoadProofs1({ String? search, String? driver, String? route, DateTime? from, DateTime? to, }) async {
    final response = await getFilteredLoadProofs1WithHttpInfo( search: search, driver: driver, route: route, from: from, to: to, );
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

  /// Performs an HTTP 'POST /api/admin/dispatches/import-bulk' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  Future<Response> importBulkDispatches1WithHttpInfo(MultipartFile file,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/import-bulk';

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
  Future<ApiResponseString?> importBulkDispatches1(MultipartFile file,) async {
    final response = await importBulkDispatches1WithHttpInfo(file,);
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

  /// Performs an HTTP 'POST /api/admin/dispatches/{dispatchId}/unload' operation and returns the [Response].
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
  Future<Response> markAsUnloaded1WithHttpInfo(int dispatchId, { String? remarks, String? address, double? latitude, double? longitude, MarkAsUnloadedRequest? markAsUnloadedRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{dispatchId}/unload'
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
  Future<Object?> markAsUnloaded1(int dispatchId, { String? remarks, String? address, double? latitude, double? longitude, MarkAsUnloadedRequest? markAsUnloadedRequest, }) async {
    final response = await markAsUnloaded1WithHttpInfo(dispatchId,  remarks: remarks, address: address, latitude: latitude, longitude: longitude, markAsUnloadedRequest: markAsUnloadedRequest, );
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

  /// Performs an HTTP 'POST /api/admin/dispatches/{id}/notify-assigned-driver' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> notifyAssignedDriver1WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/notify-assigned-driver'
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
  Future<ApiResponseDispatchDto?> notifyAssignedDriver1(int id,) async {
    final response = await notifyAssignedDriver1WithHttpInfo(id,);
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

  /// Performs an HTTP 'POST /api/admin/dispatches/plan-trip' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody (required):
  Future<Response> planTrip1WithHttpInfo(Map<String, Object> requestBody,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/plan-trip';

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
  Future<ApiResponseDispatchDto?> planTrip1(Map<String, Object> requestBody,) async {
    final response = await planTrip1WithHttpInfo(requestBody,);
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

  /// Performs an HTTP 'POST /api/admin/dispatches/{id}/reject' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [String] reason (required):
  Future<Response> rejectDispatch1WithHttpInfo(int id, String reason,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/reject'
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
  Future<ApiResponseDispatchDto?> rejectDispatch1(int id, String reason,) async {
    final response = await rejectDispatch1WithHttpInfo(id, reason,);
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

  /// Performs an HTTP 'POST /api/admin/dispatches/{dispatchId}/load' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] dispatchId (required):
  ///
  /// * [List<MultipartFile>] images (required):
  ///
  /// * [String] remarks:
  ///
  /// * [MultipartFile] signature:
  Future<Response> submitLoadProof1WithHttpInfo(int dispatchId, List<MultipartFile> images, { String? remarks, MultipartFile? signature, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{dispatchId}/load'
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
  /// * [List<MultipartFile>] images (required):
  ///
  /// * [String] remarks:
  ///
  /// * [MultipartFile] signature:
  Future<ApiResponseLoadProofDto?> submitLoadProof1(int dispatchId, List<MultipartFile> images, { String? remarks, MultipartFile? signature, }) async {
    final response = await submitLoadProof1WithHttpInfo(dispatchId, images,  remarks: remarks, signature: signature, );
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

  /// Performs an HTTP 'POST /api/admin/dispatches/driver/unload-proof/{dispatchId}/unload' operation and returns the [Response].
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
  Future<Response> submitUnloadProof1WithHttpInfo(int dispatchId, { String? remarks, String? address, double? latitude, double? longitude, List<MultipartFile>? images, MultipartFile? signature, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/driver/unload-proof/{dispatchId}/unload'
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
  Future<ApiResponseUnloadProofDto?> submitUnloadProof1(int dispatchId, { String? remarks, String? address, double? latitude, double? longitude, List<MultipartFile>? images, MultipartFile? signature, }) async {
    final response = await submitUnloadProof1WithHttpInfo(dispatchId,  remarks: remarks, address: address, latitude: latitude, longitude: longitude, images: images, signature: signature, );
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

  /// Performs an HTTP 'PUT /api/admin/dispatches/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [DispatchDto] dispatchDto (required):
  Future<Response> updateDispatch1WithHttpInfo(int id, DispatchDto dispatchDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}'
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
  Future<ApiResponseDispatchDto?> updateDispatch1(int id, DispatchDto dispatchDto,) async {
    final response = await updateDispatch1WithHttpInfo(id, dispatchDto,);
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

  /// Performs an HTTP 'PATCH /api/admin/dispatches/{id}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [String] status (required):
  Future<Response> updateDispatchStatus1WithHttpInfo(int id, String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/dispatches/{id}/status'
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
  Future<ApiResponseDispatchDto?> updateDispatchStatus1(int id, String status,) async {
    final response = await updateDispatchStatus1WithHttpInfo(id, status,);
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
