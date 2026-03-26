# openapi.api.KhbSoUploadControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**commit1**](KhbSoUploadControllerApi.md#commit1) | **POST** /api/khb-so-upload/commit | 
[**downloadFinalSummaryExcel1**](KhbSoUploadControllerApi.md#downloadfinalsummaryexcel1) | **GET** /api/khb-so-upload/khb/final-summary/excel | 
[**exportTripPlan1**](KhbSoUploadControllerApi.md#exporttripplan1) | **GET** /api/khb-so-upload/plan-trip/export | 
[**getFinalSummaryJson1**](KhbSoUploadControllerApi.md#getfinalsummaryjson1) | **GET** /api/khb-so-upload/report/final-summary | 
[**getPrePlanSummary1**](KhbSoUploadControllerApi.md#getpreplansummary1) | **GET** /api/khb-so-upload/pre-plan/summary | 
[**getPreviewTrips1**](KhbSoUploadControllerApi.md#getpreviewtrips1) | **GET** /api/khb-so-upload/plan-trip/temp | 
[**planTrip3**](KhbSoUploadControllerApi.md#plantrip3) | **GET** /api/khb-so-upload/plan-trip | 
[**preview1**](KhbSoUploadControllerApi.md#preview1) | **POST** /api/khb-so-upload/preview | 
[**savePrePlan1**](KhbSoUploadControllerApi.md#savepreplan1) | **POST** /api/khb-so-upload/pre-plan/summary | 
[**savePreviewTrips1**](KhbSoUploadControllerApi.md#savepreviewtrips1) | **POST** /api/khb-so-upload/plan-trip/preview | 
[**uploadSOFile1**](KhbSoUploadControllerApi.md#uploadsofile1) | **POST** /api/khb-so-upload/upload | 


# **commit1**
> Map<String, Object> commit1(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.commit1(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->commit1: $e\n');
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

# **downloadFinalSummaryExcel1**
> String downloadFinalSummaryExcel1(date, zone)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final date = 2013-10-20; // DateTime | 
final zone = zone_example; // String | 

try {
    final result = api_instance.downloadFinalSummaryExcel1(date, zone);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->downloadFinalSummaryExcel1: $e\n');
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

# **exportTripPlan1**
> String exportTripPlan1(uploadDate, zone, distributorCode)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final uploadDate = uploadDate_example; // String | 
final zone = zone_example; // String | 
final distributorCode = distributorCode_example; // String | 

try {
    final result = api_instance.exportTripPlan1(uploadDate, zone, distributorCode);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->exportTripPlan1: $e\n');
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

# **getFinalSummaryJson1**
> List<FinalSummaryRow> getFinalSummaryJson1(uploadDate, zone)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final uploadDate = uploadDate_example; // String | 
final zone = zone_example; // String | 

try {
    final result = api_instance.getFinalSummaryJson1(uploadDate, zone);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->getFinalSummaryJson1: $e\n');
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

# **getPrePlanSummary1**
> List<TripPrePlanResponseDto> getPrePlanSummary1(uploadDate, zone)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final uploadDate = uploadDate_example; // String | 
final zone = zone_example; // String | 

try {
    final result = api_instance.getPrePlanSummary1(uploadDate, zone);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->getPrePlanSummary1: $e\n');
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

# **getPreviewTrips1**
> List<KhbTempTrip> getPreviewTrips1(uploadDate, zone)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final uploadDate = 2013-10-20; // DateTime | 
final zone = zone_example; // String | 

try {
    final result = api_instance.getPreviewTrips1(uploadDate, zone);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->getPreviewTrips1: $e\n');
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

# **planTrip3**
> Object planTrip3(uploadDate, zone, distributorCode, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final uploadDate = uploadDate_example; // String | 
final zone = zone_example; // String | 
final distributorCode = distributorCode_example; // String | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.planTrip3(uploadDate, zone, distributorCode, page, size);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->planTrip3: $e\n');
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

# **preview1**
> Map<String, Object> preview1(updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.preview1(updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->preview1: $e\n');
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

# **savePrePlan1**
> Object savePrePlan1(tripPrePlanRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final tripPrePlanRequest = TripPrePlanRequest(); // TripPrePlanRequest | 

try {
    final result = api_instance.savePrePlan1(tripPrePlanRequest);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->savePrePlan1: $e\n');
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

# **savePreviewTrips1**
> Object savePreviewTrips1(khbTempTrip)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final khbTempTrip = [List<KhbTempTrip>()]; // List<KhbTempTrip> | 

try {
    final result = api_instance.savePreviewTrips1(khbTempTrip);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->savePreviewTrips1: $e\n');
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

# **uploadSOFile1**
> Object uploadSOFile1(updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = KhbSoUploadControllerApi();
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.uploadSOFile1(updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling KhbSoUploadControllerApi->uploadSOFile1: $e\n');
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

