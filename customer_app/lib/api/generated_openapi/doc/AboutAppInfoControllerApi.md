# openapi.api.AboutAppInfoControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAboutInfo**](AboutAppInfoControllerApi.md#getaboutinfo) | **GET** /api/admin/about-app | 
[**saveAboutInfo**](AboutAppInfoControllerApi.md#saveaboutinfo) | **POST** /api/admin/about-app | 


# **getAboutInfo**
> AboutAppInfo getAboutInfo()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AboutAppInfoControllerApi();

try {
    final result = api_instance.getAboutInfo();
    print(result);
} catch (e) {
    print('Exception when calling AboutAppInfoControllerApi->getAboutInfo: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AboutAppInfo**](AboutAppInfo.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **saveAboutInfo**
> AboutAppInfo saveAboutInfo(aboutAppInfo)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AboutAppInfoControllerApi();
final aboutAppInfo = AboutAppInfo(); // AboutAppInfo | 

try {
    final result = api_instance.saveAboutInfo(aboutAppInfo);
    print(result);
} catch (e) {
    print('Exception when calling AboutAppInfoControllerApi->saveAboutInfo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **aboutAppInfo** | [**AboutAppInfo**](AboutAppInfo.md)|  | 

### Return type

[**AboutAppInfo**](AboutAppInfo.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

