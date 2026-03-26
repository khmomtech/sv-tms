# openapi.api.DriverLocationControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**driverLogout**](DriverLocationControllerApi.md#driverlogout) | **POST** /api/driver/logout | 
[**getPresence**](DriverLocationControllerApi.md#getpresence) | **GET** /api/admin/driver/{driverId}/presence | 
[**presenceHeartbeat**](DriverLocationControllerApi.md#presenceheartbeat) | **POST** /api/driver/presence/heartbeat | 
[**restLocationUpdate**](DriverLocationControllerApi.md#restlocationupdate) | **POST** /api/driver/location/update | 


# **driverLogout**
> Object driverLogout(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLocationControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.driverLogout(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverLocationControllerApi->driverLogout: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPresence**
> Map<String, Object> getPresence(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLocationControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getPresence(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverLocationControllerApi->getPresence: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

**Map<String, Object>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **presenceHeartbeat**
> Object presenceHeartbeat(presenceHeartbeatDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLocationControllerApi();
final presenceHeartbeatDto = PresenceHeartbeatDto(); // PresenceHeartbeatDto | 

try {
    final result = api_instance.presenceHeartbeat(presenceHeartbeatDto);
    print(result);
} catch (e) {
    print('Exception when calling DriverLocationControllerApi->presenceHeartbeat: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **presenceHeartbeatDto** | [**PresenceHeartbeatDto**](PresenceHeartbeatDto.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **restLocationUpdate**
> Object restLocationUpdate(driverLocationUpdateDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverLocationControllerApi();
final driverLocationUpdateDto = DriverLocationUpdateDto(); // DriverLocationUpdateDto | 

try {
    final result = api_instance.restLocationUpdate(driverLocationUpdateDto);
    print(result);
} catch (e) {
    print('Exception when calling DriverLocationControllerApi->restLocationUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverLocationUpdateDto** | [**DriverLocationUpdateDto**](DriverLocationUpdateDto.md)|  | 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

