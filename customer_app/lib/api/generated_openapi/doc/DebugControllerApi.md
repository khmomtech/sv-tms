# openapi.api.DebugControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**findUserDebug**](DebugControllerApi.md#finduserdebug) | **GET** /api/debug/finduser/{username} | 
[**myPermissions**](DebugControllerApi.md#mypermissions) | **GET** /api/debug/permissions | 
[**whoami**](DebugControllerApi.md#whoami) | **GET** /api/debug/whoami | 


# **findUserDebug**
> Map<String, Object> findUserDebug(username)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DebugControllerApi();
final username = username_example; // String | 

try {
    final result = api_instance.findUserDebug(username);
    print(result);
} catch (e) {
    print('Exception when calling DebugControllerApi->findUserDebug: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **username** | **String**|  | 

### Return type

**Map<String, Object>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **myPermissions**
> ApiResponseMapStringObject myPermissions()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DebugControllerApi();

try {
    final result = api_instance.myPermissions();
    print(result);
} catch (e) {
    print('Exception when calling DebugControllerApi->myPermissions: $e\n');
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

# **whoami**
> ApiResponseMapStringObject whoami()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DebugControllerApi();

try {
    final result = api_instance.whoami();
    print(result);
} catch (e) {
    print('Exception when calling DebugControllerApi->whoami: $e\n');
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

