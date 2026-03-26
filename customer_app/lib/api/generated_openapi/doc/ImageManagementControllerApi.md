# openapi.api.ImageManagementControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteImage**](ImageManagementControllerApi.md#deleteimage) | **DELETE** /api/admin/images/{imageId} | 
[**getAllImages**](ImageManagementControllerApi.md#getallimages) | **GET** /api/admin/images | 
[**getImagesByCategory**](ImageManagementControllerApi.md#getimagesbycategory) | **GET** /api/admin/images/category/{category} | 
[**updateImageMetadata**](ImageManagementControllerApi.md#updateimagemetadata) | **PUT** /api/admin/images/{imageId} | 
[**uploadImage**](ImageManagementControllerApi.md#uploadimage) | **POST** /api/admin/images/upload | 


# **deleteImage**
> ApiResponseString deleteImage(imageId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ImageManagementControllerApi();
final imageId = imageId_example; // String | 

try {
    final result = api_instance.deleteImage(imageId);
    print(result);
} catch (e) {
    print('Exception when calling ImageManagementControllerApi->deleteImage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **imageId** | **String**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllImages**
> ApiResponseListMapStringObject getAllImages()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ImageManagementControllerApi();

try {
    final result = api_instance.getAllImages();
    print(result);
} catch (e) {
    print('Exception when calling ImageManagementControllerApi->getAllImages: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListMapStringObject**](ApiResponseListMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getImagesByCategory**
> ApiResponseListMapStringObject getImagesByCategory(category)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ImageManagementControllerApi();
final category = category_example; // String | 

try {
    final result = api_instance.getImagesByCategory(category);
    print(result);
} catch (e) {
    print('Exception when calling ImageManagementControllerApi->getImagesByCategory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **category** | **String**|  | 

### Return type

[**ApiResponseListMapStringObject**](ApiResponseListMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateImageMetadata**
> ApiResponseMapStringObject updateImageMetadata(imageId, requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ImageManagementControllerApi();
final imageId = imageId_example; // String | 
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.updateImageMetadata(imageId, requestBody);
    print(result);
} catch (e) {
    print('Exception when calling ImageManagementControllerApi->updateImageMetadata: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **imageId** | **String**|  | 
 **requestBody** | [**Map<String, Object>**](Object.md)|  | 

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadImage**
> ApiResponseMapStringObject uploadImage(file, category, description)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ImageManagementControllerApi();
final file = BINARY_DATA_HERE; // MultipartFile | 
final category = category_example; // String | 
final description = description_example; // String | 

try {
    final result = api_instance.uploadImage(file, category, description);
    print(result);
} catch (e) {
    print('Exception when calling ImageManagementControllerApi->uploadImage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | 
 **category** | **String**|  | [optional] [default to 'general']
 **description** | **String**|  | [optional] 

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

