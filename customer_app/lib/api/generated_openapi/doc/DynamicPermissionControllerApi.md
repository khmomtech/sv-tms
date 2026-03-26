# openapi.api.DynamicPermissionControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**checkPermissionExists**](DynamicPermissionControllerApi.md#checkpermissionexists) | **GET** /api/admin/dynamic-permissions/exists/{name} | 
[**clearCache**](DynamicPermissionControllerApi.md#clearcache) | **POST** /api/admin/dynamic-permissions/clear-cache | 
[**createPermission1**](DynamicPermissionControllerApi.md#createpermission1) | **POST** /api/admin/dynamic-permissions | 
[**deletePermission1**](DynamicPermissionControllerApi.md#deletepermission1) | **DELETE** /api/admin/dynamic-permissions/{id} | 
[**getAllPermissionNames**](DynamicPermissionControllerApi.md#getallpermissionnames) | **GET** /api/admin/dynamic-permissions/names | 
[**getPermissionsByResource**](DynamicPermissionControllerApi.md#getpermissionsbyresource) | **GET** /api/admin/dynamic-permissions/by-resource/{resourceType} | 
[**updatePermission1**](DynamicPermissionControllerApi.md#updatepermission1) | **PUT** /api/admin/dynamic-permissions/{id} | 


# **checkPermissionExists**
> ApiResponseMapStringBoolean checkPermissionExists(name)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DynamicPermissionControllerApi();
final name = name_example; // String | 

try {
    final result = api_instance.checkPermissionExists(name);
    print(result);
} catch (e) {
    print('Exception when calling DynamicPermissionControllerApi->checkPermissionExists: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**|  | 

### Return type

[**ApiResponseMapStringBoolean**](ApiResponseMapStringBoolean.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **clearCache**
> ApiResponseString clearCache()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DynamicPermissionControllerApi();

try {
    final result = api_instance.clearCache();
    print(result);
} catch (e) {
    print('Exception when calling DynamicPermissionControllerApi->clearCache: $e\n');
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

# **createPermission1**
> ApiResponsePermission createPermission1(createPermissionRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DynamicPermissionControllerApi();
final createPermissionRequest = CreatePermissionRequest(); // CreatePermissionRequest | 

try {
    final result = api_instance.createPermission1(createPermissionRequest);
    print(result);
} catch (e) {
    print('Exception when calling DynamicPermissionControllerApi->createPermission1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createPermissionRequest** | [**CreatePermissionRequest**](CreatePermissionRequest.md)|  | 

### Return type

[**ApiResponsePermission**](ApiResponsePermission.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePermission1**
> ApiResponseString deletePermission1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DynamicPermissionControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deletePermission1(id);
    print(result);
} catch (e) {
    print('Exception when calling DynamicPermissionControllerApi->deletePermission1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllPermissionNames**
> ApiResponseSetString getAllPermissionNames()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DynamicPermissionControllerApi();

try {
    final result = api_instance.getAllPermissionNames();
    print(result);
} catch (e) {
    print('Exception when calling DynamicPermissionControllerApi->getAllPermissionNames: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseSetString**](ApiResponseSetString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPermissionsByResource**
> ApiResponseListPermission getPermissionsByResource(resourceType)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DynamicPermissionControllerApi();
final resourceType = resourceType_example; // String | 

try {
    final result = api_instance.getPermissionsByResource(resourceType);
    print(result);
} catch (e) {
    print('Exception when calling DynamicPermissionControllerApi->getPermissionsByResource: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resourceType** | **String**|  | 

### Return type

[**ApiResponseListPermission**](ApiResponseListPermission.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePermission1**
> ApiResponsePermission updatePermission1(id, updatePermissionRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DynamicPermissionControllerApi();
final id = 789; // int | 
final updatePermissionRequest = UpdatePermissionRequest(); // UpdatePermissionRequest | 

try {
    final result = api_instance.updatePermission1(id, updatePermissionRequest);
    print(result);
} catch (e) {
    print('Exception when calling DynamicPermissionControllerApi->updatePermission1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **updatePermissionRequest** | [**UpdatePermissionRequest**](UpdatePermissionRequest.md)|  | 

### Return type

[**ApiResponsePermission**](ApiResponsePermission.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

