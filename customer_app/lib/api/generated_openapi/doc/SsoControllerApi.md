# openapi.api.SsoControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authenticateWithSsoToken**](SsoControllerApi.md#authenticatewithssotoken) | **POST** /api/sso/authenticate | 
[**createSsoToken**](SsoControllerApi.md#createssotoken) | **POST** /api/sso/create-token | 
[**validateSsoToken**](SsoControllerApi.md#validatessotoken) | **POST** /api/sso/validate | 


# **authenticateWithSsoToken**
> Object authenticateWithSsoToken(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SsoControllerApi();
final requestBody = Map<String, String>(); // Map<String, String> | 

try {
    final result = api_instance.authenticateWithSsoToken(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling SsoControllerApi->authenticateWithSsoToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, String>**](String.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createSsoToken**
> Object createSsoToken(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SsoControllerApi();
final requestBody = Map<String, String>(); // Map<String, String> | 

try {
    final result = api_instance.createSsoToken(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling SsoControllerApi->createSsoToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, String>**](String.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **validateSsoToken**
> Object validateSsoToken(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SsoControllerApi();
final requestBody = Map<String, String>(); // Map<String, String> | 

try {
    final result = api_instance.validateSsoToken(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling SsoControllerApi->validateSsoToken: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, String>**](String.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

