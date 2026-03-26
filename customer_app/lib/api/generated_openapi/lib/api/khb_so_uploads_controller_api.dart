//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class KhbSoUploadsControllerApi {
  KhbSoUploadsControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/khb-so-uploads/commit' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody (required):
  Future<Response> commitWithHttpInfo(Map<String, Object> requestBody,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/commit';

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
  Future<Map<String, Object>?> commit(Map<String, Object> requestBody,) async {
    final response = await commitWithHttpInfo(requestBody,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return Map<String, Object>.from(await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Map<String, Object>'),);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/khb-so-uploads/khb/final-summary/excel' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] date (required):
  ///
  /// * [String] zone:
  Future<Response> downloadFinalSummaryExcelWithHttpInfo(DateTime date, { String? zone, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/khb/final-summary/excel';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'date', date));
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
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
  /// * [DateTime] date (required):
  ///
  /// * [String] zone:
  Future<String?> downloadFinalSummaryExcel(DateTime date, { String? zone, }) async {
    final response = await downloadFinalSummaryExcelWithHttpInfo(date,  zone: zone, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'String',) as String;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/khb-so-uploads/plan-trip/export' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  ///
  /// * [String] distributorCode:
  Future<Response> exportTripPlanWithHttpInfo(String uploadDate, { String? zone, String? distributorCode, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/plan-trip/export';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'uploadDate', uploadDate));
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
    }
    if (distributorCode != null) {
      queryParams.addAll(_queryParams('', 'distributorCode', distributorCode));
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
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  ///
  /// * [String] distributorCode:
  Future<String?> exportTripPlan(String uploadDate, { String? zone, String? distributorCode, }) async {
    final response = await exportTripPlanWithHttpInfo(uploadDate,  zone: zone, distributorCode: distributorCode, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'String',) as String;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/khb-so-uploads/report/final-summary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  Future<Response> getFinalSummaryJsonWithHttpInfo(String uploadDate, { String? zone, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/report/final-summary';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'uploadDate', uploadDate));
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
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
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  Future<List<FinalSummaryRow>?> getFinalSummaryJson(String uploadDate, { String? zone, }) async {
    final response = await getFinalSummaryJsonWithHttpInfo(uploadDate,  zone: zone, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<FinalSummaryRow>') as List)
        .cast<FinalSummaryRow>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/khb-so-uploads/pre-plan/summary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  Future<Response> getPrePlanSummaryWithHttpInfo(String uploadDate, { String? zone, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/pre-plan/summary';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'uploadDate', uploadDate));
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
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
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  Future<List<TripPrePlanResponseDto>?> getPrePlanSummary(String uploadDate, { String? zone, }) async {
    final response = await getPrePlanSummaryWithHttpInfo(uploadDate,  zone: zone, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<TripPrePlanResponseDto>') as List)
        .cast<TripPrePlanResponseDto>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/khb-so-uploads/plan-trip/temp' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] uploadDate (required):
  ///
  /// * [String] zone:
  Future<Response> getPreviewTripsWithHttpInfo(DateTime uploadDate, { String? zone, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/plan-trip/temp';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'uploadDate', uploadDate));
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
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
  /// * [DateTime] uploadDate (required):
  ///
  /// * [String] zone:
  Future<List<KhbTempTrip>?> getPreviewTrips(DateTime uploadDate, { String? zone, }) async {
    final response = await getPreviewTripsWithHttpInfo(uploadDate,  zone: zone, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<KhbTempTrip>') as List)
        .cast<KhbTempTrip>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/khb-so-uploads/plan-trip' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  ///
  /// * [String] distributorCode:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> planTrip2WithHttpInfo(String uploadDate, { String? zone, String? distributorCode, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/plan-trip';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'uploadDate', uploadDate));
    if (zone != null) {
      queryParams.addAll(_queryParams('', 'zone', zone));
    }
    if (distributorCode != null) {
      queryParams.addAll(_queryParams('', 'distributorCode', distributorCode));
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
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  ///
  /// * [String] distributorCode:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Object?> planTrip2(String uploadDate, { String? zone, String? distributorCode, int? page, int? size, }) async {
    final response = await planTrip2WithHttpInfo(uploadDate,  zone: zone, distributorCode: distributorCode, page: page, size: size, );
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

  /// Performs an HTTP 'POST /api/khb-so-uploads/preview' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> previewWithHttpInfo({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/preview';

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
  Future<Map<String, Object>?> preview({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await previewWithHttpInfo( updateDocumentFileRequest: updateDocumentFileRequest, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return Map<String, Object>.from(await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Map<String, Object>'),);

    }
    return null;
  }

  /// Performs an HTTP 'POST /api/khb-so-uploads/pre-plan/summary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [TripPrePlanRequest] tripPrePlanRequest (required):
  Future<Response> savePrePlanWithHttpInfo(TripPrePlanRequest tripPrePlanRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/pre-plan/summary';

    // ignore: prefer_final_locals
    Object? postBody = tripPrePlanRequest;

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
  /// * [TripPrePlanRequest] tripPrePlanRequest (required):
  Future<Object?> savePrePlan(TripPrePlanRequest tripPrePlanRequest,) async {
    final response = await savePrePlanWithHttpInfo(tripPrePlanRequest,);
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

  /// Performs an HTTP 'POST /api/khb-so-uploads/plan-trip/preview' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [List<KhbTempTrip>] khbTempTrip (required):
  Future<Response> savePreviewTripsWithHttpInfo(List<KhbTempTrip> khbTempTrip,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/plan-trip/preview';

    // ignore: prefer_final_locals
    Object? postBody = khbTempTrip;

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
  /// * [List<KhbTempTrip>] khbTempTrip (required):
  Future<Object?> savePreviewTrips(List<KhbTempTrip> khbTempTrip,) async {
    final response = await savePreviewTripsWithHttpInfo(khbTempTrip,);
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

  /// Performs an HTTP 'POST /api/khb-so-uploads/upload' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> uploadSOFileWithHttpInfo({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-uploads/upload';

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
  Future<Object?> uploadSOFile({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await uploadSOFileWithHttpInfo( updateDocumentFileRequest: updateDocumentFileRequest, );
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
}
