# openapi.api.NotificationControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**broadcast**](NotificationControllerApi.md#broadcast) | **POST** /api/notifications/driver/broadcast | 
[**countDriverUnread**](NotificationControllerApi.md#countdriverunread) | **GET** /api/notifications/driver/{driverId}/count | 
[**countUnreadAdminNotifications**](NotificationControllerApi.md#countunreadadminnotifications) | **GET** /api/notifications/admin/count | 
[**countUnreadsAdminNotifications**](NotificationControllerApi.md#countunreadsadminnotifications) | **GET** /api/notifications/admin/unread | 
[**createAdminNotification**](NotificationControllerApi.md#createadminnotification) | **POST** /api/notifications/admin/create | 
[**deleteAdminNotification**](NotificationControllerApi.md#deleteadminnotification) | **DELETE** /api/notifications/admin/{id} | 
[**deleteAllAdminNotifications**](NotificationControllerApi.md#deletealladminnotifications) | **DELETE** /api/notifications/admin/all | 
[**deleteAllForDriver**](NotificationControllerApi.md#deleteallfordriver) | **DELETE** /api/notifications/driver/{driverId}/all | 
[**deleteBatchForDriver**](NotificationControllerApi.md#deletebatchfordriver) | **DELETE** /api/notifications/driver/{driverId}/batch | 
[**deleteDriverNotification**](NotificationControllerApi.md#deletedrivernotification) | **DELETE** /api/notifications/driver/{driverId}/{notificationId} | 
[**deleteDriverNotificationLegacy**](NotificationControllerApi.md#deletedrivernotificationlegacy) | **DELETE** /api/notifications/driver/{notificationId} | 
[**deleteReadForDriver**](NotificationControllerApi.md#deletereadfordriver) | **DELETE** /api/notifications/driver/{driverId}/delete-read | 
[**getAllAdminNotifications**](NotificationControllerApi.md#getalladminnotifications) | **GET** /api/notifications/admin | 
[**getDriverNotifications**](NotificationControllerApi.md#getdrivernotifications) | **GET** /api/notifications/driver/{driverId} | 
[**markAdminAsRead**](NotificationControllerApi.md#markadminasread) | **PUT** /api/notifications/admin/{id}/read | 
[**markAllAdminAsRead**](NotificationControllerApi.md#markalladminasread) | **PATCH** /api/notifications/admin/mark-all-read | 
[**markAllAsRead**](NotificationControllerApi.md#markallasread) | **PATCH** /api/notifications/driver/{driverId}/mark-all-read | 
[**markAsRead**](NotificationControllerApi.md#markasread) | **PUT** /api/notifications/driver/{driverId}/{notificationId}/read | 
[**markAsReadLegacy**](NotificationControllerApi.md#markasreadlegacy) | **PUT** /api/notifications/driver/{notificationId}/read | 
[**sendToDriver**](NotificationControllerApi.md#sendtodriver) | **POST** /api/notifications/driver/send | 


# **broadcast**
> ApiResponseString broadcast(broadcastNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final broadcastNotificationRequest = BroadcastNotificationRequest(); // BroadcastNotificationRequest | 

try {
    final result = api_instance.broadcast(broadcastNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->broadcast: $e\n');
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

# **countDriverUnread**
> ApiResponseLong countDriverUnread(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.countDriverUnread(driverId);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->countDriverUnread: $e\n');
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

# **countUnreadAdminNotifications**
> ApiResponseLong countUnreadAdminNotifications()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();

try {
    final result = api_instance.countUnreadAdminNotifications();
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->countUnreadAdminNotifications: $e\n');
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

# **countUnreadsAdminNotifications**
> ApiResponseLong countUnreadsAdminNotifications()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();

try {
    final result = api_instance.countUnreadsAdminNotifications();
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->countUnreadsAdminNotifications: $e\n');
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

# **createAdminNotification**
> ApiResponseString createAdminNotification(createNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final createNotificationRequest = CreateNotificationRequest(); // CreateNotificationRequest | 

try {
    final result = api_instance.createAdminNotification(createNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->createAdminNotification: $e\n');
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

# **deleteAdminNotification**
> ApiResponseString deleteAdminNotification(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteAdminNotification(id);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->deleteAdminNotification: $e\n');
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

# **deleteAllAdminNotifications**
> ApiResponseString deleteAllAdminNotifications()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();

try {
    final result = api_instance.deleteAllAdminNotifications();
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->deleteAllAdminNotifications: $e\n');
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

# **deleteAllForDriver**
> ApiResponseString deleteAllForDriver(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.deleteAllForDriver(driverId);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->deleteAllForDriver: $e\n');
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

# **deleteBatchForDriver**
> ApiResponseString deleteBatchForDriver(driverId, idsPayload)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final driverId = 789; // int | 
final idsPayload = IdsPayload(); // IdsPayload | 

try {
    final result = api_instance.deleteBatchForDriver(driverId, idsPayload);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->deleteBatchForDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **idsPayload** | [**IdsPayload**](IdsPayload.md)|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDriverNotification**
> ApiResponseString deleteDriverNotification(driverId, notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final driverId = 789; // int | 
final notificationId = 789; // int | 

try {
    final result = api_instance.deleteDriverNotification(driverId, notificationId);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->deleteDriverNotification: $e\n');
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

# **deleteDriverNotificationLegacy**
> ApiResponseString deleteDriverNotificationLegacy(notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final notificationId = 789; // int | 

try {
    final result = api_instance.deleteDriverNotificationLegacy(notificationId);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->deleteDriverNotificationLegacy: $e\n');
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

# **deleteReadForDriver**
> ApiResponseString deleteReadForDriver(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.deleteReadForDriver(driverId);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->deleteReadForDriver: $e\n');
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

# **getAllAdminNotifications**
> ApiResponseListNotificationDTO getAllAdminNotifications()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();

try {
    final result = api_instance.getAllAdminNotifications();
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->getAllAdminNotifications: $e\n');
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

# **getDriverNotifications**
> ApiResponseMapStringObject getDriverNotifications(driverId, order, unreadOnly, since, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final driverId = 789; // int | 
final order = order_example; // String | 
final unreadOnly = true; // bool | 
final since = 2013-10-20T19:20:30+01:00; // DateTime | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getDriverNotifications(driverId, order, unreadOnly, since, page, size);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->getDriverNotifications: $e\n');
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

# **markAdminAsRead**
> ApiResponseString markAdminAsRead(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.markAdminAsRead(id);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->markAdminAsRead: $e\n');
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

# **markAllAdminAsRead**
> ApiResponseString markAllAdminAsRead()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();

try {
    final result = api_instance.markAllAdminAsRead();
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->markAllAdminAsRead: $e\n');
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

# **markAllAsRead**
> ApiResponseString markAllAsRead(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.markAllAsRead(driverId);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->markAllAsRead: $e\n');
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

# **markAsRead**
> ApiResponseString markAsRead(driverId, notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final driverId = 789; // int | 
final notificationId = 789; // int | 

try {
    final result = api_instance.markAsRead(driverId, notificationId);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->markAsRead: $e\n');
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

# **markAsReadLegacy**
> ApiResponseString markAsReadLegacy(notificationId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final notificationId = 789; // int | 

try {
    final result = api_instance.markAsReadLegacy(notificationId);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->markAsReadLegacy: $e\n');
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

# **sendToDriver**
> ApiResponseString sendToDriver(createNotificationRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = NotificationControllerApi();
final createNotificationRequest = CreateNotificationRequest(); // CreateNotificationRequest | 

try {
    final result = api_instance.sendToDriver(createNotificationRequest);
    print(result);
} catch (e) {
    print('Exception when calling NotificationControllerApi->sendToDriver: $e\n');
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

