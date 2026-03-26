//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverNotificationAdminControllerApi {
  DriverNotificationAdminControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/admin/drivers/broadcast-notification' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [BroadcastNotificationRequest] broadcastNotificationRequest (required):
  Future<Response> broadcastNotification1WithHttpInfo(BroadcastNotificationRequest broadcastNotificationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/broadcast-notification';

    // ignore: prefer_final_locals
    Object? postBody = broadcastNotificationRequest;

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
  /// * [BroadcastNotificationRequest] broadcastNotificationRequest (required):
  Future<ApiResponseString?> broadcastNotification1(BroadcastNotificationRequest broadcastNotificationRequest,) async {
    final response = await broadcastNotification1WithHttpInfo(broadcastNotificationRequest,);
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

  /// Performs an HTTP 'DELETE /api/admin/drivers/{driverId}/notifications/{notificationId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<Response> deleteDriverNotification3WithHttpInfo(int driverId, int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/notifications/{notificationId}'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{notificationId}', notificationId.toString());

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
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<ApiResponseString?> deleteDriverNotification3(int driverId, int notificationId,) async {
    final response = await deleteDriverNotification3WithHttpInfo(driverId, notificationId,);
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

  /// Performs an HTTP 'POST /api/admin/drivers/{driverId}/force-open' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> forceOpenDriverApp1WithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/force-open'
      .replaceAll('{driverId}', driverId.toString());

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
  /// * [int] driverId (required):
  Future<ApiResponseString?> forceOpenDriverApp1(int driverId,) async {
    final response = await forceOpenDriverApp1WithHttpInfo(driverId,);
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

  /// Performs an HTTP 'GET /api/admin/drivers/{driverId}/notifications' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [String] order:
  ///
  /// * [bool] unreadOnly:
  ///
  /// * [DateTime] since:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<Response> getDriverNotifications3WithHttpInfo(int driverId, { String? order, bool? unreadOnly, DateTime? since, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/notifications'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (order != null) {
      queryParams.addAll(_queryParams('', 'order', order));
    }
    if (unreadOnly != null) {
      queryParams.addAll(_queryParams('', 'unreadOnly', unreadOnly));
    }
    if (since != null) {
      queryParams.addAll(_queryParams('', 'since', since));
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
  /// * [int] driverId (required):
  ///
  /// * [String] order:
  ///
  /// * [bool] unreadOnly:
  ///
  /// * [DateTime] since:
  ///
  /// * [int] page:
  ///
  /// * [int] size:
  Future<ApiResponseMapStringObject?> getDriverNotifications3(int driverId, { String? order, bool? unreadOnly, DateTime? since, int? page, int? size, }) async {
    final response = await getDriverNotifications3WithHttpInfo(driverId,  order: order, unreadOnly: unreadOnly, since: since, page: page, size: size, );
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

  /// Performs an HTTP 'PATCH /api/admin/drivers/{driverId}/notifications/mark-all-read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> markAllAsRead3WithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/notifications/mark-all-read'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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
  /// * [int] driverId (required):
  Future<ApiResponseString?> markAllAsRead3(int driverId,) async {
    final response = await markAllAsRead3WithHttpInfo(driverId,);
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

  /// Performs an HTTP 'PUT /api/admin/drivers/{driverId}/notifications/{notificationId}/read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<Response> markAsRead3WithHttpInfo(int driverId, int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/{driverId}/notifications/{notificationId}/read'
      .replaceAll('{driverId}', driverId.toString())
      .replaceAll('{notificationId}', notificationId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<ApiResponseString?> markAsRead3(int driverId, int notificationId,) async {
    final response = await markAsRead3WithHttpInfo(driverId, notificationId,);
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

  /// Performs an HTTP 'PUT /api/admin/drivers/notifications/{notificationId}/read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] notificationId (required):
  Future<Response> markAsReadLegacy2WithHttpInfo(int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/notifications/{notificationId}/read'
      .replaceAll('{notificationId}', notificationId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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
  /// * [int] notificationId (required):
  Future<ApiResponseString?> markAsReadLegacy2(int notificationId,) async {
    final response = await markAsReadLegacy2WithHttpInfo(notificationId,);
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

  /// Performs an HTTP 'POST /api/admin/drivers/send-notification' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [CreateNotificationRequest] createNotificationRequest (required):
  Future<Response> sendNotification1WithHttpInfo(CreateNotificationRequest createNotificationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/drivers/send-notification';

    // ignore: prefer_final_locals
    Object? postBody = createNotificationRequest;

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
  /// * [CreateNotificationRequest] createNotificationRequest (required):
  Future<ApiResponseString?> sendNotification1(CreateNotificationRequest createNotificationRequest,) async {
    final response = await sendNotification1WithHttpInfo(createNotificationRequest,);
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
}
