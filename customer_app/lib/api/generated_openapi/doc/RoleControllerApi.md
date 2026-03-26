# openapi.api.RoleControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addPermissionToRole**](RoleControllerApi.md#addpermissiontorole) | **POST** /api/admin/roles/{roleId}/permissions/{permissionId} | 
[**createRole**](RoleControllerApi.md#createrole) | **POST** /api/admin/roles | 
[**deleteRole**](RoleControllerApi.md#deleterole) | **DELETE** /api/admin/roles/{id} | 
[**getAllRoles**](RoleControllerApi.md#getallroles) | **GET** /api/admin/roles | 
[**getRoleById**](RoleControllerApi.md#getrolebyid) | **GET** /api/admin/roles/{id} | 
[**getRolePermissions**](RoleControllerApi.md#getrolepermissions) | **GET** /api/admin/roles/{roleId}/permissions | 
[**removePermissionFromRole**](RoleControllerApi.md#removepermissionfromrole) | **DELETE** /api/admin/roles/{roleId}/permissions/{permissionId} | 
[**updateRole**](RoleControllerApi.md#updaterole) | **PUT** /api/admin/roles/{id} | 


# **addPermissionToRole**
> Role addPermissionToRole(roleId, permissionId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoleControllerApi();
final roleId = 789; // int | 
final permissionId = 789; // int | 

try {
    final result = api_instance.addPermissionToRole(roleId, permissionId);
    print(result);
} catch (e) {
    print('Exception when calling RoleControllerApi->addPermissionToRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roleId** | **int**|  | 
 **permissionId** | **int**|  | 

### Return type

[**Role**](Role.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createRole**
> Role createRole(role)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoleControllerApi();
final role = Role(); // Role | 

try {
    final result = api_instance.createRole(role);
    print(result);
} catch (e) {
    print('Exception when calling RoleControllerApi->createRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **role** | [**Role**](Role.md)|  | 

### Return type

[**Role**](Role.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteRole**
> deleteRole(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoleControllerApi();
final id = 789; // int | 

try {
    api_instance.deleteRole(id);
} catch (e) {
    print('Exception when calling RoleControllerApi->deleteRole: $e\n');
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

# **getAllRoles**
> List<Role> getAllRoles()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoleControllerApi();

try {
    final result = api_instance.getAllRoles();
    print(result);
} catch (e) {
    print('Exception when calling RoleControllerApi->getAllRoles: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Role>**](Role.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRoleById**
> Role getRoleById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoleControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getRoleById(id);
    print(result);
} catch (e) {
    print('Exception when calling RoleControllerApi->getRoleById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**Role**](Role.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRolePermissions**
> Set<Permission> getRolePermissions(roleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoleControllerApi();
final roleId = 789; // int | 

try {
    final result = api_instance.getRolePermissions(roleId);
    print(result);
} catch (e) {
    print('Exception when calling RoleControllerApi->getRolePermissions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roleId** | **int**|  | 

### Return type

[**Set<Permission>**](Permission.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removePermissionFromRole**
> Role removePermissionFromRole(roleId, permissionId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoleControllerApi();
final roleId = 789; // int | 
final permissionId = 789; // int | 

try {
    final result = api_instance.removePermissionFromRole(roleId, permissionId);
    print(result);
} catch (e) {
    print('Exception when calling RoleControllerApi->removePermissionFromRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roleId** | **int**|  | 
 **permissionId** | **int**|  | 

### Return type

[**Role**](Role.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateRole**
> Role updateRole(id, role)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoleControllerApi();
final id = 789; // int | 
final role = Role(); // Role | 

try {
    final result = api_instance.updateRole(id, role);
    print(result);
} catch (e) {
    print('Exception when calling RoleControllerApi->updateRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **role** | [**Role**](Role.md)|  | 

### Return type

[**Role**](Role.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

