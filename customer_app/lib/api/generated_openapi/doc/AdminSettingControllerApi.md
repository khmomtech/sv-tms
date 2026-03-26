# openapi.api.AdminSettingControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**bulk**](AdminSettingControllerApi.md#bulk) | **POST** /api/admin/settings/bulk | 
[**getValue**](AdminSettingControllerApi.md#getvalue) | **GET** /api/admin/settings/value | 
[**importJson**](AdminSettingControllerApi.md#importjson) | **POST** /api/admin/settings/import | 
[**listValues**](AdminSettingControllerApi.md#listvalues) | **GET** /api/admin/settings/values | 
[**upsert**](AdminSettingControllerApi.md#upsert) | **POST** /api/admin/settings/value | 


# **bulk**
> List<SettingReadResponse> bulk(settingBulkWriteRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AdminSettingControllerApi();
final settingBulkWriteRequest = SettingBulkWriteRequest(); // SettingBulkWriteRequest | 

try {
    final result = api_instance.bulk(settingBulkWriteRequest);
    print(result);
} catch (e) {
    print('Exception when calling AdminSettingControllerApi->bulk: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **settingBulkWriteRequest** | [**SettingBulkWriteRequest**](SettingBulkWriteRequest.md)|  | 

### Return type

[**List<SettingReadResponse>**](SettingReadResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getValue**
> Object getValue(groupCode, keyCode, scope, scopeRef)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AdminSettingControllerApi();
final groupCode = groupCode_example; // String | 
final keyCode = keyCode_example; // String | 
final scope = scope_example; // String | 
final scopeRef = scopeRef_example; // String | 

try {
    final result = api_instance.getValue(groupCode, keyCode, scope, scopeRef);
    print(result);
} catch (e) {
    print('Exception when calling AdminSettingControllerApi->getValue: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupCode** | **String**|  | 
 **keyCode** | **String**|  | 
 **scope** | **String**|  | [optional] [default to 'GLOBAL']
 **scopeRef** | **String**|  | [optional] 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **importJson**
> List<SettingWriteRequest> importJson(body, scope, scopeRef, apply)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AdminSettingControllerApi();
final body = String(); // String | 
final scope = scope_example; // String | 
final scopeRef = scopeRef_example; // String | 
final apply = true; // bool | 

try {
    final result = api_instance.importJson(body, scope, scopeRef, apply);
    print(result);
} catch (e) {
    print('Exception when calling AdminSettingControllerApi->importJson: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **body** | **String**|  | 
 **scope** | **String**|  | [optional] [default to 'GLOBAL']
 **scopeRef** | **String**|  | [optional] 
 **apply** | **bool**|  | [optional] [default to false]

### Return type

[**List<SettingWriteRequest>**](SettingWriteRequest.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/octet-stream
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listValues**
> List<SettingReadResponse> listValues(groupCode, scope, scopeRef, includeSecrets)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AdminSettingControllerApi();
final groupCode = groupCode_example; // String | 
final scope = scope_example; // String | 
final scopeRef = scopeRef_example; // String | 
final includeSecrets = true; // bool | 

try {
    final result = api_instance.listValues(groupCode, scope, scopeRef, includeSecrets);
    print(result);
} catch (e) {
    print('Exception when calling AdminSettingControllerApi->listValues: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **groupCode** | **String**|  | 
 **scope** | **String**|  | [optional] [default to 'GLOBAL']
 **scopeRef** | **String**|  | [optional] 
 **includeSecrets** | **bool**|  | [optional] [default to false]

### Return type

[**List<SettingReadResponse>**](SettingReadResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **upsert**
> SettingReadResponse upsert(settingWriteRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AdminSettingControllerApi();
final settingWriteRequest = SettingWriteRequest(); // SettingWriteRequest | 

try {
    final result = api_instance.upsert(settingWriteRequest);
    print(result);
} catch (e) {
    print('Exception when calling AdminSettingControllerApi->upsert: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **settingWriteRequest** | [**SettingWriteRequest**](SettingWriteRequest.md)|  | 

### Return type

[**SettingReadResponse**](SettingReadResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

