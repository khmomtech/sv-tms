# openapi.api.DashboardControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getCacheStats**](DashboardControllerApi.md#getcachestats) | **GET** /api/admin/dashboard/cache-stats | 
[**getDashboardSummary**](DashboardControllerApi.md#getdashboardsummary) | **GET** /api/admin/dashboard/summary | 
[**getLiveDriversCachedOnly**](DashboardControllerApi.md#getlivedriverscachedonly) | **GET** /api/admin/dashboard/live-drivers-cached | 
[**getSummaryStatsOnly**](DashboardControllerApi.md#getsummarystatsonly) | **GET** /api/admin/dashboard/summary-stats | 
[**getTopDrivers**](DashboardControllerApi.md#gettopdrivers) | **GET** /api/admin/dashboard/top-drivers | 


# **getCacheStats**
> ApiResponseMapStringObject getCacheStats()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DashboardControllerApi();

try {
    final result = api_instance.getCacheStats();
    print(result);
} catch (e) {
    print('Exception when calling DashboardControllerApi->getCacheStats: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDashboardSummary**
> ApiResponseDashboardSummaryResponse getDashboardSummary(fromDate, toDate)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DashboardControllerApi();
final fromDate = 2013-10-20; // DateTime | 
final toDate = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getDashboardSummary(fromDate, toDate);
    print(result);
} catch (e) {
    print('Exception when calling DashboardControllerApi->getDashboardSummary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **fromDate** | **DateTime**|  | [optional] 
 **toDate** | **DateTime**|  | [optional] 

### Return type

[**ApiResponseDashboardSummaryResponse**](ApiResponseDashboardSummaryResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLiveDriversCachedOnly**
> ApiResponseListDriverDto getLiveDriversCachedOnly()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DashboardControllerApi();

try {
    final result = api_instance.getLiveDriversCachedOnly();
    print(result);
} catch (e) {
    print('Exception when calling DashboardControllerApi->getLiveDriversCachedOnly: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListDriverDto**](ApiResponseListDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSummaryStatsOnly**
> ApiResponseListLoadingSummaryRowDto getSummaryStatsOnly(fromDate, toDate, customerName, truckType)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DashboardControllerApi();
final fromDate = 2013-10-20; // DateTime | 
final toDate = 2013-10-20; // DateTime | 
final customerName = customerName_example; // String | 
final truckType = truckType_example; // String | 

try {
    final result = api_instance.getSummaryStatsOnly(fromDate, toDate, customerName, truckType);
    print(result);
} catch (e) {
    print('Exception when calling DashboardControllerApi->getSummaryStatsOnly: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **fromDate** | **DateTime**|  | [optional] 
 **toDate** | **DateTime**|  | [optional] 
 **customerName** | **String**|  | [optional] 
 **truckType** | **String**|  | [optional] 

### Return type

[**ApiResponseListLoadingSummaryRowDto**](ApiResponseListLoadingSummaryRowDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTopDrivers**
> ApiResponseListTopDriverDto getTopDrivers()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DashboardControllerApi();

try {
    final result = api_instance.getTopDrivers();
    print(result);
} catch (e) {
    print('Exception when calling DashboardControllerApi->getTopDrivers: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListTopDriverDto**](ApiResponseListTopDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

