# openapi.api.UserControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createUser**](UserControllerApi.md#createuser) | **POST** /api/admin/users | 
[**deleteDriverAccount**](UserControllerApi.md#deletedriveraccount) | **DELETE** /api/admin/users/driver-account/{driverId} | 
[**deleteUser**](UserControllerApi.md#deleteuser) | **DELETE** /api/admin/users/{id} | 
[**getAllUsers**](UserControllerApi.md#getallusers) | **GET** /api/admin/users | 
[**getDriverAccount**](UserControllerApi.md#getdriveraccount) | **GET** /api/admin/users/driver-account/{driverId} | 
[**registerDriverAccount**](UserControllerApi.md#registerdriveraccount) | **POST** /api/admin/users/registerdriver | 
[**updateUser**](UserControllerApi.md#updateuser) | **PUT** /api/admin/users/{id} | 


# **createUser**
> Object createUser(registerRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserControllerApi();
final registerRequest = RegisterRequest(); // RegisterRequest | 

try {
    final result = api_instance.createUser(registerRequest);
    print(result);
} catch (e) {
    print('Exception when calling UserControllerApi->createUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerRequest** | [**RegisterRequest**](RegisterRequest.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDriverAccount**
> Object deleteDriverAccount(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.deleteDriverAccount(driverId);
    print(result);
} catch (e) {
    print('Exception when calling UserControllerApi->deleteDriverAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteUser**
> Object deleteUser(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteUser(id);
    print(result);
} catch (e) {
    print('Exception when calling UserControllerApi->deleteUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllUsers**
> List<UserDto> getAllUsers()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserControllerApi();

try {
    final result = api_instance.getAllUsers();
    print(result);
} catch (e) {
    print('Exception when calling UserControllerApi->getAllUsers: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<UserDto>**](UserDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDriverAccount**
> Object getDriverAccount(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getDriverAccount(driverId);
    print(result);
} catch (e) {
    print('Exception when calling UserControllerApi->getDriverAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerDriverAccount**
> Object registerDriverAccount(driverId, registerRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserControllerApi();
final driverId = 789; // int | 
final registerRequest = RegisterRequest(); // RegisterRequest | 

try {
    final result = api_instance.registerDriverAccount(driverId, registerRequest);
    print(result);
} catch (e) {
    print('Exception when calling UserControllerApi->registerDriverAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **registerRequest** | [**RegisterRequest**](RegisterRequest.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateUser**
> Object updateUser(id, registerRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserControllerApi();
final id = 789; // int | 
final registerRequest = RegisterRequest(); // RegisterRequest | 

try {
    final result = api_instance.updateUser(id, registerRequest);
    print(result);
} catch (e) {
    print('Exception when calling UserControllerApi->updateUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **registerRequest** | [**RegisterRequest**](RegisterRequest.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

