# openapi.api.DriverNotificationAdminControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**broadcastNotification1**](DriverNotificationAdminControllerApi.md#broadcastnotification1) | **POST** /api/admin/drivers/broadcast-notification | 
[**deleteDriverNotification3**](DriverNotificationAdminControllerApi.md#deletedrivernotification3) | **DELETE** /api/admin/drivers/{driverId}/notifications/{notificationId} | 
[**forceOpenDriverApp1**](DriverNotificationAdminControllerApi.md#forceopendriverapp1) | **POST** /api/admin/drivers/{driverId}/force-open | 
[**getDriverNotifications3**](DriverNotificationAdminControllerApi.md#getdrivernotifications3) | **GET** /api/admin/drivers/{driverId}/notifications | 
[**markAllAsRead3**](DriverNotificationAdminControllerApi.md#markallasread3) | **PATCH** /api/admin/drivers/{driverId}/notifications/mark-all-read | 
[**markAsRead3**](DriverNotificationAdminControllerApi.md#markasread3) | **PUT** /api/admin/drivers/{driverId}/notifications/{notificationId}/read | 
[**markAsReadLegacy2**](DriverNotificationAdminControllerApi.md#markasreadlegacy2) | **PUT** /api/admin/drivers/notifications/{notificationId}/read | 
[**sendNotification1**](DriverNotificationAdminControllerApi.md#sendnotification1) | **POST** /api/admin/drivers/send-notification | 


# **broadcastNotification1**
> ApiResponseString broadcastNotification1(broadcastNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationAdminControllerApi();
final broadcastNotificationRequest = BroadcastNotificationRequest(); // BroadcastNotificationRequest | 

try {
    final result = api_instance.broadcastNotification1(broadcastNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationAdminControllerApi->broadcastNotification1: $e\n');
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

# **deleteDriverNotification3**
> ApiResponseString deleteDriverNotification3(driverId, notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationAdminControllerApi();
final driverId = 789; // int | 
final notificationId = 789; // int | 

try {
    final result = api_instance.deleteDriverNotification3(driverId, notificationId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationAdminControllerApi->deleteDriverNotification3: $e\n');
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

# **forceOpenDriverApp1**
> ApiResponseString forceOpenDriverApp1(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationAdminControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.forceOpenDriverApp1(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationAdminControllerApi->forceOpenDriverApp1: $e\n');
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

# **getDriverNotifications3**
> ApiResponseMapStringObject getDriverNotifications3(driverId, order, unreadOnly, since, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationAdminControllerApi();
final driverId = 789; // int | 
final order = order_example; // String | 
final unreadOnly = true; // bool | 
final since = 2013-10-20T19:20:30+01:00; // DateTime | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getDriverNotifications3(driverId, order, unreadOnly, since, page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationAdminControllerApi->getDriverNotifications3: $e\n');
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

# **markAllAsRead3**
> ApiResponseString markAllAsRead3(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationAdminControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.markAllAsRead3(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationAdminControllerApi->markAllAsRead3: $e\n');
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

# **markAsRead3**
> ApiResponseString markAsRead3(driverId, notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationAdminControllerApi();
final driverId = 789; // int | 
final notificationId = 789; // int | 

try {
    final result = api_instance.markAsRead3(driverId, notificationId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationAdminControllerApi->markAsRead3: $e\n');
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

# **markAsReadLegacy2**
> ApiResponseString markAsReadLegacy2(notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationAdminControllerApi();
final notificationId = 789; // int | 

try {
    final result = api_instance.markAsReadLegacy2(notificationId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationAdminControllerApi->markAsReadLegacy2: $e\n');
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

# **sendNotification1**
> ApiResponseString sendNotification1(createNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationAdminControllerApi();
final createNotificationRequest = CreateNotificationRequest(); // CreateNotificationRequest | 

try {
    final result = api_instance.sendNotification1(createNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationAdminControllerApi->sendNotification1: $e\n');
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

