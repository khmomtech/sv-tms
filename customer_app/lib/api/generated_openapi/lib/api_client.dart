//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiClient {
  ApiClient({this.basePath = 'http://localhost:8085', this.authentication,});

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
     _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType,
  ) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty ? '?${urlEncodedQueryParams.join('&')}' : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (
        body is MultipartFile && (contentType == null ||
        !contentType.toLowerCase().startsWith('multipart/form-data'))
      ) {
        final request = StreamedRequest(method, uri);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
          request.sink.add,
          onDone: request.sink.close,
          // ignore: avoid_types_on_closure_parameters
          onError: (Object error, StackTrace trace) => request.sink.close(),
          cancelOnError: true,
        );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request = MultipartRequest(method, uri);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
        ? formParams
        : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      switch(method) {
        case 'POST': return await _client.post(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'PUT': return await _client.put(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'DELETE': return await _client.delete(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'PATCH': return await _client.patch(uri, headers: nullableHeaderParams, body: msgBody,);
        case 'HEAD': return await _client.head(uri, headers: nullableHeaderParams,);
        case 'GET': return await _client.get(uri, headers: nullableHeaderParams,);
      }
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }

    throw ApiException(
      HttpStatus.badRequest,
      'Invalid HTTP operation: $method $path',
    );
  }

  Future<dynamic> deserializeAsync(String value, String targetType, {bool growable = false,}) async =>
    // ignore: deprecated_member_use_from_same_package
    deserialize(value, targetType, growable: growable);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(String value, String targetType, {bool growable = false,}) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType = targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
      ? value
      : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated('Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(dynamic value, String targetType, {bool growable = false,}) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'AboutAppInfo':
          return AboutAppInfo.fromJson(value);
        case 'Address':
          return Address.fromJson(value);
        case 'ApiResponseAttendanceDto':
          return ApiResponseAttendanceDto.fromJson(value);
        case 'ApiResponseAttendanceSummaryDto':
          return ApiResponseAttendanceSummaryDto.fromJson(value);
        case 'ApiResponseBannerDto':
          return ApiResponseBannerDto.fromJson(value);
        case 'ApiResponseBoolean':
          return ApiResponseBoolean.fromJson(value);
        case 'ApiResponseCustomerDto':
          return ApiResponseCustomerDto.fromJson(value);
        case 'ApiResponseDashboardSummaryResponse':
          return ApiResponseDashboardSummaryResponse.fromJson(value);
        case 'ApiResponseDeviceRegisterDto':
          return ApiResponseDeviceRegisterDto.fromJson(value);
        case 'ApiResponseDeviceStatus':
          return ApiResponseDeviceStatus.fromJson(value);
        case 'ApiResponseDispatchDto':
          return ApiResponseDispatchDto.fromJson(value);
        case 'ApiResponseDocumentAuditDto':
          return ApiResponseDocumentAuditDto.fromJson(value);
        case 'ApiResponseDriverAssignment':
          return ApiResponseDriverAssignment.fromJson(value);
        case 'ApiResponseDriverAssignmentDto':
          return ApiResponseDriverAssignmentDto.fromJson(value);
        case 'ApiResponseDriverDocument':
          return ApiResponseDriverDocument.fromJson(value);
        case 'ApiResponseDriverDto':
          return ApiResponseDriverDto.fromJson(value);
        case 'ApiResponseDriverIssueDto':
          return ApiResponseDriverIssueDto.fromJson(value);
        case 'ApiResponseDriverLicenseDto':
          return ApiResponseDriverLicenseDto.fromJson(value);
        case 'ApiResponseItemDto':
          return ApiResponseItemDto.fromJson(value);
        case 'ApiResponseListAttendanceDto':
          return ApiResponseListAttendanceDto.fromJson(value);
        case 'ApiResponseListBannerDto':
          return ApiResponseListBannerDto.fromJson(value);
        case 'ApiResponseListCustomer':
          return ApiResponseListCustomer.fromJson(value);
        case 'ApiResponseListCustomerDto':
          return ApiResponseListCustomerDto.fromJson(value);
        case 'ApiResponseListDeviceRegisterDto':
          return ApiResponseListDeviceRegisterDto.fromJson(value);
        case 'ApiResponseListDispatchStatusHistoryDto':
          return ApiResponseListDispatchStatusHistoryDto.fromJson(value);
        case 'ApiResponseListDriverAssignmentDto':
          return ApiResponseListDriverAssignmentDto.fromJson(value);
        case 'ApiResponseListDriverDocument':
          return ApiResponseListDriverDocument.fromJson(value);
        case 'ApiResponseListDriverDto':
          return ApiResponseListDriverDto.fromJson(value);
        case 'ApiResponseListDriverLicenseDto':
          return ApiResponseListDriverLicenseDto.fromJson(value);
        case 'ApiResponseListItemDto':
          return ApiResponseListItemDto.fromJson(value);
        case 'ApiResponseListLiveDriverDto':
          return ApiResponseListLiveDriverDto.fromJson(value);
        case 'ApiResponseListLoadProofDto':
          return ApiResponseListLoadProofDto.fromJson(value);
        case 'ApiResponseListLoadingSummaryRowDto':
          return ApiResponseListLoadingSummaryRowDto.fromJson(value);
        case 'ApiResponseListLocationHistoryDto':
          return ApiResponseListLocationHistoryDto.fromJson(value);
        case 'ApiResponseListLong':
          return ApiResponseListLong.fromJson(value);
        case 'ApiResponseListMaintenanceTaskDto':
          return ApiResponseListMaintenanceTaskDto.fromJson(value);
        case 'ApiResponseListMaintenanceTaskTypeDto':
          return ApiResponseListMaintenanceTaskTypeDto.fromJson(value);
        case 'ApiResponseListMapStringObject':
          return ApiResponseListMapStringObject.fromJson(value);
        case 'ApiResponseListNotificationDTO':
          return ApiResponseListNotificationDTO.fromJson(value);
        case 'ApiResponseListOrderAddress':
          return ApiResponseListOrderAddress.fromJson(value);
        case 'ApiResponseListOrderAddressDto':
          return ApiResponseListOrderAddressDto.fromJson(value);
        case 'ApiResponseListOrderItem':
          return ApiResponseListOrderItem.fromJson(value);
        case 'ApiResponseListPartnerAdmin':
          return ApiResponseListPartnerAdmin.fromJson(value);
        case 'ApiResponseListPartnerCompany':
          return ApiResponseListPartnerCompany.fromJson(value);
        case 'ApiResponseListPermission':
          return ApiResponseListPermission.fromJson(value);
        case 'ApiResponseListTopDriverDto':
          return ApiResponseListTopDriverDto.fromJson(value);
        case 'ApiResponseListTransportOrderDto':
          return ApiResponseListTransportOrderDto.fromJson(value);
        case 'ApiResponseListUserSetting':
          return ApiResponseListUserSetting.fromJson(value);
        case 'ApiResponseListVehicleDto':
          return ApiResponseListVehicleDto.fromJson(value);
        case 'ApiResponseListVehicleWithDriverDto':
          return ApiResponseListVehicleWithDriverDto.fromJson(value);
        case 'ApiResponseLiveDriverDto':
          return ApiResponseLiveDriverDto.fromJson(value);
        case 'ApiResponseLoadProofDto':
          return ApiResponseLoadProofDto.fromJson(value);
        case 'ApiResponseLong':
          return ApiResponseLong.fromJson(value);
        case 'ApiResponseMaintenanceTaskDto':
          return ApiResponseMaintenanceTaskDto.fromJson(value);
        case 'ApiResponseMaintenanceTaskTypeDto':
          return ApiResponseMaintenanceTaskTypeDto.fromJson(value);
        case 'ApiResponseMapStringBoolean':
          return ApiResponseMapStringBoolean.fromJson(value);
        case 'ApiResponseMapStringObject':
          return ApiResponseMapStringObject.fromJson(value);
        case 'ApiResponseObject':
          return ApiResponseObject.fromJson(value);
        case 'ApiResponseOrderAddressDto':
          return ApiResponseOrderAddressDto.fromJson(value);
        case 'ApiResponsePageCustomer':
          return ApiResponsePageCustomer.fromJson(value);
        case 'ApiResponsePageDispatchDto':
          return ApiResponsePageDispatchDto.fromJson(value);
        case 'ApiResponsePageDriverIssueDto':
          return ApiResponsePageDriverIssueDto.fromJson(value);
        case 'ApiResponsePageLocationHistoryDto':
          return ApiResponsePageLocationHistoryDto.fromJson(value);
        case 'ApiResponsePageMaintenanceTaskDto':
          return ApiResponsePageMaintenanceTaskDto.fromJson(value);
        case 'ApiResponsePageMaintenanceTaskTypeDto':
          return ApiResponsePageMaintenanceTaskTypeDto.fromJson(value);
        case 'ApiResponsePageNotificationDTO':
          return ApiResponsePageNotificationDTO.fromJson(value);
        case 'ApiResponsePageResponseAttendanceDto':
          return ApiResponsePageResponseAttendanceDto.fromJson(value);
        case 'ApiResponsePageResponseDriverDto':
          return ApiResponsePageResponseDriverDto.fromJson(value);
        case 'ApiResponsePageTransportOrder':
          return ApiResponsePageTransportOrder.fromJson(value);
        case 'ApiResponsePageTransportOrderDto':
          return ApiResponsePageTransportOrderDto.fromJson(value);
        case 'ApiResponsePageVehicleDto':
          return ApiResponsePageVehicleDto.fromJson(value);
        case 'ApiResponsePartnerAdmin':
          return ApiResponsePartnerAdmin.fromJson(value);
        case 'ApiResponsePartnerCompany':
          return ApiResponsePartnerCompany.fromJson(value);
        case 'ApiResponsePermission':
          return ApiResponsePermission.fromJson(value);
        case 'ApiResponseSetString':
          return ApiResponseSetString.fromJson(value);
        case 'ApiResponseString':
          return ApiResponseString.fromJson(value);
        case 'ApiResponseTransportOrderDto':
          return ApiResponseTransportOrderDto.fromJson(value);
        case 'ApiResponseUnloadProofDto':
          return ApiResponseUnloadProofDto.fromJson(value);
        case 'ApiResponseUserSetting':
          return ApiResponseUserSetting.fromJson(value);
        case 'ApiResponseVehicleDto':
          return ApiResponseVehicleDto.fromJson(value);
        case 'ApiResponseVehicleStatisticsDto':
          return ApiResponseVehicleStatisticsDto.fromJson(value);
        case 'ApiResponseVoid':
          return ApiResponseVoid.fromJson(value);
        case 'AppVersion':
          return AppVersion.fromJson(value);
        case 'AssignAdminRequest':
          return AssignAdminRequest.fromJson(value);
        case 'AttendanceDto':
          return AttendanceDto.fromJson(value);
        case 'AttendanceRequest':
          return AttendanceRequest.fromJson(value);
        case 'AttendanceSummaryDto':
          return AttendanceSummaryDto.fromJson(value);
        case 'AuditTrail':
          return AuditTrail.fromJson(value);
        case 'BannerDto':
          return BannerDto.fromJson(value);
        case 'BroadcastNotificationRequest':
          return BroadcastNotificationRequest.fromJson(value);
        case 'BulkPermissionRequest':
          return BulkPermissionRequest.fromJson(value);
        case 'ChangePasswordRequest':
          return ChangePasswordRequest.fromJson(value);
        case 'CreateAccountRequest':
          return CreateAccountRequest.fromJson(value);
        case 'CreateNotificationRequest':
          return CreateNotificationRequest.fromJson(value);
        case 'CreatePermissionRequest':
          return CreatePermissionRequest.fromJson(value);
        case 'Customer':
          return Customer.fromJson(value);
        case 'CustomerDto':
          return CustomerDto.fromJson(value);
        case 'DashboardSummaryDto':
          return DashboardSummaryDto.fromJson(value);
        case 'DashboardSummaryResponse':
          return DashboardSummaryResponse.fromJson(value);
        case 'DeviceApprovalRequest':
          return DeviceApprovalRequest.fromJson(value);
        case 'DeviceRegisterDto':
          return DeviceRegisterDto.fromJson(value);
        case 'DeviceTokenRequest':
          return DeviceTokenRequest.fromJson(value);
        case 'Dispatch':
          return Dispatch.fromJson(value);
        case 'DispatchDayReportRow':
          return DispatchDayReportRow.fromJson(value);
        case 'DispatchDto':
          return DispatchDto.fromJson(value);
        case 'DispatchItem':
          return DispatchItem.fromJson(value);
        case 'DispatchItemDto':
          return DispatchItemDto.fromJson(value);
        case 'DispatchStatusHistoryDto':
          return DispatchStatusHistoryDto.fromJson(value);
        case 'DispatchStop':
          return DispatchStop.fromJson(value);
        case 'DispatchStopDto':
          return DispatchStopDto.fromJson(value);
        case 'DocumentAuditDto':
          return DocumentAuditDto.fromJson(value);
        case 'Driver':
          return Driver.fromJson(value);
        case 'DriverAssignment':
          return DriverAssignment.fromJson(value);
        case 'DriverAssignmentDto':
          return DriverAssignmentDto.fromJson(value);
        case 'DriverCreateRequest':
          return DriverCreateRequest.fromJson(value);
        case 'DriverDocument':
          return DriverDocument.fromJson(value);
        case 'DriverDocumentCreateDto':
          return DriverDocumentCreateDto.fromJson(value);
        case 'DriverDocumentUpdateDto':
          return DriverDocumentUpdateDto.fromJson(value);
        case 'DriverDto':
          return DriverDto.fromJson(value);
        case 'DriverFilterRequest':
          return DriverFilterRequest.fromJson(value);
        case 'DriverIssueDto':
          return DriverIssueDto.fromJson(value);
        case 'DriverIssuePhotoDto':
          return DriverIssuePhotoDto.fromJson(value);
        case 'DriverLicenseDto':
          return DriverLicenseDto.fromJson(value);
        case 'DriverLocationUpdateDto':
          return DriverLocationUpdateDto.fromJson(value);
        case 'DriverSimpleDto':
          return DriverSimpleDto.fromJson(value);
        case 'DriverUpdateRequest':
          return DriverUpdateRequest.fromJson(value);
        case 'DropAddress':
          return DropAddress.fromJson(value);
        case 'Employee':
          return Employee.fromJson(value);
        case 'EmployeeDto':
          return EmployeeDto.fromJson(value);
        case 'FinalSummaryRow':
          return FinalSummaryRow.fromJson(value);
        case 'ForgotPasswordRequest':
          return ForgotPasswordRequest.fromJson(value);
        case 'HeartbeatDto':
          return HeartbeatDto.fromJson(value);
        case 'IdsPayload':
          return IdsPayload.fromJson(value);
        case 'Invoice':
          return Invoice.fromJson(value);
        case 'InvoiceDto':
          return InvoiceDto.fromJson(value);
        case 'Item':
          return Item.fromJson(value);
        case 'ItemDto':
          return ItemDto.fromJson(value);
        case 'KhbTempTrip':
          return KhbTempTrip.fromJson(value);
        case 'LiveDriverDto':
          return LiveDriverDto.fromJson(value);
        case 'LoadProof':
          return LoadProof.fromJson(value);
        case 'LoadProofDto':
          return LoadProofDto.fromJson(value);
        case 'LoadingAddress':
          return LoadingAddress.fromJson(value);
        case 'LoadingSummaryRowDto':
          return LoadingSummaryRowDto.fromJson(value);
        case 'LocationHistoryDto':
          return LocationHistoryDto.fromJson(value);
        case 'LocationPoint':
          return LocationPoint.fromJson(value);
        case 'LoginRequest':
          return LoginRequest.fromJson(value);
        case 'MaintenanceTaskDto':
          return MaintenanceTaskDto.fromJson(value);
        case 'MaintenanceTaskTypeDto':
          return MaintenanceTaskTypeDto.fromJson(value);
        case 'MarkAsUnloadedRequest':
          return MarkAsUnloadedRequest.fromJson(value);
        case 'NotificationDTO':
          return NotificationDTO.fromJson(value);
        case 'Order':
          return Order.fromJson(value);
        case 'OrderAddress':
          return OrderAddress.fromJson(value);
        case 'OrderAddressDto':
          return OrderAddressDto.fromJson(value);
        case 'OrderItem':
          return OrderItem.fromJson(value);
        case 'OrderItemDto':
          return OrderItemDto.fromJson(value);
        case 'OrderStop':
          return OrderStop.fromJson(value);
        case 'OrderStopDto':
          return OrderStopDto.fromJson(value);
        case 'PMScheduleDto':
          return PMScheduleDto.fromJson(value);
        case 'PageCustomer':
          return PageCustomer.fromJson(value);
        case 'PageDispatchDto':
          return PageDispatchDto.fromJson(value);
        case 'PageDriverIssueDto':
          return PageDriverIssueDto.fromJson(value);
        case 'PageLocationHistoryDto':
          return PageLocationHistoryDto.fromJson(value);
        case 'PageMaintenanceTaskDto':
          return PageMaintenanceTaskDto.fromJson(value);
        case 'PageMaintenanceTaskTypeDto':
          return PageMaintenanceTaskTypeDto.fromJson(value);
        case 'PageNotificationDTO':
          return PageNotificationDTO.fromJson(value);
        case 'PagePMScheduleDto':
          return PagePMScheduleDto.fromJson(value);
        case 'PagePartsMasterDto':
          return PagePartsMasterDto.fromJson(value);
        case 'PageResponseAttendanceDto':
          return PageResponseAttendanceDto.fromJson(value);
        case 'PageResponseDriverDto':
          return PageResponseDriverDto.fromJson(value);
        case 'PageTransportOrder':
          return PageTransportOrder.fromJson(value);
        case 'PageTransportOrderDto':
          return PageTransportOrderDto.fromJson(value);
        case 'PageVehicleDto':
          return PageVehicleDto.fromJson(value);
        case 'PageWorkOrderDto':
          return PageWorkOrderDto.fromJson(value);
        case 'Pageable':
          return Pageable.fromJson(value);
        case 'Pageablenull':
          return Pageablenull.fromJson(value);
        case 'PartialDispatchDto':
          return PartialDispatchDto.fromJson(value);
        case 'PartnerAdmin':
          return PartnerAdmin.fromJson(value);
        case 'PartnerCompany':
          return PartnerCompany.fromJson(value);
        case 'PartsMasterDto':
          return PartsMasterDto.fromJson(value);
        case 'Permission':
          return Permission.fromJson(value);
        case 'PresenceHeartbeatDto':
          return PresenceHeartbeatDto.fromJson(value);
        case 'RegisterDriverRequest':
          return RegisterDriverRequest.fromJson(value);
        case 'RegisterRequest':
          return RegisterRequest.fromJson(value);
        case 'ResetPasswordRequest':
          return ResetPasswordRequest.fromJson(value);
        case 'Role':
          return Role.fromJson(value);
        case 'SettingBulkWriteRequest':
          return SettingBulkWriteRequest.fromJson(value);
        case 'SettingReadResponse':
          return SettingReadResponse.fromJson(value);
        case 'SettingWriteRequest':
          return SettingWriteRequest.fromJson(value);
        case 'Shipment':
          return Shipment.fromJson(value);
        case 'Sortnull':
          return Sortnull.fromJson(value);
        case 'SubmitIssueRequest':
          return SubmitIssueRequest.fromJson(value);
        case 'TopDriverDto':
          return TopDriverDto.fromJson(value);
        case 'TransportOrder':
          return TransportOrder.fromJson(value);
        case 'TransportOrderDto':
          return TransportOrderDto.fromJson(value);
        case 'TripPrePlanDto':
          return TripPrePlanDto.fromJson(value);
        case 'TripPrePlanRequest':
          return TripPrePlanRequest.fromJson(value);
        case 'TripPrePlanResponseDto':
          return TripPrePlanResponseDto.fromJson(value);
        case 'UnloadDetail':
          return UnloadDetail.fromJson(value);
        case 'UnloadProof':
          return UnloadProof.fromJson(value);
        case 'UnloadProofDto':
          return UnloadProofDto.fromJson(value);
        case 'UpdateDocumentFileRequest':
          return UpdateDocumentFileRequest.fromJson(value);
        case 'UpdateIssueRequest':
          return UpdateIssueRequest.fromJson(value);
        case 'UpdatePermissionRequest':
          return UpdatePermissionRequest.fromJson(value);
        case 'UpdatePermissionsRequest':
          return UpdatePermissionsRequest.fromJson(value);
        case 'UpdateStatusRequest':
          return UpdateStatusRequest.fromJson(value);
        case 'UpdateTransportOrderDto':
          return UpdateTransportOrderDto.fromJson(value);
        case 'User':
          return User.fromJson(value);
        case 'UserDto':
          return UserDto.fromJson(value);
        case 'UserPermissionSummaryDto':
          return UserPermissionSummaryDto.fromJson(value);
        case 'UserSetting':
          return UserSetting.fromJson(value);
        case 'UserSimpleDto':
          return UserSimpleDto.fromJson(value);
        case 'Vehicle':
          return Vehicle.fromJson(value);
        case 'VehicleDto':
          return VehicleDto.fromJson(value);
        case 'VehicleStatisticsDto':
          return VehicleStatisticsDto.fromJson(value);
        case 'VehicleWithDriverDto':
          return VehicleWithDriverDto.fromJson(value);
        case 'WorkOrderDto':
          return WorkOrderDto.fromJson(value);
        case 'WorkOrderPartDto':
          return WorkOrderPartDto.fromJson(value);
        case 'WorkOrderPhotoDto':
          return WorkOrderPhotoDto.fromJson(value);
        case 'WorkOrderTaskDto':
          return WorkOrderTaskDto.fromJson(value);
        default:
          dynamic match;
          if (value is List && (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toList(growable: growable);
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
              .map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,))
              .toSet();
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(v, match, growable: growable,)),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(HttpStatus.internalServerError, 'Exception during deserialization.', error, trace,);
    }
    throw ApiException(HttpStatus.internalServerError, 'Could not find a suitable class for deserialization',);
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
    ? message.json
    : ApiClient.fromJson(
        json.decode(message.json),
        targetType,
        growable: message.growable,
      );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async => value == null ? '' : json.encode(value);
