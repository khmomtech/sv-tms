# openapi.api.DriverIssueControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteIssue**](DriverIssueControllerApi.md#deleteissue) | **DELETE** /api/driver/issues/{id} | 
[**getById1**](DriverIssueControllerApi.md#getbyid1) | **GET** /api/driver/issues/{id} | 
[**getIssuesByDriverIdPaged**](DriverIssueControllerApi.md#getissuesbydriveridpaged) | **GET** /api/driver/issues/{driverId}/paged | 
[**getIssuesByDriverPaged**](DriverIssueControllerApi.md#getissuesbydriverpaged) | **GET** /api/driver/issues/paged | 
[**submitIssue**](DriverIssueControllerApi.md#submitissue) | **POST** /api/driver/issues | 
[**updateIssue**](DriverIssueControllerApi.md#updateissue) | **PUT** /api/driver/issues/{id} | 
[**updateStatus**](DriverIssueControllerApi.md#updatestatus) | **PATCH** /api/driver/issues/{id}/status | 


# **deleteIssue**
> ApiResponseVoid deleteIssue(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverIssueControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteIssue(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverIssueControllerApi->deleteIssue: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseVoid**](ApiResponseVoid.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getById1**
> ApiResponseDriverIssueDto getById1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverIssueControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getById1(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverIssueControllerApi->getById1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseDriverIssueDto**](ApiResponseDriverIssueDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getIssuesByDriverIdPaged**
> ApiResponsePageDriverIssueDto getIssuesByDriverIdPaged(driverId, pageable, status, type, fromDate, toDate)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverIssueControllerApi();
final driverId = 789; // int | 
final pageable = ; // Pageable | 
final status = status_example; // String | 
final type = type_example; // String | 
final fromDate = 2013-10-20; // DateTime | 
final toDate = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getIssuesByDriverIdPaged(driverId, pageable, status, type, fromDate, toDate);
    print(result);
} catch (e) {
    print('Exception when calling DriverIssueControllerApi->getIssuesByDriverIdPaged: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **pageable** | [**Pageable**](.md)|  | 
 **status** | **String**|  | [optional] 
 **type** | **String**|  | [optional] 
 **fromDate** | **DateTime**|  | [optional] 
 **toDate** | **DateTime**|  | [optional] 

### Return type

[**ApiResponsePageDriverIssueDto**](ApiResponsePageDriverIssueDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getIssuesByDriverPaged**
> ApiResponsePageDriverIssueDto getIssuesByDriverPaged(pageable, status, type, fromDate, toDate)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverIssueControllerApi();
final pageable = ; // Pageable | 
final status = status_example; // String | 
final type = type_example; // String | 
final fromDate = 2013-10-20; // DateTime | 
final toDate = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getIssuesByDriverPaged(pageable, status, type, fromDate, toDate);
    print(result);
} catch (e) {
    print('Exception when calling DriverIssueControllerApi->getIssuesByDriverPaged: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 
 **status** | **String**|  | [optional] 
 **type** | **String**|  | [optional] 
 **fromDate** | **DateTime**|  | [optional] 
 **toDate** | **DateTime**|  | [optional] 

### Return type

[**ApiResponsePageDriverIssueDto**](ApiResponsePageDriverIssueDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitIssue**
> ApiResponseDriverIssueDto submitIssue(payload, images)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverIssueControllerApi();
final payload = ; // SubmitIssueRequest | 
final images = [/path/to/file.txt]; // List<MultipartFile> | 

try {
    final result = api_instance.submitIssue(payload, images);
    print(result);
} catch (e) {
    print('Exception when calling DriverIssueControllerApi->submitIssue: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **payload** | [**SubmitIssueRequest**](SubmitIssueRequest.md)|  | 
 **images** | [**List<MultipartFile>**](MultipartFile.md)|  | [optional] 

### Return type

[**ApiResponseDriverIssueDto**](ApiResponseDriverIssueDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateIssue**
> ApiResponseDriverIssueDto updateIssue(id, updateIssueRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverIssueControllerApi();
final id = 789; // int | 
final updateIssueRequest = UpdateIssueRequest(); // UpdateIssueRequest | 

try {
    final result = api_instance.updateIssue(id, updateIssueRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverIssueControllerApi->updateIssue: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **updateIssueRequest** | [**UpdateIssueRequest**](UpdateIssueRequest.md)|  | 

### Return type

[**ApiResponseDriverIssueDto**](ApiResponseDriverIssueDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateStatus**
> ApiResponseDriverIssueDto updateStatus(id, updateStatusRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverIssueControllerApi();
final id = 789; // int | 
final updateStatusRequest = UpdateStatusRequest(); // UpdateStatusRequest | 

try {
    final result = api_instance.updateStatus(id, updateStatusRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverIssueControllerApi->updateStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **updateStatusRequest** | [**UpdateStatusRequest**](UpdateStatusRequest.md)|  | 

### Return type

[**ApiResponseDriverIssueDto**](ApiResponseDriverIssueDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

