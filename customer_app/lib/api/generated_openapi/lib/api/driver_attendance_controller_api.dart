//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverAttendanceControllerApi {
  DriverAttendanceControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/drivers/{driverId}/attendance/permission-range' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [BulkPermissionRequest] bulkPermissionRequest (required):
  Future<Response> bulkPermissionWithHttpInfo(int driverId, BulkPermissionRequest bulkPermissionRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/attendance/permission-range'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = bulkPermissionRequest;

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
  /// * [int] driverId (required):
  ///
  /// * [BulkPermissionRequest] bulkPermissionRequest (required):
  Future<ApiResponseListAttendanceDto?> bulkPermission(int driverId, BulkPermissionRequest bulkPermissionRequest,) async {
    final response = await bulkPermissionWithHttpInfo(driverId, bulkPermissionRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListAttendanceDto',) as ApiResponseListAttendanceDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/admin/drivers/{driverId}/attendance' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [AttendanceRequest] attendanceRequest (required):
  Future<Response> create2WithHttpInfo(int driverId, AttendanceRequest attendanceRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/attendance'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = attendanceRequest;

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
  /// * [int] driverId (required):
  ///
  /// * [AttendanceRequest] attendanceRequest (required):
  Future<ApiResponseAttendanceDto?> create2(int driverId, AttendanceRequest attendanceRequest,) async {
    final response = await create2WithHttpInfo(driverId, attendanceRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseAttendanceDto',) as ApiResponseAttendanceDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/admin/drivers/attendance/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> delete2WithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/attendance/{id}'
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
  Future<ApiResponseString?> delete2(int id,) async {
    final response = await delete2WithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/attendance/date/{date}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [String] date (required):
  Future<Response> getByDateWithHttpInfo(int driverId, String date,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/attendance/date/{date}'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{date}', date);

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
  /// * [int] driverId (required):
  ///
  /// * [String] date (required):
  Future<ApiResponseAttendanceDto?> getByDate(int driverId, String date,) async {
    final response = await getByDateWithHttpInfo(driverId, date,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseAttendanceDto',) as ApiResponseAttendanceDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/attendance' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] year (required):
  ///
  /// * [int] month (required):
  Future<Response> listWithHttpInfo(int driverId, int year, int month,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/attendance'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'year', year));
      queryParams.addAll(_queryParams('', 'month', month));

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
  /// * [int] year (required):
  ///
  /// * [int] month (required):
  Future<ApiResponseListAttendanceDto?> list(int driverId, int year, int month,) async {
    final response = await listWithHttpInfo(driverId, year, month,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListAttendanceDto',) as ApiResponseListAttendanceDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/attendance' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] year:
  ///
  /// * [int] month:
  ///
  /// * [int] driverId:
  ///
  /// * [bool] permissionOnly:
  ///
  /// * [String] fromDate:
  ///
  /// * [String] toDate:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> listAllWithHttpInfo({ int? year, int? month, int? driverId, bool? permissionOnly, String? fromDate, String? toDate, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/attendance';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (year != null) {
      queryParams.addAll(_queryParams('', 'year', year));
    }
    if (month != null) {
      queryParams.addAll(_queryParams('', 'month', month));
    }
    if (driverId != null) {
      queryParams.addAll(_queryParams('', 'driverId', driverId));
    }
    if (permissionOnly != null) {
      queryParams.addAll(_queryParams('', 'permissionOnly', permissionOnly));
    }
    if (fromDate != null) {
      queryParams.addAll(_queryParams('', 'fromDate', fromDate));
    }
    if (toDate != null) {
      queryParams.addAll(_queryParams('', 'toDate', toDate));
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
  /// * [int] year:
  ///
  /// * [int] month:
  ///
  /// * [int] driverId:
  ///
  /// * [bool] permissionOnly:
  ///
  /// * [String] fromDate:
  ///
  /// * [String] toDate:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponsePageResponseAttendanceDto?> listAll({ int? year, int? month, int? driverId, bool? permissionOnly, String? fromDate, String? toDate, int? page, int? size, }) async {
    final response = await listAllWithHttpInfo( year: year, month: month, driverId: driverId, permissionOnly: permissionOnly, fromDate: fromDate, toDate: toDate, page: page, size: size, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponsePageResponseAttendanceDto',) as ApiResponsePageResponseAttendanceDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/attendance/summary' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] year (required):
  ///
  /// * [int] month (required):
  Future<Response> summaryWithHttpInfo(int driverId, int year, int month,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/attendance/summary'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'year', year));
      queryParams.addAll(_queryParams('', 'month', month));

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
  /// * [int] year (required):
  ///
  /// * [int] month (required):
  Future<ApiResponseAttendanceSummaryDto?> summary(int driverId, int year, int month,) async {
    final response = await summaryWithHttpInfo(driverId, year, month,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseAttendanceSummaryDto',) as ApiResponseAttendanceSummaryDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/admin/drivers/attendance/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [AttendanceRequest] attendanceRequest (required):
  Future<Response> update2WithHttpInfo(int id, AttendanceRequest attendanceRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/attendance/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = attendanceRequest;

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
  /// * [AttendanceRequest] attendanceRequest (required):
  Future<ApiResponseAttendanceDto?> update2(int id, AttendanceRequest attendanceRequest,) async {
    final response = await update2WithHttpInfo(id, attendanceRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseAttendanceDto',) as ApiResponseAttendanceDto;
    
    }
    return null;
  }
}
