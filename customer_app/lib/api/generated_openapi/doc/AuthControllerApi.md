# openapi.api.AuthControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**changePassword**](AuthControllerApi.md#changepassword) | **POST** /api/auth/change-password | 
[**driverLogin**](AuthControllerApi.md#driverlogin) | **POST** /api/auth/driver/login | 
[**login**](AuthControllerApi.md#login) | **POST** /api/auth/login | 
[**refresh**](AuthControllerApi.md#refresh) | **POST** /api/auth/refresh | 
[**register**](AuthControllerApi.md#register) | **POST** /api/auth/register | 
[**registerDriver**](AuthControllerApi.md#registerdriver) | **POST** /api/auth/registerdriver | 


# **changePassword**
> ApiResponseString changePassword(changePasswordRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuthControllerApi();
final changePasswordRequest = ChangePasswordRequest(); // ChangePasswordRequest | 

try {
    final result = api_instance.changePassword(changePasswordRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthControllerApi->changePassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **changePasswordRequest** | [**ChangePasswordRequest**](ChangePasswordRequest.md)|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverLogin**
> ApiResponseMapStringObject driverLogin(loginRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuthControllerApi();
final loginRequest = LoginRequest(); // LoginRequest | 

try {
    final result = api_instance.driverLogin(loginRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthControllerApi->driverLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **login**
> ApiResponseMapStringObject login(loginRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuthControllerApi();
final loginRequest = LoginRequest(); // LoginRequest | 

try {
    final result = api_instance.login(loginRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthControllerApi->login: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | 

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refresh**
> ApiResponseMapStringObject refresh(authorization)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuthControllerApi();
final authorization = authorization_example; // String | 

try {
    final result = api_instance.refresh(authorization);
    print(result);
} catch (e) {
    print('Exception when calling AuthControllerApi->refresh: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **authorization** | **String**|  | [optional] 

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **register**
> ApiResponseString register(registerRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuthControllerApi();
final registerRequest = RegisterRequest(); // RegisterRequest | 

try {
    final result = api_instance.register(registerRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthControllerApi->register: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **registerRequest** | [**RegisterRequest**](RegisterRequest.md)|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerDriver**
> ApiResponseMapStringObject registerDriver(driverId, registerDriverRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuthControllerApi();
final driverId = 789; // int | 
final registerDriverRequest = RegisterDriverRequest(); // RegisterDriverRequest | 

try {
    final result = api_instance.registerDriver(driverId, registerDriverRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthControllerApi->registerDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **registerDriverRequest** | [**RegisterDriverRequest**](RegisterDriverRequest.md)|  | 

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

