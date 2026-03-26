# openapi.api.DriverAttendanceControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**bulkPermission**](DriverAttendanceControllerApi.md#bulkpermission) | **POST** /api/admin/drivers/{driverId}/attendance/permission-range | 
[**create2**](DriverAttendanceControllerApi.md#create2) | **POST** /api/admin/drivers/{driverId}/attendance | 
[**delete2**](DriverAttendanceControllerApi.md#delete2) | **DELETE** /api/admin/drivers/attendance/{id} | 
[**getByDate**](DriverAttendanceControllerApi.md#getbydate) | **GET** /api/admin/drivers/{driverId}/attendance/date/{date} | 
[**list**](DriverAttendanceControllerApi.md#list) | **GET** /api/admin/drivers/{driverId}/attendance | 
[**listAll**](DriverAttendanceControllerApi.md#listall) | **GET** /api/admin/drivers/attendance | 
[**summary**](DriverAttendanceControllerApi.md#summary) | **GET** /api/admin/drivers/{driverId}/attendance/summary | 
[**update2**](DriverAttendanceControllerApi.md#update2) | **PUT** /api/admin/drivers/attendance/{id} | 


# **bulkPermission**
> ApiResponseListAttendanceDto bulkPermission(driverId, bulkPermissionRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAttendanceControllerApi();
final driverId = 789; // int | 
final bulkPermissionRequest = BulkPermissionRequest(); // BulkPermissionRequest | 

try {
    final result = api_instance.bulkPermission(driverId, bulkPermissionRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverAttendanceControllerApi->bulkPermission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **bulkPermissionRequest** | [**BulkPermissionRequest**](BulkPermissionRequest.md)|  | 

### Return type

[**ApiResponseListAttendanceDto**](ApiResponseListAttendanceDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create2**
> ApiResponseAttendanceDto create2(driverId, attendanceRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAttendanceControllerApi();
final driverId = 789; // int | 
final attendanceRequest = AttendanceRequest(); // AttendanceRequest | 

try {
    final result = api_instance.create2(driverId, attendanceRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverAttendanceControllerApi->create2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **attendanceRequest** | [**AttendanceRequest**](AttendanceRequest.md)|  | 

### Return type

[**ApiResponseAttendanceDto**](ApiResponseAttendanceDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete2**
> ApiResponseString delete2(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAttendanceControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.delete2(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverAttendanceControllerApi->delete2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getByDate**
> ApiResponseAttendanceDto getByDate(driverId, date)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAttendanceControllerApi();
final driverId = 789; // int | 
final date = date_example; // String | 

try {
    final result = api_instance.getByDate(driverId, date);
    print(result);
} catch (e) {
    print('Exception when calling DriverAttendanceControllerApi->getByDate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **date** | **String**|  | 

### Return type

[**ApiResponseAttendanceDto**](ApiResponseAttendanceDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list**
> ApiResponseListAttendanceDto list(driverId, year, month)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAttendanceControllerApi();
final driverId = 789; // int | 
final year = 56; // int | 
final month = 56; // int | 

try {
    final result = api_instance.list(driverId, year, month);
    print(result);
} catch (e) {
    print('Exception when calling DriverAttendanceControllerApi->list: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **year** | **int**|  | 
 **month** | **int**|  | 

### Return type

[**ApiResponseListAttendanceDto**](ApiResponseListAttendanceDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAll**
> ApiResponsePageResponseAttendanceDto listAll(year, month, driverId, permissionOnly, fromDate, toDate, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAttendanceControllerApi();
final year = 56; // int | 
final month = 56; // int | 
final driverId = 789; // int | 
final permissionOnly = true; // bool | 
final fromDate = fromDate_example; // String | 
final toDate = toDate_example; // String | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.listAll(year, month, driverId, permissionOnly, fromDate, toDate, page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverAttendanceControllerApi->listAll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **year** | **int**|  | [optional] 
 **month** | **int**|  | [optional] 
 **driverId** | **int**|  | [optional] 
 **permissionOnly** | **bool**|  | [optional] [default to true]
 **fromDate** | **String**|  | [optional] 
 **toDate** | **String**|  | [optional] 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 20]

### Return type

[**ApiResponsePageResponseAttendanceDto**](ApiResponsePageResponseAttendanceDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **summary**
> ApiResponseAttendanceSummaryDto summary(driverId, year, month)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAttendanceControllerApi();
final driverId = 789; // int | 
final year = 56; // int | 
final month = 56; // int | 

try {
    final result = api_instance.summary(driverId, year, month);
    print(result);
} catch (e) {
    print('Exception when calling DriverAttendanceControllerApi->summary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **year** | **int**|  | 
 **month** | **int**|  | 

### Return type

[**ApiResponseAttendanceSummaryDto**](ApiResponseAttendanceSummaryDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **update2**
> ApiResponseAttendanceDto update2(id, attendanceRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAttendanceControllerApi();
final id = 789; // int | 
final attendanceRequest = AttendanceRequest(); // AttendanceRequest | 

try {
    final result = api_instance.update2(id, attendanceRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverAttendanceControllerApi->update2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **attendanceRequest** | [**AttendanceRequest**](AttendanceRequest.md)|  | 

### Return type

[**ApiResponseAttendanceDto**](ApiResponseAttendanceDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

