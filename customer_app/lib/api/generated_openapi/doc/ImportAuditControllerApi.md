# openapi.api.ImportAuditControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**finish**](ImportAuditControllerApi.md#finish) | **POST** /api/admin/imports/finish | 
[**start**](ImportAuditControllerApi.md#start) | **POST** /api/admin/imports/start | 


# **finish**
> Object finish(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ImportAuditControllerApi();
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.finish(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling ImportAuditControllerApi->finish: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, Object>**](Object.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **start**
> Object start(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ImportAuditControllerApi();
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.start(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling ImportAuditControllerApi->start: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, Object>**](Object.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

