# openapi.api.PublicAppVersionControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getLatestVersion**](PublicAppVersionControllerApi.md#getlatestversion) | **GET** /api/public/app-version/latest | 


# **getLatestVersion**
> AppVersion getLatestVersion()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PublicAppVersionControllerApi();

try {
    final result = api_instance.getLatestVersion();
    print(result);
} catch (e) {
    print('Exception when calling PublicAppVersionControllerApi->getLatestVersion: $e\n');
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

