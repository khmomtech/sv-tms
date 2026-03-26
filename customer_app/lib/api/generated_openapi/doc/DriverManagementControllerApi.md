# openapi.api.DriverManagementControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**advancedSearchDrivers1**](DriverManagementControllerApi.md#advancedsearchdrivers1) | **POST** /api/admin/drivers/advanced-search | 
[**createDriver**](DriverManagementControllerApi.md#createdriver) | **POST** /api/admin/drivers/add | 
[**deleteDriver1**](DriverManagementControllerApi.md#deletedriver1) | **DELETE** /api/admin/drivers/delete/{id} | 
[**driverHeartbeat1**](DriverManagementControllerApi.md#driverheartbeat1) | **POST** /api/admin/drivers/{driverId}/heartbeat | 
[**getAllDrivers1**](DriverManagementControllerApi.md#getalldrivers1) | **GET** /api/admin/drivers/list | 
[**getAllDriversNoPag1**](DriverManagementControllerApi.md#getalldriversnopag1) | **GET** /api/admin/drivers/all | 
[**getAllListDrivers1**](DriverManagementControllerApi.md#getalllistdrivers1) | **GET** /api/admin/drivers/alllists | 
[**getDeviceToken1**](DriverManagementControllerApi.md#getdevicetoken1) | **GET** /api/admin/drivers/{id}/device-token | 
[**getDriverById2**](DriverManagementControllerApi.md#getdriverbyid2) | **GET** /api/admin/drivers/{id} | 
[**searchDrivers2**](DriverManagementControllerApi.md#searchdrivers2) | **GET** /api/admin/drivers/search | 
[**updateDeviceToken1**](DriverManagementControllerApi.md#updatedevicetoken1) | **POST** /api/admin/drivers/update-device-token | 
[**updateDriver1**](DriverManagementControllerApi.md#updatedriver1) | **PUT** /api/admin/drivers/update/{id} | 
[**uploadProfilePictureAdmin1**](DriverManagementControllerApi.md#uploadprofilepictureadmin1) | **POST** /api/admin/drivers/{driverId}/upload-profile | 


# **advancedSearchDrivers1**
> ApiResponsePageResponseDriverDto advancedSearchDrivers1(page, size, driverFilterRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final page = 56; // int | 
final size = 56; // int | 
final driverFilterRequest = DriverFilterRequest(); // DriverFilterRequest | 

try {
    final result = api_instance.advancedSearchDrivers1(page, size, driverFilterRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->advancedSearchDrivers1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 12]
 **driverFilterRequest** | [**DriverFilterRequest**](DriverFilterRequest.md)|  | [optional] 

### Return type

[**ApiResponsePageResponseDriverDto**](ApiResponsePageResponseDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createDriver**
> ApiResponseDriverDto createDriver(driverCreateRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final driverCreateRequest = DriverCreateRequest(); // DriverCreateRequest | 

try {
    final result = api_instance.createDriver(driverCreateRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->createDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverCreateRequest** | [**DriverCreateRequest**](DriverCreateRequest.md)|  | 

### Return type

[**ApiResponseDriverDto**](ApiResponseDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDriver1**
> ApiResponseString deleteDriver1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteDriver1(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->deleteDriver1: $e\n');
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

# **driverHeartbeat1**
> ApiResponseString driverHeartbeat1(driverId, heartbeatDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final driverId = 789; // int | 
final heartbeatDto = HeartbeatDto(); // HeartbeatDto | 

try {
    final result = api_instance.driverHeartbeat1(driverId, heartbeatDto);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->driverHeartbeat1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **heartbeatDto** | [**HeartbeatDto**](HeartbeatDto.md)|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllDrivers1**
> ApiResponsePageResponseDriverDto getAllDrivers1(page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getAllDrivers1(page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->getAllDrivers1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 5]

### Return type

[**ApiResponsePageResponseDriverDto**](ApiResponsePageResponseDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllDriversNoPag1**
> ApiResponseListDriverDto getAllDriversNoPag1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();

try {
    final result = api_instance.getAllDriversNoPag1();
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->getAllDriversNoPag1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListDriverDto**](ApiResponseListDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllListDrivers1**
> ApiResponsePageResponseDriverDto getAllListDrivers1(page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getAllListDrivers1(page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->getAllListDrivers1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 5]

### Return type

[**ApiResponsePageResponseDriverDto**](ApiResponsePageResponseDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDeviceToken1**
> ApiResponseString getDeviceToken1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDeviceToken1(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->getDeviceToken1: $e\n');
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

# **getDriverById2**
> ApiResponseDriverDto getDriverById2(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDriverById2(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->getDriverById2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseDriverDto**](ApiResponseDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchDrivers2**
> ApiResponseListDriverDto searchDrivers2(query)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final query = query_example; // String | 

try {
    final result = api_instance.searchDrivers2(query);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->searchDrivers2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **query** | **String**|  | 

### Return type

[**ApiResponseListDriverDto**](ApiResponseListDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDeviceToken1**
> ApiResponseString updateDeviceToken1(deviceTokenRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final deviceTokenRequest = DeviceTokenRequest(); // DeviceTokenRequest | 

try {
    final result = api_instance.updateDeviceToken1(deviceTokenRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->updateDeviceToken1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceTokenRequest** | [**DeviceTokenRequest**](DeviceTokenRequest.md)|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDriver1**
> ApiResponseDriverDto updateDriver1(id, driverUpdateRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final id = 789; // int | 
final driverUpdateRequest = DriverUpdateRequest(); // DriverUpdateRequest | 

try {
    final result = api_instance.updateDriver1(id, driverUpdateRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->updateDriver1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **driverUpdateRequest** | [**DriverUpdateRequest**](DriverUpdateRequest.md)|  | 

### Return type

[**ApiResponseDriverDto**](ApiResponseDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadProfilePictureAdmin1**
> ApiResponseString uploadProfilePictureAdmin1(driverId, profilePicture)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverManagementControllerApi();
final driverId = 789; // int | 
final profilePicture = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.uploadProfilePictureAdmin1(driverId, profilePicture);
    print(result);
} catch (e) {
    print('Exception when calling DriverManagementControllerApi->uploadProfilePictureAdmin1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **profilePicture** | **MultipartFile**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

