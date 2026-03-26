# openapi.api.UserPermissionControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assignPermissionToUser**](UserPermissionControllerApi.md#assignpermissiontouser) | **POST** /api/admin/user-permissions/assign | 
[**assignPermissionToUserByName**](UserPermissionControllerApi.md#assignpermissiontouserbyname) | **POST** /api/admin/user-permissions/assign-by-name | 
[**getCurrentUserPermissions**](UserPermissionControllerApi.md#getcurrentuserpermissions) | **GET** /api/admin/user-permissions/me/effective | 
[**getEffectivePermissions**](UserPermissionControllerApi.md#geteffectivepermissions) | **GET** /api/admin/user-permissions/user/{userId}/effective | 
[**getUserPermissions**](UserPermissionControllerApi.md#getuserpermissions) | **GET** /api/admin/user-permissions/user/{userId} | 
[**getUsersWithPermission**](UserPermissionControllerApi.md#getuserswithpermission) | **GET** /api/admin/user-permissions/users-with-permission | 
[**removePermissionFromUser**](UserPermissionControllerApi.md#removepermissionfromuser) | **DELETE** /api/admin/user-permissions/remove | 
[**userHasPermission**](UserPermissionControllerApi.md#userhaspermission) | **GET** /api/admin/user-permissions/user/{userId}/has-permission | 


# **assignPermissionToUser**
> String assignPermissionToUser(userId, permissionId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserPermissionControllerApi();
final userId = 789; // int | 
final permissionId = 789; // int | 

try {
    final result = api_instance.assignPermissionToUser(userId, permissionId);
    print(result);
} catch (e) {
    print('Exception when calling UserPermissionControllerApi->assignPermissionToUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 
 **permissionId** | **int**|  | 

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assignPermissionToUserByName**
> String assignPermissionToUserByName(userId, permissionName)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserPermissionControllerApi();
final userId = 789; // int | 
final permissionName = permissionName_example; // String | 

try {
    final result = api_instance.assignPermissionToUserByName(userId, permissionName);
    print(result);
} catch (e) {
    print('Exception when calling UserPermissionControllerApi->assignPermissionToUserByName: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 
 **permissionName** | **String**|  | 

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCurrentUserPermissions**
> UserPermissionSummaryDto getCurrentUserPermissions()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserPermissionControllerApi();

try {
    final result = api_instance.getCurrentUserPermissions();
    print(result);
} catch (e) {
    print('Exception when calling UserPermissionControllerApi->getCurrentUserPermissions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UserPermissionSummaryDto**](UserPermissionSummaryDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getEffectivePermissions**
> UserPermissionSummaryDto getEffectivePermissions(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserPermissionControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.getEffectivePermissions(userId);
    print(result);
} catch (e) {
    print('Exception when calling UserPermissionControllerApi->getEffectivePermissions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

[**UserPermissionSummaryDto**](UserPermissionSummaryDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserPermissions**
> Set<Permission> getUserPermissions(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserPermissionControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.getUserPermissions(userId);
    print(result);
} catch (e) {
    print('Exception when calling UserPermissionControllerApi->getUserPermissions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

[**Set<Permission>**](Permission.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUsersWithPermission**
> List<User> getUsersWithPermission(permissionName)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserPermissionControllerApi();
final permissionName = permissionName_example; // String | 

try {
    final result = api_instance.getUsersWithPermission(permissionName);
    print(result);
} catch (e) {
    print('Exception when calling UserPermissionControllerApi->getUsersWithPermission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **permissionName** | **String**|  | 

### Return type

[**List<User>**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removePermissionFromUser**
> String removePermissionFromUser(userId, permissionId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserPermissionControllerApi();
final userId = 789; // int | 
final permissionId = 789; // int | 

try {
    final result = api_instance.removePermissionFromUser(userId, permissionId);
    print(result);
} catch (e) {
    print('Exception when calling UserPermissionControllerApi->removePermissionFromUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 
 **permissionId** | **int**|  | 

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **userHasPermission**
> bool userHasPermission(userId, permissionName)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserPermissionControllerApi();
final userId = 789; // int | 
final permissionName = permissionName_example; // String | 

try {
    final result = api_instance.userHasPermission(userId, permissionName);
    print(result);
} catch (e) {
    print('Exception when calling UserPermissionControllerApi->userHasPermission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 
 **permissionName** | **String**|  | 

### Return type

**bool**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

