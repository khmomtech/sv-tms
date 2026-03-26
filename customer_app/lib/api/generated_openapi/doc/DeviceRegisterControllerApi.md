# openapi.api.DeviceRegisterControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**approveDevice**](DeviceRegisterControllerApi.md#approvedevice) | **PUT** /api/driver/device/approve/{id} | 
[**blockDevice**](DeviceRegisterControllerApi.md#blockdevice) | **PUT** /api/driver/device/block/{id} | 
[**createDevice**](DeviceRegisterControllerApi.md#createdevice) | **POST** /api/driver/device/create | 
[**deleteDevice**](DeviceRegisterControllerApi.md#deletedevice) | **DELETE** /api/driver/device/{id} | 
[**filterDevices**](DeviceRegisterControllerApi.md#filterdevices) | **GET** /api/driver/device/filter | 
[**getAllDevices**](DeviceRegisterControllerApi.md#getalldevices) | **GET** /api/driver/device/all | 
[**getDevice**](DeviceRegisterControllerApi.md#getdevice) | **GET** /api/driver/device/{id} | 
[**registerDevice**](DeviceRegisterControllerApi.md#registerdevice) | **POST** /api/driver/device/register | 
[**requestApproval**](DeviceRegisterControllerApi.md#requestapproval) | **POST** /api/driver/device/request-approval | 
[**setPendingDevice**](DeviceRegisterControllerApi.md#setpendingdevice) | **PUT** /api/driver/device/pending/{id} | 
[**updateDevice**](DeviceRegisterControllerApi.md#updatedevice) | **PUT** /api/driver/device/{id} | 
[**updateDeviceStatus**](DeviceRegisterControllerApi.md#updatedevicestatus) | **PUT** /api/driver/device/{id}/status | 


# **approveDevice**
> ApiResponseVoid approveDevice(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.approveDevice(id);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->approveDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseVoid**](ApiResponseVoid.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **blockDevice**
> ApiResponseVoid blockDevice(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.blockDevice(id);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->blockDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseVoid**](ApiResponseVoid.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createDevice**
> ApiResponseDeviceRegisterDto createDevice(deviceRegisterDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final deviceRegisterDto = DeviceRegisterDto(); // DeviceRegisterDto | 

try {
    final result = api_instance.createDevice(deviceRegisterDto);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->createDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceRegisterDto** | [**DeviceRegisterDto**](DeviceRegisterDto.md)|  | 

### Return type

[**ApiResponseDeviceRegisterDto**](ApiResponseDeviceRegisterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDevice**
> ApiResponseVoid deleteDevice(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteDevice(id);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->deleteDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseVoid**](ApiResponseVoid.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **filterDevices**
> ApiResponseListDeviceRegisterDto filterDevices(status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final status = status_example; // String | 

try {
    final result = api_instance.filterDevices(status);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->filterDevices: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | 

### Return type

[**ApiResponseListDeviceRegisterDto**](ApiResponseListDeviceRegisterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllDevices**
> ApiResponseListDeviceRegisterDto getAllDevices()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();

try {
    final result = api_instance.getAllDevices();
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->getAllDevices: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListDeviceRegisterDto**](ApiResponseListDeviceRegisterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDevice**
> ApiResponseDeviceRegisterDto getDevice(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDevice(id);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->getDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseDeviceRegisterDto**](ApiResponseDeviceRegisterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerDevice**
> ApiResponseDeviceStatus registerDevice(deviceRegisterDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final deviceRegisterDto = DeviceRegisterDto(); // DeviceRegisterDto | 

try {
    final result = api_instance.registerDevice(deviceRegisterDto);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->registerDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceRegisterDto** | [**DeviceRegisterDto**](DeviceRegisterDto.md)|  | 

### Return type

[**ApiResponseDeviceStatus**](ApiResponseDeviceStatus.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **requestApproval**
> ApiResponseVoid requestApproval(deviceApprovalRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final deviceApprovalRequest = DeviceApprovalRequest(); // DeviceApprovalRequest | 

try {
    final result = api_instance.requestApproval(deviceApprovalRequest);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->requestApproval: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceApprovalRequest** | [**DeviceApprovalRequest**](DeviceApprovalRequest.md)|  | 

### Return type

[**ApiResponseVoid**](ApiResponseVoid.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setPendingDevice**
> ApiResponseVoid setPendingDevice(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.setPendingDevice(id);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->setPendingDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseVoid**](ApiResponseVoid.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDevice**
> ApiResponseDeviceRegisterDto updateDevice(id, deviceRegisterDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final id = 789; // int | 
final deviceRegisterDto = DeviceRegisterDto(); // DeviceRegisterDto | 

try {
    final result = api_instance.updateDevice(id, deviceRegisterDto);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->updateDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **deviceRegisterDto** | [**DeviceRegisterDto**](DeviceRegisterDto.md)|  | 

### Return type

[**ApiResponseDeviceRegisterDto**](ApiResponseDeviceRegisterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDeviceStatus**
> ApiResponseVoid updateDeviceStatus(id, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DeviceRegisterControllerApi();
final id = 789; // int | 
final status = status_example; // String | 

try {
    final result = api_instance.updateDeviceStatus(id, status);
    print(result);
} catch (e) {
    print('Exception when calling DeviceRegisterControllerApi->updateDeviceStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **status** | **String**|  | 

### Return type

[**ApiResponseVoid**](ApiResponseVoid.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

