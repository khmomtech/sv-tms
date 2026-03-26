//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class KhbSoUploadControllerApi {
  KhbSoUploadControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/khb-so-upload/commit' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [Map<String, Object>] requestBody (required):
  Future<Response> commit1WithHttpInfo(Map<String, Object> requestBody,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/commit';

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
  Future<Map<String, Object>?> commit1(Map<String, Object> requestBody,) async {
    final response = await commit1WithHttpInfo(requestBody,);
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

  /// Performs an HTTP 'GET /api/khb-so-upload/khb/final-summary/excel' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] date (required):
  ///
  /// * [String] zone:
  Future<Response> downloadFinalSummaryExcel1WithHttpInfo(DateTime date, { String? zone, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/khb/final-summary/excel';

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
  Future<String?> downloadFinalSummaryExcel1(DateTime date, { String? zone, }) async {
    final response = await downloadFinalSummaryExcel1WithHttpInfo(date,  zone: zone, );
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

  /// Performs an HTTP 'GET /api/khb-so-upload/plan-trip/export' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  ///
  /// * [String] distributorCode:
  Future<Response> exportTripPlan1WithHttpInfo(String uploadDate, { String? zone, String? distributorCode, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/plan-trip/export';

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
  Future<String?> exportTripPlan1(String uploadDate, { String? zone, String? distributorCode, }) async {
    final response = await exportTripPlan1WithHttpInfo(uploadDate,  zone: zone, distributorCode: distributorCode, );
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

  /// Performs an HTTP 'GET /api/khb-so-upload/report/final-summary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  Future<Response> getFinalSummaryJson1WithHttpInfo(String uploadDate, { String? zone, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/report/final-summary';

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
  Future<List<FinalSummaryRow>?> getFinalSummaryJson1(String uploadDate, { String? zone, }) async {
    final response = await getFinalSummaryJson1WithHttpInfo(uploadDate,  zone: zone, );
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

  /// Performs an HTTP 'GET /api/khb-so-upload/pre-plan/summary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] uploadDate (required):
  ///
  /// * [String] zone:
  Future<Response> getPrePlanSummary1WithHttpInfo(String uploadDate, { String? zone, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/pre-plan/summary';

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
  Future<List<TripPrePlanResponseDto>?> getPrePlanSummary1(String uploadDate, { String? zone, }) async {
    final response = await getPrePlanSummary1WithHttpInfo(uploadDate,  zone: zone, );
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

  /// Performs an HTTP 'GET /api/khb-so-upload/plan-trip/temp' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] uploadDate (required):
  ///
  /// * [String] zone:
  Future<Response> getPreviewTrips1WithHttpInfo(DateTime uploadDate, { String? zone, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/plan-trip/temp';

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
  Future<List<KhbTempTrip>?> getPreviewTrips1(DateTime uploadDate, { String? zone, }) async {
    final response = await getPreviewTrips1WithHttpInfo(uploadDate,  zone: zone, );
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

  /// Performs an HTTP 'GET /api/khb-so-upload/plan-trip' operation and returns the [Response].
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
  Future<Response> planTrip3WithHttpInfo(String uploadDate, { String? zone, String? distributorCode, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/plan-trip';

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
  Future<Object?> planTrip3(String uploadDate, { String? zone, String? distributorCode, int? page, int? size, }) async {
    final response = await planTrip3WithHttpInfo(uploadDate,  zone: zone, distributorCode: distributorCode, page: page, size: size, );
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

  /// Performs an HTTP 'POST /api/khb-so-upload/preview' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> preview1WithHttpInfo({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/preview';

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
  Future<Map<String, Object>?> preview1({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await preview1WithHttpInfo( updateDocumentFileRequest: updateDocumentFileRequest, );
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

  /// Performs an HTTP 'POST /api/khb-so-upload/pre-plan/summary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [TripPrePlanRequest] tripPrePlanRequest (required):
  Future<Response> savePrePlan1WithHttpInfo(TripPrePlanRequest tripPrePlanRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/pre-plan/summary';

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
  Future<Object?> savePrePlan1(TripPrePlanRequest tripPrePlanRequest,) async {
    final response = await savePrePlan1WithHttpInfo(tripPrePlanRequest,);
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

  /// Performs an HTTP 'POST /api/khb-so-upload/plan-trip/preview' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [List<KhbTempTrip>] khbTempTrip (required):
  Future<Response> savePreviewTrips1WithHttpInfo(List<KhbTempTrip> khbTempTrip,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/plan-trip/preview';

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
  Future<Object?> savePreviewTrips1(List<KhbTempTrip> khbTempTrip,) async {
    final response = await savePreviewTrips1WithHttpInfo(khbTempTrip,);
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

  /// Performs an HTTP 'POST /api/khb-so-upload/upload' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [UpdateDocumentFileRequest] updateDocumentFileRequest:
  Future<Response> uploadSOFile1WithHttpInfo({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/khb-so-upload/upload';

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
  Future<Object?> uploadSOFile1({ UpdateDocumentFileRequest? updateDocumentFileRequest, }) async {
    final response = await uploadSOFile1WithHttpInfo( updateDocumentFileRequest: updateDocumentFileRequest, );
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
