//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DriverLocationControllerApi {
  DriverLocationControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /api/driver/logout' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> driverLogoutWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/logout';

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
  /// * [int] driverId (required):
  Future<Object?> driverLogout(int driverId,) async {
    final response = await driverLogoutWithHttpInfo(driverId,);
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

  /// Performs an HTTP 'GET /api/admin/driver/{driverId}/presence' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] driverId (required):
  Future<Response> getPresenceWithHttpInfo(int driverId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/admin/driver/{driverId}/presence'
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
  Future<Map<String, Object>?> getPresence(int driverId,) async {
    final response = await getPresenceWithHttpInfo(driverId,);
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

  /// Performs an HTTP 'POST /api/driver/presence/heartbeat' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [PresenceHeartbeatDto] presenceHeartbeatDto (required):
  Future<Response> presenceHeartbeatWithHttpInfo(PresenceHeartbeatDto presenceHeartbeatDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/presence/heartbeat';

    // ignore: prefer_final_locals
    Object? postBody = presenceHeartbeatDto;

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
  /// * [PresenceHeartbeatDto] presenceHeartbeatDto (required):
  Future<Object?> presenceHeartbeat(PresenceHeartbeatDto presenceHeartbeatDto,) async {
    final response = await presenceHeartbeatWithHttpInfo(presenceHeartbeatDto,);
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

  /// Performs an HTTP 'POST /api/driver/location/update' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DriverLocationUpdateDto] driverLocationUpdateDto (required):
  Future<Response> restLocationUpdateWithHttpInfo(DriverLocationUpdateDto driverLocationUpdateDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/location/update';

    // ignore: prefer_final_locals
    Object? postBody = driverLocationUpdateDto;

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
  /// * [DriverLocationUpdateDto] driverLocationUpdateDto (required):
  Future<Object?> restLocationUpdate(DriverLocationUpdateDto driverLocationUpdateDto,) async {
    final response = await restLocationUpdateWithHttpInfo(driverLocationUpdateDto,);
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
