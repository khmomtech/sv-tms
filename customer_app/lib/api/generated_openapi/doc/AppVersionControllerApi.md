# openapi.api.AppVersionControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAllVersions**](AppVersionControllerApi.md#getallversions) | **GET** /api/admin/app-versions | 
[**getLatestVersion1**](AppVersionControllerApi.md#getlatestversion1) | **GET** /api/admin/app-versions/latest | 
[**saveAppVersion**](AppVersionControllerApi.md#saveappversion) | **POST** /api/admin/app-versions | 


# **getAllVersions**
> List<AppVersion> getAllVersions()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AppVersionControllerApi();

try {
    final result = api_instance.getAllVersions();
    print(result);
} catch (e) {
    print('Exception when calling AppVersionControllerApi->getAllVersions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<AppVersion>**](AppVersion.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLatestVersion1**
> AppVersion getLatestVersion1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AppVersionControllerApi();

try {
    final result = api_instance.getLatestVersion1();
    print(result);
} catch (e) {
    print('Exception when calling AppVersionControllerApi->getLatestVersion1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AppVersion**](AppVersion.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **saveAppVersion**
> AppVersion saveAppVersion(appVersion)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AppVersionControllerApi();
final appVersion = AppVersion(); // AppVersion | 

try {
    final result = api_instance.saveAppVersion(appVersion);
    print(result);
} catch (e) {
    print('Exception when calling AppVersionControllerApi->saveAppVersion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **appVersion** | [**AppVersion**](AppVersion.md)|  | 

### Return type

[**AppVersion**](AppVersion.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

