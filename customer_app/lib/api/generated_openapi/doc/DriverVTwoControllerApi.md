# openapi.api.DriverVTwoControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addDriver**](DriverVTwoControllerApi.md#adddriver) | **POST** /api/driver/add | 
[**adminUpdateDriverLocationBatch**](DriverVTwoControllerApi.md#adminupdatedriverlocationbatch) | **POST** /api/driver/location/update/batch | 
[**advancedSearchDrivers**](DriverVTwoControllerApi.md#advancedsearchdrivers) | **POST** /api/driver/advanced-search | 
[**assignDriver**](DriverVTwoControllerApi.md#assigndriver) | **POST** /api/driver/assign | 
[**broadcastNotification**](DriverVTwoControllerApi.md#broadcastnotification) | **POST** /api/driver/broadcast-notification | 
[**deleteDriver**](DriverVTwoControllerApi.md#deletedriver) | **DELETE** /api/driver/delete/{id} | 
[**deleteDriverNotification1**](DriverVTwoControllerApi.md#deletedrivernotification1) | **DELETE** /api/driver/{driverId}/notifications/{notificationId} | 
[**driverHeartbeat**](DriverVTwoControllerApi.md#driverheartbeat) | **POST** /api/driver/{driverId}/heartbeat | 
[**forceOpenDriverApp**](DriverVTwoControllerApi.md#forceopendriverapp) | **POST** /api/driver/{driverId}/force-open | 
[**getAllDrivers**](DriverVTwoControllerApi.md#getalldrivers) | **GET** /api/driver/list | 
[**getAllDriversNoPag**](DriverVTwoControllerApi.md#getalldriversnopag) | **GET** /api/driver/all | 
[**getAllListDrivers**](DriverVTwoControllerApi.md#getalllistdrivers) | **GET** /api/driver/alllists | 
[**getDeviceToken**](DriverVTwoControllerApi.md#getdevicetoken) | **GET** /api/driver/{id}/device-token | 
[**getDriverById1**](DriverVTwoControllerApi.md#getdriverbyid1) | **GET** /api/driver/{id} | 
[**getDriverLocationHistory**](DriverVTwoControllerApi.md#getdriverlocationhistory) | **GET** /api/driver/{id}/location-history | 
[**getDriverLocationHistoryPaginated**](DriverVTwoControllerApi.md#getdriverlocationhistorypaginated) | **GET** /api/driver/{driverId}/location-history/paginated | 
[**getDriverNotifications1**](DriverVTwoControllerApi.md#getdrivernotifications1) | **GET** /api/driver/{driverId}/notifications | 
[**getVehiclesByDriver**](DriverVTwoControllerApi.md#getvehiclesbydriver) | **GET** /api/driver/by-driver/{driverId} | 
[**getVehiclesWithCurrentDrivers**](DriverVTwoControllerApi.md#getvehicleswithcurrentdrivers) | **GET** /api/driver/vehicles-with-drivers | 
[**latestForDriver**](DriverVTwoControllerApi.md#latestfordriver) | **GET** /api/driver/{driverId}/latest-location | 
[**liveDrivers**](DriverVTwoControllerApi.md#livedrivers) | **GET** /api/driver/live-drivers | 
[**markAllAsRead1**](DriverVTwoControllerApi.md#markallasread1) | **PATCH** /api/driver/{driverId}/notifications/mark-all-read | 
[**markAsRead1**](DriverVTwoControllerApi.md#markasread1) | **PUT** /api/driver/{driverId}/notifications/{notificationId}/read | 
[**markAsReadLegacy1**](DriverVTwoControllerApi.md#markasreadlegacy1) | **PUT** /api/driver/notifications/{notificationId}/read | 
[**searchDrivers1**](DriverVTwoControllerApi.md#searchdrivers1) | **GET** /api/driver/search | 
[**sendNotification**](DriverVTwoControllerApi.md#sendnotification) | **POST** /api/driver/send-notification | 
[**updateDeviceToken**](DriverVTwoControllerApi.md#updatedevicetoken) | **POST** /api/driver/update-device-token | 
[**updateDriver**](DriverVTwoControllerApi.md#updatedriver) | **PUT** /api/driver/update/{id} | 
[**uploadProfilePictureAdmin**](DriverVTwoControllerApi.md#uploadprofilepictureadmin) | **POST** /api/driver/{driverId}/upload-profile | 


# **addDriver**
> ApiResponseDriverDto addDriver(driverCreateRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverCreateRequest = DriverCreateRequest(); // DriverCreateRequest | 

try {
    final result = api_instance.addDriver(driverCreateRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->addDriver: $e\n');
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

# **adminUpdateDriverLocationBatch**
> ApiResponseString adminUpdateDriverLocationBatch(driverLocationUpdateDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverLocationUpdateDto = [List<DriverLocationUpdateDto>()]; // List<DriverLocationUpdateDto> | 

try {
    final result = api_instance.adminUpdateDriverLocationBatch(driverLocationUpdateDto);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->adminUpdateDriverLocationBatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverLocationUpdateDto** | [**List<DriverLocationUpdateDto>**](DriverLocationUpdateDto.md)|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **advancedSearchDrivers**
> ApiResponsePageResponseDriverDto advancedSearchDrivers(driverFilterRequest, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverFilterRequest = DriverFilterRequest(); // DriverFilterRequest | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.advancedSearchDrivers(driverFilterRequest, page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->advancedSearchDrivers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverFilterRequest** | [**DriverFilterRequest**](DriverFilterRequest.md)|  | 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 12]

### Return type

[**ApiResponsePageResponseDriverDto**](ApiResponsePageResponseDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assignDriver**
> ApiResponseDriverAssignment assignDriver(driverId, vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 
final vehicleId = 789; // int | 

try {
    final result = api_instance.assignDriver(driverId, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->assignDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **vehicleId** | **int**|  | 

### Return type

[**ApiResponseDriverAssignment**](ApiResponseDriverAssignment.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **broadcastNotification**
> ApiResponseString broadcastNotification(broadcastNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final broadcastNotificationRequest = BroadcastNotificationRequest(); // BroadcastNotificationRequest | 

try {
    final result = api_instance.broadcastNotification(broadcastNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->broadcastNotification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **broadcastNotificationRequest** | [**BroadcastNotificationRequest**](BroadcastNotificationRequest.md)|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDriver**
> ApiResponseString deleteDriver(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteDriver(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->deleteDriver: $e\n');
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

# **deleteDriverNotification1**
> ApiResponseString deleteDriverNotification1(driverId, notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 
final notificationId = 789; // int | 

try {
    final result = api_instance.deleteDriverNotification1(driverId, notificationId);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->deleteDriverNotification1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **notificationId** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driverHeartbeat**
> ApiResponseString driverHeartbeat(driverId, heartbeatDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 
final heartbeatDto = HeartbeatDto(); // HeartbeatDto | 

try {
    final result = api_instance.driverHeartbeat(driverId, heartbeatDto);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->driverHeartbeat: $e\n');
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

# **forceOpenDriverApp**
> ApiResponseString forceOpenDriverApp(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.forceOpenDriverApp(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->forceOpenDriverApp: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllDrivers**
> ApiResponsePageResponseDriverDto getAllDrivers(page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getAllDrivers(page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getAllDrivers: $e\n');
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

# **getAllDriversNoPag**
> ApiResponseListDriverDto getAllDriversNoPag()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();

try {
    final result = api_instance.getAllDriversNoPag();
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getAllDriversNoPag: $e\n');
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

# **getAllListDrivers**
> ApiResponsePageResponseDriverDto getAllListDrivers(page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getAllListDrivers(page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getAllListDrivers: $e\n');
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

# **getDeviceToken**
> ApiResponseString getDeviceToken(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDeviceToken(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getDeviceToken: $e\n');
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

# **getDriverById1**
> ApiResponseDriverDto getDriverById1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDriverById1(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getDriverById1: $e\n');
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

# **getDriverLocationHistory**
> ApiResponseListLocationHistoryDto getDriverLocationHistory(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDriverLocationHistory(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getDriverLocationHistory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseListLocationHistoryDto**](ApiResponseListLocationHistoryDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDriverLocationHistoryPaginated**
> ApiResponsePageLocationHistoryDto getDriverLocationHistoryPaginated(driverId, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getDriverLocationHistoryPaginated(driverId, page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getDriverLocationHistoryPaginated: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 20]

### Return type

[**ApiResponsePageLocationHistoryDto**](ApiResponsePageLocationHistoryDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDriverNotifications1**
> ApiResponseMapStringObject getDriverNotifications1(driverId, order, unreadOnly, since, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 
final order = order_example; // String | 
final unreadOnly = true; // bool | 
final since = 2013-10-20T19:20:30+01:00; // DateTime | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getDriverNotifications1(driverId, order, unreadOnly, since, page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getDriverNotifications1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **order** | **String**|  | [optional] [default to 'unreadFirst']
 **unreadOnly** | **bool**|  | [optional] [default to false]
 **since** | **DateTime**|  | [optional] 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 10]

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getVehiclesByDriver**
> ApiResponseListVehicleDto getVehiclesByDriver(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getVehiclesByDriver(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getVehiclesByDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseListVehicleDto**](ApiResponseListVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getVehiclesWithCurrentDrivers**
> ApiResponseListVehicleWithDriverDto getVehiclesWithCurrentDrivers()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();

try {
    final result = api_instance.getVehiclesWithCurrentDrivers();
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->getVehiclesWithCurrentDrivers: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListVehicleWithDriverDto**](ApiResponseListVehicleWithDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **latestForDriver**
> ApiResponseLiveDriverDto latestForDriver(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.latestForDriver(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->latestForDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseLiveDriverDto**](ApiResponseLiveDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **liveDrivers**
> ApiResponseListLiveDriverDto liveDrivers(onlyOnline, onlineSeconds, south, west, north, east)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final onlyOnline = true; // bool | 
final onlineSeconds = 56; // int | 
final south = 1.2; // double | 
final west = 1.2; // double | 
final north = 1.2; // double | 
final east = 1.2; // double | 

try {
    final result = api_instance.liveDrivers(onlyOnline, onlineSeconds, south, west, north, east);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->liveDrivers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **onlyOnline** | **bool**|  | [optional] [default to true]
 **onlineSeconds** | **int**|  | [optional] [default to 120]
 **south** | **double**|  | [optional] 
 **west** | **double**|  | [optional] 
 **north** | **double**|  | [optional] 
 **east** | **double**|  | [optional] 

### Return type

[**ApiResponseListLiveDriverDto**](ApiResponseListLiveDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAllAsRead1**
> ApiResponseString markAllAsRead1(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.markAllAsRead1(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->markAllAsRead1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAsRead1**
> ApiResponseString markAsRead1(driverId, notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 
final notificationId = 789; // int | 

try {
    final result = api_instance.markAsRead1(driverId, notificationId);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->markAsRead1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **notificationId** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAsReadLegacy1**
> ApiResponseString markAsReadLegacy1(notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final notificationId = 789; // int | 

try {
    final result = api_instance.markAsReadLegacy1(notificationId);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->markAsReadLegacy1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **notificationId** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchDrivers1**
> ApiResponseListDriverDto searchDrivers1(query)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final query = query_example; // String | 

try {
    final result = api_instance.searchDrivers1(query);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->searchDrivers1: $e\n');
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

# **sendNotification**
> ApiResponseString sendNotification(createNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final createNotificationRequest = CreateNotificationRequest(); // CreateNotificationRequest | 

try {
    final result = api_instance.sendNotification(createNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->sendNotification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createNotificationRequest** | [**CreateNotificationRequest**](CreateNotificationRequest.md)|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDeviceToken**
> ApiResponseString updateDeviceToken(deviceTokenRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final deviceTokenRequest = DeviceTokenRequest(); // DeviceTokenRequest | 

try {
    final result = api_instance.updateDeviceToken(deviceTokenRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->updateDeviceToken: $e\n');
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

# **updateDriver**
> ApiResponseDriverDto updateDriver(id, driverUpdateRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final id = 789; // int | 
final driverUpdateRequest = DriverUpdateRequest(); // DriverUpdateRequest | 

try {
    final result = api_instance.updateDriver(id, driverUpdateRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->updateDriver: $e\n');
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

# **uploadProfilePictureAdmin**
> ApiResponseString uploadProfilePictureAdmin(driverId, profilePicture)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverVTwoControllerApi();
final driverId = 789; // int | 
final profilePicture = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.uploadProfilePictureAdmin(driverId, profilePicture);
    print(result);
} catch (e) {
    print('Exception when calling DriverVTwoControllerApi->uploadProfilePictureAdmin: $e\n');
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

