//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class NotificationControllerApi {
  NotificationControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/notifications/driver/broadcast' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [BroadcastNotificationRequest] broadcastNotificationRequest (required):
  Future<Response> broadcastWithHttpInfo(BroadcastNotificationRequest broadcastNotificationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/broadcast';

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
  Future<ApiResponseString?> broadcast(BroadcastNotificationRequest broadcastNotificationRequest,) async {
    final response = await broadcastWithHttpInfo(broadcastNotificationRequest,);
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

  /// Performs an HTTP 'GET /api/notifications/driver/{driverId}/count' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> countDriverUnreadWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{driverId}/count'
      .replaceAll('{driverId}', driverId.toString());

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
  Future<ApiResponseLong?> countDriverUnread(int driverId,) async {
    final response = await countDriverUnreadWithHttpInfo(driverId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseLong',) as ApiResponseLong;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/notifications/admin/count' operation and returns the [Response].
  Future<Response> countUnreadAdminNotificationsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/admin/count';

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

  Future<ApiResponseLong?> countUnreadAdminNotifications() async {
    final response = await countUnreadAdminNotificationsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseLong',) as ApiResponseLong;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/notifications/admin/unread' operation and returns the [Response].
  Future<Response> countUnreadsAdminNotificationsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/admin/unread';

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

  Future<ApiResponseLong?> countUnreadsAdminNotifications() async {
    final response = await countUnreadsAdminNotificationsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseLong',) as ApiResponseLong;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/notifications/admin/create' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [CreateNotificationRequest] createNotificationRequest (required):
  Future<Response> createAdminNotificationWithHttpInfo(CreateNotificationRequest createNotificationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/admin/create';

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
  Future<ApiResponseString?> createAdminNotification(CreateNotificationRequest createNotificationRequest,) async {
    final response = await createAdminNotificationWithHttpInfo(createNotificationRequest,);
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

  /// Performs an HTTP 'DELETE /api/notifications/admin/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteAdminNotificationWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/admin/{id}'
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
  Future<ApiResponseString?> deleteAdminNotification(int id,) async {
    final response = await deleteAdminNotificationWithHttpInfo(id,);
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

  /// Performs an HTTP 'DELETE /api/notifications/admin/all' operation and returns the [Response].
  Future<Response> deleteAllAdminNotificationsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/admin/all';

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

  Future<ApiResponseString?> deleteAllAdminNotifications() async {
    final response = await deleteAllAdminNotificationsWithHttpInfo();
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

  /// Performs an HTTP 'DELETE /api/notifications/driver/{driverId}/all' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> deleteAllForDriverWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{driverId}/all'
      .replaceAll('{driverId}', driverId.toString());

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
  Future<ApiResponseString?> deleteAllForDriver(int driverId,) async {
    final response = await deleteAllForDriverWithHttpInfo(driverId,);
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

  /// Performs an HTTP 'DELETE /api/notifications/driver/{driverId}/batch' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [IdsPayload] idsPayload (required):
  Future<Response> deleteBatchForDriverWithHttpInfo(int driverId, IdsPayload idsPayload,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{driverId}/batch'
      .replaceAll('{driverId}', driverId.toString());

    // ignore: prefer_final_locals
    Object? postBody = idsPayload;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


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
  /// * [IdsPayload] idsPayload (required):
  Future<ApiResponseString?> deleteBatchForDriver(int driverId, IdsPayload idsPayload,) async {
    final response = await deleteBatchForDriverWithHttpInfo(driverId, idsPayload,);
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

  /// Performs an HTTP 'DELETE /api/notifications/driver/{driverId}/{notificationId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<Response> deleteDriverNotificationWithHttpInfo(int driverId, int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{driverId}/{notificationId}'
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
  Future<ApiResponseString?> deleteDriverNotification(int driverId, int notificationId,) async {
    final response = await deleteDriverNotificationWithHttpInfo(driverId, notificationId,);
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

  /// Performs an HTTP 'DELETE /api/notifications/driver/{notificationId}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] notificationId (required):
  Future<Response> deleteDriverNotificationLegacyWithHttpInfo(int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{notificationId}'
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
  /// * [int] notificationId (required):
  Future<ApiResponseString?> deleteDriverNotificationLegacy(int notificationId,) async {
    final response = await deleteDriverNotificationLegacyWithHttpInfo(notificationId,);
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

  /// Performs an HTTP 'DELETE /api/notifications/driver/{driverId}/delete-read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> deleteReadForDriverWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{driverId}/delete-read'
      .replaceAll('{driverId}', driverId.toString());

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
  Future<ApiResponseString?> deleteReadForDriver(int driverId,) async {
    final response = await deleteReadForDriverWithHttpInfo(driverId,);
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

  /// Performs an HTTP 'GET /api/notifications/admin' operation and returns the [Response].
  Future<Response> getAllAdminNotificationsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/admin';

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

  Future<ApiResponseListNotificationDTO?> getAllAdminNotifications() async {
    final response = await getAllAdminNotificationsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListNotificationDTO',) as ApiResponseListNotificationDTO;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/notifications/driver/{driverId}' operation and returns the [Response].
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
  Future<Response> getDriverNotificationsWithHttpInfo(int driverId, { String? order, bool? unreadOnly, DateTime? since, int? page, int? size, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{driverId}'
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
  Future<ApiResponseMapStringObject?> getDriverNotifications(int driverId, { String? order, bool? unreadOnly, DateTime? since, int? page, int? size, }) async {
    final response = await getDriverNotificationsWithHttpInfo(driverId,  order: order, unreadOnly: unreadOnly, since: since, page: page, size: size, );
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

  /// Performs an HTTP 'PUT /api/notifications/admin/{id}/read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> markAdminAsReadWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/admin/{id}/read'
      .replaceAll('{id}', id.toString());

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
  /// * [int] id (required):
  Future<ApiResponseString?> markAdminAsRead(int id,) async {
    final response = await markAdminAsReadWithHttpInfo(id,);
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

  /// Performs an HTTP 'PATCH /api/notifications/admin/mark-all-read' operation and returns the [Response].
  Future<Response> markAllAdminAsReadWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/admin/mark-all-read';

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

  Future<ApiResponseString?> markAllAdminAsRead() async {
    final response = await markAllAdminAsReadWithHttpInfo();
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

  /// Performs an HTTP 'PATCH /api/notifications/driver/{driverId}/mark-all-read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> markAllAsReadWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{driverId}/mark-all-read'
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
  Future<ApiResponseString?> markAllAsRead(int driverId,) async {
    final response = await markAllAsReadWithHttpInfo(driverId,);
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

  /// Performs an HTTP 'PUT /api/notifications/driver/{driverId}/{notificationId}/read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  ///
  /// * [int] notificationId (required):
  Future<Response> markAsReadWithHttpInfo(int driverId, int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{driverId}/{notificationId}/read'
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
  Future<ApiResponseString?> markAsRead(int driverId, int notificationId,) async {
    final response = await markAsReadWithHttpInfo(driverId, notificationId,);
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

  /// Performs an HTTP 'PUT /api/notifications/driver/{notificationId}/read' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] notificationId (required):
  Future<Response> markAsReadLegacyWithHttpInfo(int notificationId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/{notificationId}/read'
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
  Future<ApiResponseString?> markAsReadLegacy(int notificationId,) async {
    final response = await markAsReadLegacyWithHttpInfo(notificationId,);
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

  /// Performs an HTTP 'POST /api/notifications/driver/send' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [CreateNotificationRequest] createNotificationRequest (required):
  Future<Response> sendToDriverWithHttpInfo(CreateNotificationRequest createNotificationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/notifications/driver/send';

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
  Future<ApiResponseString?> sendToDriver(CreateNotificationRequest createNotificationRequest,) async {
    final response = await sendToDriverWithHttpInfo(createNotificationRequest,);
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
