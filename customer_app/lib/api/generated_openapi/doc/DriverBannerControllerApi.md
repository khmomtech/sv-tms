# openapi.api.DriverBannerControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getActiveBanners**](DriverBannerControllerApi.md#getactivebanners) | **GET** /api/driver/banners/active | 
[**getActiveBannersByCategory**](DriverBannerControllerApi.md#getactivebannersbycategory) | **GET** /api/driver/banners/category/{category} | 
[**trackClick**](DriverBannerControllerApi.md#trackclick) | **POST** /api/driver/banners/{id}/click | 


# **getActiveBanners**
> ApiResponseListBannerDto getActiveBanners()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverBannerControllerApi();

try {
    final result = api_instance.getActiveBanners();
    print(result);
} catch (e) {
    print('Exception when calling DriverBannerControllerApi->getActiveBanners: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListBannerDto**](ApiResponseListBannerDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getActiveBannersByCategory**
> ApiResponseListBannerDto getActiveBannersByCategory(category)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverBannerControllerApi();
final category = category_example; // String | 

try {
    final result = api_instance.getActiveBannersByCategory(category);
    print(result);
} catch (e) {
    print('Exception when calling DriverBannerControllerApi->getActiveBannersByCategory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **category** | **String**|  | 

### Return type

[**ApiResponseListBannerDto**](ApiResponseListBannerDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **trackClick**
> ApiResponseString trackClick(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverBannerControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.trackClick(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverBannerControllerApi->trackClick: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

