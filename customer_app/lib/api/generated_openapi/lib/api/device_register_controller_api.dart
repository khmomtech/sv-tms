//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DeviceRegisterControllerApi {
  DeviceRegisterControllerApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'PUT /api/driver/device/approve/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> approveDeviceWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/approve/{id}'
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
  Future<ApiResponseVoid?> approveDevice(int id,) async {
    final response = await approveDeviceWithHttpInfo(id,);
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

  /// Performs an HTTP 'PUT /api/driver/device/block/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> blockDeviceWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/block/{id}'
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
  Future<ApiResponseVoid?> blockDevice(int id,) async {
    final response = await blockDeviceWithHttpInfo(id,);
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

  /// Performs an HTTP 'POST /api/driver/device/create' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DeviceRegisterDto] deviceRegisterDto (required):
  Future<Response> createDeviceWithHttpInfo(DeviceRegisterDto deviceRegisterDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/create';

    // ignore: prefer_final_locals
    Object? postBody = deviceRegisterDto;

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
  /// * [DeviceRegisterDto] deviceRegisterDto (required):
  Future<ApiResponseDeviceRegisterDto?> createDevice(DeviceRegisterDto deviceRegisterDto,) async {
    final response = await createDeviceWithHttpInfo(deviceRegisterDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDeviceRegisterDto',) as ApiResponseDeviceRegisterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'DELETE /api/driver/device/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> deleteDeviceWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/{id}'
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
  Future<ApiResponseVoid?> deleteDevice(int id,) async {
    final response = await deleteDeviceWithHttpInfo(id,);
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

  /// Performs an HTTP 'GET /api/driver/device/filter' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [String] status (required):
  Future<Response> filterDevicesWithHttpInfo(String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/filter';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'status', status));

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
  Future<ApiResponseListDeviceRegisterDto?> filterDevices(String status,) async {
    final response = await filterDevicesWithHttpInfo(status,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDeviceRegisterDto',) as ApiResponseListDeviceRegisterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/device/all' operation and returns the [Response].
  Future<Response> getAllDevicesWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/all';

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

  Future<ApiResponseListDeviceRegisterDto?> getAllDevices() async {
    final response = await getAllDevicesWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseListDeviceRegisterDto',) as ApiResponseListDeviceRegisterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'GET /api/driver/device/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> getDeviceWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/{id}'
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
  Future<ApiResponseDeviceRegisterDto?> getDevice(int id,) async {
    final response = await getDeviceWithHttpInfo(id,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDeviceRegisterDto',) as ApiResponseDeviceRegisterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/device/register' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DeviceRegisterDto] deviceRegisterDto (required):
  Future<Response> registerDeviceWithHttpInfo(DeviceRegisterDto deviceRegisterDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/register';

    // ignore: prefer_final_locals
    Object? postBody = deviceRegisterDto;

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
  /// * [DeviceRegisterDto] deviceRegisterDto (required):
  Future<ApiResponseDeviceStatus?> registerDevice(DeviceRegisterDto deviceRegisterDto,) async {
    final response = await registerDeviceWithHttpInfo(deviceRegisterDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDeviceStatus',) as ApiResponseDeviceStatus;
    
    }
    return null;
  }

  /// Performs an HTTP 'POST /api/driver/device/request-approval' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [DeviceApprovalRequest] deviceApprovalRequest (required):
  Future<Response> requestApprovalWithHttpInfo(DeviceApprovalRequest deviceApprovalRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/request-approval';

    // ignore: prefer_final_locals
    Object? postBody = deviceApprovalRequest;

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
  /// * [DeviceApprovalRequest] deviceApprovalRequest (required):
  Future<ApiResponseVoid?> requestApproval(DeviceApprovalRequest deviceApprovalRequest,) async {
    final response = await requestApprovalWithHttpInfo(deviceApprovalRequest,);
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

  /// Performs an HTTP 'PUT /api/driver/device/pending/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  Future<Response> setPendingDeviceWithHttpInfo(int id,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/pending/{id}'
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
  Future<ApiResponseVoid?> setPendingDevice(int id,) async {
    final response = await setPendingDeviceWithHttpInfo(id,);
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

  /// Performs an HTTP 'PUT /api/driver/device/{id}' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [DeviceRegisterDto] deviceRegisterDto (required):
  Future<Response> updateDeviceWithHttpInfo(int id, DeviceRegisterDto deviceRegisterDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/{id}'
      .replaceAll('{id}', id.toString());

    // ignore: prefer_final_locals
    Object? postBody = deviceRegisterDto;

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
  /// * [DeviceRegisterDto] deviceRegisterDto (required):
  Future<ApiResponseDeviceRegisterDto?> updateDevice(int id, DeviceRegisterDto deviceRegisterDto,) async {
    final response = await updateDeviceWithHttpInfo(id, deviceRegisterDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ApiResponseDeviceRegisterDto',) as ApiResponseDeviceRegisterDto;
    
    }
    return null;
  }

  /// Performs an HTTP 'PUT /api/driver/device/{id}/status' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [int] id (required):
  ///
  /// * [String] status (required):
  Future<Response> updateDeviceStatusWithHttpInfo(int id, String status,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/driver/device/{id}/status'
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
  Future<ApiResponseVoid?> updateDeviceStatus(int id, String status,) async {
    final response = await updateDeviceStatusWithHttpInfo(id, status,);
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
}
