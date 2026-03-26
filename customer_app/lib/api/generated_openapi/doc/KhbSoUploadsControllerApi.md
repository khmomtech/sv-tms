# openapi.api.KhbSoUploadsControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**commit**](KhbSoUploadsControllerApi.md#commit) | **POST** /api/khb-so-uploads/commit | 
[**downloadFinalSummaryExcel**](KhbSoUploadsControllerApi.md#downloadfinalsummaryexcel) | **GET** /api/khb-so-uploads/khb/final-summary/excel | 
[**exportTripPlan**](KhbSoUploadsControllerApi.md#exporttripplan) | **GET** /api/khb-so-uploads/plan-trip/export | 
[**getFinalSummaryJson**](KhbSoUploadsControllerApi.md#getfinalsummaryjson) | **GET** /api/khb-so-uploads/report/final-summary | 
[**getPrePlanSummary**](KhbSoUploadsControllerApi.md#getpreplansummary) | **GET** /api/khb-so-uploads/pre-plan/summary | 
[**getPreviewTrips**](KhbSoUploadsControllerApi.md#getpreviewtrips) | **GET** /api/khb-so-uploads/plan-trip/temp | 
[**planTrip2**](KhbSoUploadsControllerApi.md#plantrip2) | **GET** /api/khb-so-uploads/plan-trip | 
[**preview**](KhbSoUploadsControllerApi.md#preview) | **POST** /api/khb-so-uploads/preview | 
[**savePrePlan**](KhbSoUploadsControllerApi.md#savepreplan) | **POST** /api/khb-so-uploads/pre-plan/summary | 
[**savePreviewTrips**](KhbSoUploadsControllerApi.md#savepreviewtrips) | **POST** /api/khb-so-uploads/plan-trip/preview | 
[**uploadSOFile**](KhbSoUploadsControllerApi.md#uploadsofile) | **POST** /api/khb-so-uploads/upload | 


# **commit**
> Map<String, Object> commit(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.commit(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->commit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, Object>**](Object.md)|  | 

### Return type

**Map<String, Object>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **downloadFinalSummaryExcel**
> String downloadFinalSummaryExcel(date, zone)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final date = 2013-10-20; // DateTime | 
final zone = zone_example; // String | 

try {
    final result = api_instance.downloadFinalSummaryExcel(date, zone);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->downloadFinalSummaryExcel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **date** | **DateTime**|  | 
 **zone** | **String**|  | [optional] 

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **exportTripPlan**
> String exportTripPlan(uploadDate, zone, distributorCode)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final uploadDate = uploadDate_example; // String | 
final zone = zone_example; // String | 
final distributorCode = distributorCode_example; // String | 

try {
    final result = api_instance.exportTripPlan(uploadDate, zone, distributorCode);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->exportTripPlan: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uploadDate** | **String**|  | 
 **zone** | **String**|  | [optional] 
 **distributorCode** | **String**|  | [optional] 

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFinalSummaryJson**
> List<FinalSummaryRow> getFinalSummaryJson(uploadDate, zone)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final uploadDate = uploadDate_example; // String | 
final zone = zone_example; // String | 

try {
    final result = api_instance.getFinalSummaryJson(uploadDate, zone);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->getFinalSummaryJson: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uploadDate** | **String**|  | 
 **zone** | **String**|  | [optional] 

### Return type

[**List<FinalSummaryRow>**](FinalSummaryRow.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPrePlanSummary**
> List<TripPrePlanResponseDto> getPrePlanSummary(uploadDate, zone)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final uploadDate = uploadDate_example; // String | 
final zone = zone_example; // String | 

try {
    final result = api_instance.getPrePlanSummary(uploadDate, zone);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->getPrePlanSummary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uploadDate** | **String**|  | 
 **zone** | **String**|  | [optional] 

### Return type

[**List<TripPrePlanResponseDto>**](TripPrePlanResponseDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPreviewTrips**
> List<KhbTempTrip> getPreviewTrips(uploadDate, zone)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final uploadDate = 2013-10-20; // DateTime | 
final zone = zone_example; // String | 

try {
    final result = api_instance.getPreviewTrips(uploadDate, zone);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->getPreviewTrips: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uploadDate** | **DateTime**|  | 
 **zone** | **String**|  | [optional] 

### Return type

[**List<KhbTempTrip>**](KhbTempTrip.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **planTrip2**
> Object planTrip2(uploadDate, zone, distributorCode, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final uploadDate = uploadDate_example; // String | 
final zone = zone_example; // String | 
final distributorCode = distributorCode_example; // String | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.planTrip2(uploadDate, zone, distributorCode, page, size);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->planTrip2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **uploadDate** | **String**|  | 
 **zone** | **String**|  | [optional] 
 **distributorCode** | **String**|  | [optional] 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 20]

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **preview**
> Map<String, Object> preview(updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.preview(updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->preview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateDocumentFileRequest** | [**UpdateDocumentFileRequest**](UpdateDocumentFileRequest.md)|  | [optional] 

### Return type

**Map<String, Object>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **savePrePlan**
> Object savePrePlan(tripPrePlanRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final tripPrePlanRequest = TripPrePlanRequest(); // TripPrePlanRequest | 

try {
    final result = api_instance.savePrePlan(tripPrePlanRequest);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->savePrePlan: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **tripPrePlanRequest** | [**TripPrePlanRequest**](TripPrePlanRequest.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **savePreviewTrips**
> Object savePreviewTrips(khbTempTrip)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final khbTempTrip = [List<KhbTempTrip>()]; // List<KhbTempTrip> | 

try {
    final result = api_instance.savePreviewTrips(khbTempTrip);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->savePreviewTrips: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **khbTempTrip** | [**List<KhbTempTrip>**](KhbTempTrip.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadSOFile**
> Object uploadSOFile(updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadsControllerApi();
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.uploadSOFile(updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadsControllerApi->uploadSOFile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateDocumentFileRequest** | [**UpdateDocumentFileRequest**](UpdateDocumentFileRequest.md)|  | [optional] 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

