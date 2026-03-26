# openapi.api.DriverNotificationControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**broadcast1**](DriverNotificationControllerApi.md#broadcast1) | **POST** /api/admin/notifications/driver/broadcast | 
[**countDriverUnread1**](DriverNotificationControllerApi.md#countdriverunread1) | **GET** /api/admin/notifications/driver/{driverId}/count | 
[**countUnreadAdminNotifications1**](DriverNotificationControllerApi.md#countunreadadminnotifications1) | **GET** /api/admin/notifications/admin/count | 
[**countUnreadsAdminNotifications1**](DriverNotificationControllerApi.md#countunreadsadminnotifications1) | **GET** /api/admin/notifications/admin/unread | 
[**createAdminNotification1**](DriverNotificationControllerApi.md#createadminnotification1) | **POST** /api/admin/notifications/admin/create | 
[**deleteAdminNotification1**](DriverNotificationControllerApi.md#deleteadminnotification1) | **DELETE** /api/admin/notifications/admin/{id} | 
[**deleteAllAdminNotifications1**](DriverNotificationControllerApi.md#deletealladminnotifications1) | **DELETE** /api/admin/notifications/admin/all | 
[**deleteAllForDriver1**](DriverNotificationControllerApi.md#deleteallfordriver1) | **DELETE** /api/admin/notifications/driver/{driverId}/all | 
[**deleteDriverNotification2**](DriverNotificationControllerApi.md#deletedrivernotification2) | **DELETE** /api/admin/notifications/driver/{driverId}/{notificationId} | 
[**getAllAdminNotifications1**](DriverNotificationControllerApi.md#getalladminnotifications1) | **GET** /api/admin/notifications/admin | 
[**getDriverNotifications2**](DriverNotificationControllerApi.md#getdrivernotifications2) | **GET** /api/admin/notifications/driver/{driverId} | 
[**markAdminAsRead1**](DriverNotificationControllerApi.md#markadminasread1) | **PUT** /api/admin/notifications/admin/{id}/read | 
[**markAllAdminAsRead1**](DriverNotificationControllerApi.md#markalladminasread1) | **PATCH** /api/admin/notifications/admin/mark-all-read | 
[**markAllAsRead2**](DriverNotificationControllerApi.md#markallasread2) | **PATCH** /api/admin/notifications/driver/{driverId}/mark-all-read | 
[**markAsRead2**](DriverNotificationControllerApi.md#markasread2) | **PUT** /api/admin/notifications/driver/{driverId}/{notificationId}/read | 
[**sendToDriver1**](DriverNotificationControllerApi.md#sendtodriver1) | **POST** /api/admin/notifications/driver/send | 


# **broadcast1**
> ApiResponseString broadcast1(broadcastNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final broadcastNotificationRequest = BroadcastNotificationRequest(); // BroadcastNotificationRequest | 

try {
    final result = api_instance.broadcast1(broadcastNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->broadcast1: $e\n');
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

# **countDriverUnread1**
> ApiResponseLong countDriverUnread1(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.countDriverUnread1(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->countDriverUnread1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseLong**](ApiResponseLong.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **countUnreadAdminNotifications1**
> ApiResponseLong countUnreadAdminNotifications1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();

try {
    final result = api_instance.countUnreadAdminNotifications1();
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->countUnreadAdminNotifications1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseLong**](ApiResponseLong.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **countUnreadsAdminNotifications1**
> ApiResponseLong countUnreadsAdminNotifications1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();

try {
    final result = api_instance.countUnreadsAdminNotifications1();
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->countUnreadsAdminNotifications1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseLong**](ApiResponseLong.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createAdminNotification1**
> ApiResponseString createAdminNotification1(createNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final createNotificationRequest = CreateNotificationRequest(); // CreateNotificationRequest | 

try {
    final result = api_instance.createAdminNotification1(createNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->createAdminNotification1: $e\n');
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

# **deleteAdminNotification1**
> ApiResponseString deleteAdminNotification1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteAdminNotification1(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->deleteAdminNotification1: $e\n');
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

# **deleteAllAdminNotifications1**
> ApiResponseString deleteAllAdminNotifications1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();

try {
    final result = api_instance.deleteAllAdminNotifications1();
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->deleteAllAdminNotifications1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteAllForDriver1**
> ApiResponseString deleteAllForDriver1(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.deleteAllForDriver1(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->deleteAllForDriver1: $e\n');
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

# **deleteDriverNotification2**
> ApiResponseString deleteDriverNotification2(driverId, notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final driverId = 789; // int | 
final notificationId = 789; // int | 

try {
    final result = api_instance.deleteDriverNotification2(driverId, notificationId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->deleteDriverNotification2: $e\n');
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

# **getAllAdminNotifications1**
> ApiResponseListNotificationDTO getAllAdminNotifications1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();

try {
    final result = api_instance.getAllAdminNotifications1();
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->getAllAdminNotifications1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListNotificationDTO**](ApiResponseListNotificationDTO.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDriverNotifications2**
> ApiResponsePageNotificationDTO getDriverNotifications2(driverId, order, unreadOnly, since, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final driverId = 789; // int | 
final order = order_example; // String | 
final unreadOnly = true; // bool | 
final since = 2013-10-20T19:20:30+01:00; // DateTime | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getDriverNotifications2(driverId, order, unreadOnly, since, page, size);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->getDriverNotifications2: $e\n');
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

[**ApiResponsePageNotificationDTO**](ApiResponsePageNotificationDTO.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAdminAsRead1**
> ApiResponseString markAdminAsRead1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.markAdminAsRead1(id);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->markAdminAsRead1: $e\n');
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

# **markAllAdminAsRead1**
> ApiResponseString markAllAdminAsRead1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();

try {
    final result = api_instance.markAllAdminAsRead1();
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->markAllAdminAsRead1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAllAsRead2**
> ApiResponseString markAllAsRead2(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.markAllAsRead2(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->markAllAsRead2: $e\n');
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

# **markAsRead2**
> ApiResponseString markAsRead2(driverId, notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final driverId = 789; // int | 
final notificationId = 789; // int | 

try {
    final result = api_instance.markAsRead2(driverId, notificationId);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->markAsRead2: $e\n');
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

# **sendToDriver1**
> ApiResponseString sendToDriver1(createNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverNotificationControllerApi();
final createNotificationRequest = CreateNotificationRequest(); // CreateNotificationRequest | 

try {
    final result = api_instance.sendToDriver1(createNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverNotificationControllerApi->sendToDriver1: $e\n');
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

