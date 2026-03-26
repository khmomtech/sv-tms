# openapi.api.ReportsControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**dispatchDay**](ReportsControllerApi.md#dispatchday) | **GET** /api/admin/reports/dispatch/day | 
[**exportCsv**](ReportsControllerApi.md#exportcsv) | **GET** /api/admin/reports/dispatch/day/export | 
[**exportExcel**](ReportsControllerApi.md#exportexcel) | **GET** /api/admin/reports/dispatch/day/export.xlsx | 


# **dispatchDay**
> List<DispatchDayReportRow> dispatchDay(planFrom, planTo, fromTime, toTime, toExtraDays)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ReportsControllerApi();
final planFrom = 2013-10-20; // DateTime | 
final planTo = 2013-10-20; // DateTime | 
final fromTime = fromTime_example; // String | 
final toTime = toTime_example; // String | 
final toExtraDays = 56; // int | 

try {
    final result = api_instance.dispatchDay(planFrom, planTo, fromTime, toTime, toExtraDays);
    print(result);
} catch (e) {
    print('Exception when calling ReportsControllerApi->dispatchDay: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **planFrom** | **DateTime**|  | 
 **planTo** | **DateTime**|  | 
 **fromTime** | **String**|  | [optional] 
 **toTime** | **String**|  | [optional] 
 **toExtraDays** | **int**|  | [optional] 

### Return type

[**List<DispatchDayReportRow>**](DispatchDayReportRow.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **exportCsv**
> exportCsv(planFrom, planTo, fromTime, toTime, toExtraDays)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ReportsControllerApi();
final planFrom = 2013-10-20; // DateTime | 
final planTo = 2013-10-20; // DateTime | 
final fromTime = fromTime_example; // String | 
final toTime = toTime_example; // String | 
final toExtraDays = 56; // int | 

try {
    api_instance.exportCsv(planFrom, planTo, fromTime, toTime, toExtraDays);
} catch (e) {
    print('Exception when calling ReportsControllerApi->exportCsv: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **planFrom** | **DateTime**|  | 
 **planTo** | **DateTime**|  | 
 **fromTime** | **String**|  | [optional] 
 **toTime** | **String**|  | [optional] 
 **toExtraDays** | **int**|  | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **exportExcel**
> exportExcel(planFrom, planTo, fromTime, toTime, toExtraDays)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ReportsControllerApi();
final planFrom = 2013-10-20; // DateTime | 
final planTo = 2013-10-20; // DateTime | 
final fromTime = fromTime_example; // String | 
final toTime = toTime_example; // String | 
final toExtraDays = 56; // int | 

try {
    api_instance.exportExcel(planFrom, planTo, fromTime, toTime, toExtraDays);
} catch (e) {
    print('Exception when calling ReportsControllerApi->exportExcel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **planFrom** | **DateTime**|  | 
 **planTo** | **DateTime**|  | 
 **fromTime** | **String**|  | [optional] 
 **toTime** | **String**|  | [optional] 
 **toExtraDays** | **int**|  | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

