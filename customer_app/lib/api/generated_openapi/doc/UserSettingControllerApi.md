# openapi.api.UserSettingControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getSettings**](UserSettingControllerApi.md#getsettings) | **GET** /api/user-settings | 
[**getUserSettingByKey**](UserSettingControllerApi.md#getusersettingbykey) | **GET** /api/user-settings/key/{key} | 
[**updateUserSetting**](UserSettingControllerApi.md#updateusersetting) | **POST** /api/user-settings/update | 


# **getSettings**
> ApiResponseListUserSetting getSettings()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserSettingControllerApi();

try {
    final result = api_instance.getSettings();
    print(result);
} catch (e) {
    print('Exception when calling UserSettingControllerApi->getSettings: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListUserSetting**](ApiResponseListUserSetting.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUserSettingByKey**
> ApiResponseUserSetting getUserSettingByKey(key)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserSettingControllerApi();
final key = key_example; // String | 

try {
    final result = api_instance.getUserSettingByKey(key);
    print(result);
} catch (e) {
    print('Exception when calling UserSettingControllerApi->getUserSettingByKey: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **key** | **String**|  | 

### Return type

[**ApiResponseUserSetting**](ApiResponseUserSetting.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateUserSetting**
> ApiResponseUserSetting updateUserSetting(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = UserSettingControllerApi();
final requestBody = Map<String, String>(); // Map<String, String> | 

try {
    final result = api_instance.updateUserSetting(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling UserSettingControllerApi->updateUserSetting: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, String>**](String.md)|  | 

### Return type

[**ApiResponseUserSetting**](ApiResponseUserSetting.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

