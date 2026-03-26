# openapi.api.SystemInitializationControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getSystemStatus**](SystemInitializationControllerApi.md#getsystemstatus) | **GET** /api/admin/system/status | 
[**initializePermissions**](SystemInitializationControllerApi.md#initializepermissions) | **POST** /api/admin/system/initialize/permissions | 
[**initializeRoles**](SystemInitializationControllerApi.md#initializeroles) | **POST** /api/admin/system/initialize/roles | 
[**initializeSystem**](SystemInitializationControllerApi.md#initializesystem) | **POST** /api/admin/system/initialize | 
[**initializeUsers**](SystemInitializationControllerApi.md#initializeusers) | **POST** /api/admin/system/initialize/users | 


# **getSystemStatus**
> ApiResponseMapStringObject getSystemStatus()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SystemInitializationControllerApi();

try {
    final result = api_instance.getSystemStatus();
    print(result);
} catch (e) {
    print('Exception when calling SystemInitializationControllerApi->getSystemStatus: $e\n');
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

# **initializePermissions**
> ApiResponseString initializePermissions()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SystemInitializationControllerApi();

try {
    final result = api_instance.initializePermissions();
    print(result);
} catch (e) {
    print('Exception when calling SystemInitializationControllerApi->initializePermissions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **initializeRoles**
> ApiResponseString initializeRoles()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SystemInitializationControllerApi();

try {
    final result = api_instance.initializeRoles();
    print(result);
} catch (e) {
    print('Exception when calling SystemInitializationControllerApi->initializeRoles: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **initializeSystem**
> ApiResponseString initializeSystem()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SystemInitializationControllerApi();

try {
    final result = api_instance.initializeSystem();
    print(result);
} catch (e) {
    print('Exception when calling SystemInitializationControllerApi->initializeSystem: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **initializeUsers**
> ApiResponseString initializeUsers()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SystemInitializationControllerApi();

try {
    final result = api_instance.initializeUsers();
    print(result);
} catch (e) {
    print('Exception when calling SystemInitializationControllerApi->initializeUsers: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

