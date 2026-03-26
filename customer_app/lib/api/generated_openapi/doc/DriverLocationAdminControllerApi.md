# openapi.api.DriverLocationAdminControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getDriverLocationHistory1**](DriverLocationAdminControllerApi.md#getdriverlocationhistory1) | **GET** /api/admin/drivers/{id}/location-history | 
[**getDriverLocationHistoryPaginated1**](DriverLocationAdminControllerApi.md#getdriverlocationhistorypaginated1) | **GET** /api/admin/drivers/{driverId}/location-history/paginated | 
[**latestForDriver1**](DriverLocationAdminControllerApi.md#latestfordriver1) | **GET** /api/admin/drivers/{driverId}/latest-location | 
[**liveDrivers1**](DriverLocationAdminControllerApi.md#livedrivers1) | **GET** /api/admin/drivers/live-drivers | 


# **getDriverLocationHistory1**
> ApiResponseListLocationHistoryDto getDriverLocationHistory1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLocationAdminControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDriverLocationHistory1(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverLocationAdminControllerApi->getDriverLocationHistory1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseListLocationHistoryDto**](ApiResponseListLocationHistoryDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDriverLocationHistoryPaginated1**
> ApiResponsePageLocationHistoryDto getDriverLocationHistoryPaginated1(driverId, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLocationAdminControllerApi();
final driverId = 789; // int | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getDriverLocationHistoryPaginated1(driverId, page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverLocationAdminControllerApi->getDriverLocationHistoryPaginated1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 20]

### Return type

[**ApiResponsePageLocationHistoryDto**](ApiResponsePageLocationHistoryDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **latestForDriver1**
> ApiResponseLiveDriverDto latestForDriver1(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLocationAdminControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.latestForDriver1(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverLocationAdminControllerApi->latestForDriver1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseLiveDriverDto**](ApiResponseLiveDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **liveDrivers1**
> ApiResponseListLiveDriverDto liveDrivers1(onlyOnline, onlineSeconds, south, west, north, east)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLocationAdminControllerApi();
final onlyOnline = true; // bool | 
final onlineSeconds = 56; // int | 
final south = 1.2; // double | 
final west = 1.2; // double | 
final north = 1.2; // double | 
final east = 1.2; // double | 

try {
    final result = api_instance.liveDrivers1(onlyOnline, onlineSeconds, south, west, north, east);
    print(result);
} catch (e) {
    print('Exception when calling DriverLocationAdminControllerApi->liveDrivers1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **onlyOnline** | **bool**|  | [optional] [default to true]
 **onlineSeconds** | **int**|  | [optional] [default to 120]
 **south** | **double**|  | [optional] 
 **west** | **double**|  | [optional] 
 **north** | **double**|  | [optional] 
 **east** | **double**|  | [optional] 

### Return type

[**ApiResponseListLiveDriverDto**](ApiResponseListLiveDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

