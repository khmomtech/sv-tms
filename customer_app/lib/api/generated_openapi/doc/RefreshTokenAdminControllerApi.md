# openapi.api.RefreshTokenAdminControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**list1**](RefreshTokenAdminControllerApi.md#list1) | **GET** /api/admin/refresh-tokens | 
[**revoke**](RefreshTokenAdminControllerApi.md#revoke) | **POST** /api/admin/refresh-tokens/{id}/revoke | 


# **list1**
> Object list1(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RefreshTokenAdminControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.list1(userId);
    print(result);
} catch (e) {
    print('Exception when calling RefreshTokenAdminControllerApi->list1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | [optional] 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revoke**
> Object revoke(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RefreshTokenAdminControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.revoke(id);
    print(result);
} catch (e) {
    print('Exception when calling RefreshTokenAdminControllerApi->revoke: $e\n');
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

