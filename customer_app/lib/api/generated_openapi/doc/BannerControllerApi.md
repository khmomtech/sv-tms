# openapi.api.BannerControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createBanner**](BannerControllerApi.md#createbanner) | **POST** /api/admin/banners | 
[**deleteBanner**](BannerControllerApi.md#deletebanner) | **DELETE** /api/admin/banners/{id} | 
[**getAllBanners**](BannerControllerApi.md#getallbanners) | **GET** /api/admin/banners | 
[**getBannerById**](BannerControllerApi.md#getbannerbyid) | **GET** /api/admin/banners/{id} | 
[**updateBanner**](BannerControllerApi.md#updatebanner) | **PUT** /api/admin/banners/{id} | 


# **createBanner**
> ApiResponseBannerDto createBanner(bannerDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = BannerControllerApi();
final bannerDto = BannerDto(); // BannerDto | 

try {
    final result = api_instance.createBanner(bannerDto);
    print(result);
} catch (e) {
    print('Exception when calling BannerControllerApi->createBanner: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **bannerDto** | [**BannerDto**](BannerDto.md)|  | 

### Return type

[**ApiResponseBannerDto**](ApiResponseBannerDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteBanner**
> ApiResponseString deleteBanner(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = BannerControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteBanner(id);
    print(result);
} catch (e) {
    print('Exception when calling BannerControllerApi->deleteBanner: $e\n');
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

# **getAllBanners**
> ApiResponseListBannerDto getAllBanners()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = BannerControllerApi();

try {
    final result = api_instance.getAllBanners();
    print(result);
} catch (e) {
    print('Exception when calling BannerControllerApi->getAllBanners: $e\n');
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

# **getBannerById**
> ApiResponseBannerDto getBannerById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = BannerControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getBannerById(id);
    print(result);
} catch (e) {
    print('Exception when calling BannerControllerApi->getBannerById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseBannerDto**](ApiResponseBannerDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateBanner**
> ApiResponseBannerDto updateBanner(id, bannerDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = BannerControllerApi();
final id = 789; // int | 
final bannerDto = BannerDto(); // BannerDto | 

try {
    final result = api_instance.updateBanner(id, bannerDto);
    print(result);
} catch (e) {
    print('Exception when calling BannerControllerApi->updateBanner: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **bannerDto** | [**BannerDto**](BannerDto.md)|  | 

### Return type

[**ApiResponseBannerDto**](ApiResponseBannerDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

