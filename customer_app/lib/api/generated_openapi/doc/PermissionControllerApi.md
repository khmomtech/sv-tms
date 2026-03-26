# openapi.api.PermissionControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createPermission**](PermissionControllerApi.md#createpermission) | **POST** /api/admin/permissions | 
[**deletePermission**](PermissionControllerApi.md#deletepermission) | **DELETE** /api/admin/permissions/{id} | 
[**getAllPermissions**](PermissionControllerApi.md#getallpermissions) | **GET** /api/admin/permissions | 
[**getPermissionById**](PermissionControllerApi.md#getpermissionbyid) | **GET** /api/admin/permissions/{id} | 
[**updatePermission**](PermissionControllerApi.md#updatepermission) | **PUT** /api/admin/permissions/{id} | 


# **createPermission**
> Permission createPermission(permission)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PermissionControllerApi();
final permission = Permission(); // Permission | 

try {
    final result = api_instance.createPermission(permission);
    print(result);
} catch (e) {
    print('Exception when calling PermissionControllerApi->createPermission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **permission** | [**Permission**](Permission.md)|  | 

### Return type

[**Permission**](Permission.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePermission**
> deletePermission(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PermissionControllerApi();
final id = 789; // int | 

try {
    api_instance.deletePermission(id);
} catch (e) {
    print('Exception when calling PermissionControllerApi->deletePermission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllPermissions**
> List<Permission> getAllPermissions()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PermissionControllerApi();

try {
    final result = api_instance.getAllPermissions();
    print(result);
} catch (e) {
    print('Exception when calling PermissionControllerApi->getAllPermissions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Permission>**](Permission.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPermissionById**
> Permission getPermissionById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PermissionControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getPermissionById(id);
    print(result);
} catch (e) {
    print('Exception when calling PermissionControllerApi->getPermissionById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**Permission**](Permission.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePermission**
> Permission updatePermission(id, permission)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PermissionControllerApi();
final id = 789; // int | 
final permission = Permission(); // Permission | 

try {
    final result = api_instance.updatePermission(id, permission);
    print(result);
} catch (e) {
    print('Exception when calling PermissionControllerApi->updatePermission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **permission** | [**Permission**](Permission.md)|  | 

### Return type

[**Permission**](Permission.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

