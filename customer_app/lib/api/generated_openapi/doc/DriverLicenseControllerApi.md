# openapi.api.DriverLicenseControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addDriverLicense**](DriverLicenseControllerApi.md#adddriverlicense) | **POST** /api/admin/driver-licenses/{driverId} | 
[**deleteLicenseById**](DriverLicenseControllerApi.md#deletelicensebyid) | **DELETE** /api/admin/driver-licenses/by-id/{licenseId} | 
[**getAllLicenses**](DriverLicenseControllerApi.md#getalllicenses) | **GET** /api/admin/driver-licenses | 
[**getLicenseByDriverId**](DriverLicenseControllerApi.md#getlicensebydriverid) | **GET** /api/admin/driver-licenses/{driverId} | 
[**updateDriverLicense**](DriverLicenseControllerApi.md#updatedriverlicense) | **PUT** /api/admin/driver-licenses/{driverId} | 
[**uploadBackImage**](DriverLicenseControllerApi.md#uploadbackimage) | **POST** /api/admin/driver-licenses/{driverId}/upload-back | 
[**uploadFrontImage**](DriverLicenseControllerApi.md#uploadfrontimage) | **POST** /api/admin/driver-licenses/{driverId}/upload-front | 


# **addDriverLicense**
> ApiResponseDriverLicenseDto addDriverLicense(driverId, driverLicenseDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLicenseControllerApi();
final driverId = 789; // int | 
final driverLicenseDto = DriverLicenseDto(); // DriverLicenseDto | 

try {
    final result = api_instance.addDriverLicense(driverId, driverLicenseDto);
    print(result);
} catch (e) {
    print('Exception when calling DriverLicenseControllerApi->addDriverLicense: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **driverLicenseDto** | [**DriverLicenseDto**](DriverLicenseDto.md)|  | 

### Return type

[**ApiResponseDriverLicenseDto**](ApiResponseDriverLicenseDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteLicenseById**
> ApiResponseString deleteLicenseById(licenseId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLicenseControllerApi();
final licenseId = 789; // int | 

try {
    final result = api_instance.deleteLicenseById(licenseId);
    print(result);
} catch (e) {
    print('Exception when calling DriverLicenseControllerApi->deleteLicenseById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **licenseId** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllLicenses**
> ApiResponseListDriverLicenseDto getAllLicenses(includeDeleted)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLicenseControllerApi();
final includeDeleted = true; // bool | 

try {
    final result = api_instance.getAllLicenses(includeDeleted);
    print(result);
} catch (e) {
    print('Exception when calling DriverLicenseControllerApi->getAllLicenses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **includeDeleted** | **bool**|  | [optional] [default to false]

### Return type

[**ApiResponseListDriverLicenseDto**](ApiResponseListDriverLicenseDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLicenseByDriverId**
> ApiResponseDriverLicenseDto getLicenseByDriverId(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLicenseControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getLicenseByDriverId(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverLicenseControllerApi->getLicenseByDriverId: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseDriverLicenseDto**](ApiResponseDriverLicenseDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDriverLicense**
> ApiResponseDriverLicenseDto updateDriverLicense(driverId, driverLicenseDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLicenseControllerApi();
final driverId = 789; // int | 
final driverLicenseDto = DriverLicenseDto(); // DriverLicenseDto | 

try {
    final result = api_instance.updateDriverLicense(driverId, driverLicenseDto);
    print(result);
} catch (e) {
    print('Exception when calling DriverLicenseControllerApi->updateDriverLicense: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **driverLicenseDto** | [**DriverLicenseDto**](DriverLicenseDto.md)|  | 

### Return type

[**ApiResponseDriverLicenseDto**](ApiResponseDriverLicenseDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadBackImage**
> ApiResponseString uploadBackImage(driverId, updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLicenseControllerApi();
final driverId = 789; // int | 
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.uploadBackImage(driverId, updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverLicenseControllerApi->uploadBackImage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **updateDocumentFileRequest** | [**UpdateDocumentFileRequest**](UpdateDocumentFileRequest.md)|  | [optional] 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadFrontImage**
> ApiResponseString uploadFrontImage(driverId, updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLicenseControllerApi();
final driverId = 789; // int | 
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.uploadFrontImage(driverId, updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverLicenseControllerApi->uploadFrontImage: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **updateDocumentFileRequest** | [**UpdateDocumentFileRequest**](UpdateDocumentFileRequest.md)|  | [optional] 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

