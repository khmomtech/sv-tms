# openapi.api.AuthPasswordResetControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**forgotPassword**](AuthPasswordResetControllerApi.md#forgotpassword) | **POST** /api/auth/forgot-password | 
[**resetPassword**](AuthPasswordResetControllerApi.md#resetpassword) | **POST** /api/auth/reset-password | 


# **forgotPassword**
> Object forgotPassword(forgotPasswordRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuthPasswordResetControllerApi();
final forgotPasswordRequest = ForgotPasswordRequest(); // ForgotPasswordRequest | 

try {
    final result = api_instance.forgotPassword(forgotPasswordRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthPasswordResetControllerApi->forgotPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **forgotPasswordRequest** | [**ForgotPasswordRequest**](ForgotPasswordRequest.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resetPassword**
> Object resetPassword(resetPasswordRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuthPasswordResetControllerApi();
final resetPasswordRequest = ResetPasswordRequest(); // ResetPasswordRequest | 

try {
    final result = api_instance.resetPassword(resetPasswordRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthPasswordResetControllerApi->resetPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resetPasswordRequest** | [**ResetPasswordRequest**](ResetPasswordRequest.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

