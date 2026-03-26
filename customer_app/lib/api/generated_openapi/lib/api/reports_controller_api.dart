//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ReportsControllerApi {
  ReportsControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'GET /api/admin/reports/dispatch/day' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] planFrom (required):
  ///
  /// * [DateTime] planTo (required):
  ///
  /// * [String] fromTime:
  ///
  /// * [String] toTime:
  ///
  /// * [int] toExtraDays:
  Future<Response> dispatchDayWithHttpInfo(DateTime planFrom, DateTime planTo, { String? fromTime, String? toTime, int? toExtraDays, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/reports/dispatch/day';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'planFrom', planFrom));
      queryParams.addAll(_queryParams('', 'planTo', planTo));
    if (fromTime != null) {
      queryParams.addAll(_queryParams('', 'fromTime', fromTime));
    }
    if (toTime != null) {
      queryParams.addAll(_queryParams('', 'toTime', toTime));
    }
    if (toExtraDays != null) {
      queryParams.addAll(_queryParams('', 'toExtraDays', toExtraDays));
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
  /// * [DateTime] planFrom (required):
  ///
  /// * [DateTime] planTo (required):
  ///
  /// * [String] fromTime:
  ///
  /// * [String] toTime:
  ///
  /// * [int] toExtraDays:
  Future<List<DispatchDayReportRow>?> dispatchDay(DateTime planFrom, DateTime planTo, { String? fromTime, String? toTime, int? toExtraDays, }) async {
    final response = await dispatchDayWithHttpInfo(planFrom, planTo,  fromTime: fromTime, toTime: toTime, toExtraDays: toExtraDays, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<DispatchDayReportRow>') as List)
        .cast<DispatchDayReportRow>()
        .toList(growable: false);

    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/reports/dispatch/day/export' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] planFrom (required):
  ///
  /// * [DateTime] planTo (required):
  ///
  /// * [String] fromTime:
  ///
  /// * [String] toTime:
  ///
  /// * [int] toExtraDays:
  Future<Response> exportCsvWithHttpInfo(DateTime planFrom, DateTime planTo, { String? fromTime, String? toTime, int? toExtraDays, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/reports/dispatch/day/export';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'planFrom', planFrom));
      queryParams.addAll(_queryParams('', 'planTo', planTo));
    if (fromTime != null) {
      queryParams.addAll(_queryParams('', 'fromTime', fromTime));
    }
    if (toTime != null) {
      queryParams.addAll(_queryParams('', 'toTime', toTime));
    }
    if (toExtraDays != null) {
      queryParams.addAll(_queryParams('', 'toExtraDays', toExtraDays));
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
  /// * [DateTime] planFrom (required):
  ///
  /// * [DateTime] planTo (required):
  ///
  /// * [String] fromTime:
  ///
  /// * [String] toTime:
  ///
  /// * [int] toExtraDays:
  Future<void> exportCsv(DateTime planFrom, DateTime planTo, { String? fromTime, String? toTime, int? toExtraDays, }) async {
    final response = await exportCsvWithHttpInfo(planFrom, planTo,  fromTime: fromTime, toTime: toTime, toExtraDays: toExtraDays, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Performs an HTTP 'GET /api/admin/reports/dispatch/day/export.xlsx' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DateTime] planFrom (required):
  ///
  /// * [DateTime] planTo (required):
  ///
  /// * [String] fromTime:
  ///
  /// * [String] toTime:
  ///
  /// * [int] toExtraDays:
  Future<Response> exportExcelWithHttpInfo(DateTime planFrom, DateTime planTo, { String? fromTime, String? toTime, int? toExtraDays, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/reports/dispatch/day/export.xlsx';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'planFrom', planFrom));
      queryParams.addAll(_queryParams('', 'planTo', planTo));
    if (fromTime != null) {
      queryParams.addAll(_queryParams('', 'fromTime', fromTime));
    }
    if (toTime != null) {
      queryParams.addAll(_queryParams('', 'toTime', toTime));
    }
    if (toExtraDays != null) {
      queryParams.addAll(_queryParams('', 'toExtraDays', toExtraDays));
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
  /// * [DateTime] planFrom (required):
  ///
  /// * [DateTime] planTo (required):
  ///
  /// * [String] fromTime:
  ///
  /// * [String] toTime:
  ///
  /// * [int] toExtraDays:
  Future<void> exportExcel(DateTime planFrom, DateTime planTo, { String? fromTime, String? toTime, int? toExtraDays, }) async {
    final response = await exportExcelWithHttpInfo(planFrom, planTo,  fromTime: fromTime, toTime: toTime, toExtraDays: toExtraDays, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }
}
