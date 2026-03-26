# openapi.api.AuditTrailControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createAuditTrail**](AuditTrailControllerApi.md#createaudittrail) | **POST** /api/admin/audit-trails | 
[**deleteAuditTrail**](AuditTrailControllerApi.md#deleteaudittrail) | **DELETE** /api/admin/audit-trails/{id} | 
[**getAllAuditTrails**](AuditTrailControllerApi.md#getallaudittrails) | **GET** /api/admin/audit-trails | 
[**getAuditTrailsByAction**](AuditTrailControllerApi.md#getaudittrailsbyaction) | **GET** /api/admin/audit-trails/action/{action} | 
[**getAuditTrailsByDateRange**](AuditTrailControllerApi.md#getaudittrailsbydaterange) | **GET** /api/admin/audit-trails/date-range | 
[**getAuditTrailsByResourceType**](AuditTrailControllerApi.md#getaudittrailsbyresourcetype) | **GET** /api/admin/audit-trails/resource/{resourceType} | 
[**getAuditTrailsByUser**](AuditTrailControllerApi.md#getaudittrailsbyuser) | **GET** /api/admin/audit-trails/user/{userId} | 
[**getAuditTrailsByUsername**](AuditTrailControllerApi.md#getaudittrailsbyusername) | **GET** /api/admin/audit-trails/username/{username} | 
[**getAuditTrailsByUsernameAndAction**](AuditTrailControllerApi.md#getaudittrailsbyusernameandaction) | **GET** /api/admin/audit-trails/user/{username}/action/{action} | 


# **createAuditTrail**
> AuditTrail createAuditTrail(auditTrail)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuditTrailControllerApi();
final auditTrail = AuditTrail(); // AuditTrail | 

try {
    final result = api_instance.createAuditTrail(auditTrail);
    print(result);
} catch (e) {
    print('Exception when calling AuditTrailControllerApi->createAuditTrail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **auditTrail** | [**AuditTrail**](AuditTrail.md)|  | 

### Return type

[**AuditTrail**](AuditTrail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteAuditTrail**
> deleteAuditTrail(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuditTrailControllerApi();
final id = 789; // int | 

try {
    api_instance.deleteAuditTrail(id);
} catch (e) {
    print('Exception when calling AuditTrailControllerApi->deleteAuditTrail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllAuditTrails**
> List<AuditTrail> getAllAuditTrails()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuditTrailControllerApi();

try {
    final result = api_instance.getAllAuditTrails();
    print(result);
} catch (e) {
    print('Exception when calling AuditTrailControllerApi->getAllAuditTrails: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<AuditTrail>**](AuditTrail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAuditTrailsByAction**
> List<AuditTrail> getAuditTrailsByAction(action)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuditTrailControllerApi();
final action = action_example; // String | 

try {
    final result = api_instance.getAuditTrailsByAction(action);
    print(result);
} catch (e) {
    print('Exception when calling AuditTrailControllerApi->getAuditTrailsByAction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **action** | **String**|  | 

### Return type

[**List<AuditTrail>**](AuditTrail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAuditTrailsByDateRange**
> List<AuditTrail> getAuditTrailsByDateRange(startDate, endDate)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuditTrailControllerApi();
final startDate = startDate_example; // String | 
final endDate = endDate_example; // String | 

try {
    final result = api_instance.getAuditTrailsByDateRange(startDate, endDate);
    print(result);
} catch (e) {
    print('Exception when calling AuditTrailControllerApi->getAuditTrailsByDateRange: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **startDate** | **String**|  | 
 **endDate** | **String**|  | 

### Return type

[**List<AuditTrail>**](AuditTrail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAuditTrailsByResourceType**
> List<AuditTrail> getAuditTrailsByResourceType(resourceType)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuditTrailControllerApi();
final resourceType = resourceType_example; // String | 

try {
    final result = api_instance.getAuditTrailsByResourceType(resourceType);
    print(result);
} catch (e) {
    print('Exception when calling AuditTrailControllerApi->getAuditTrailsByResourceType: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resourceType** | **String**|  | 

### Return type

[**List<AuditTrail>**](AuditTrail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAuditTrailsByUser**
> List<AuditTrail> getAuditTrailsByUser(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuditTrailControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.getAuditTrailsByUser(userId);
    print(result);
} catch (e) {
    print('Exception when calling AuditTrailControllerApi->getAuditTrailsByUser: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

[**List<AuditTrail>**](AuditTrail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAuditTrailsByUsername**
> List<AuditTrail> getAuditTrailsByUsername(username)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuditTrailControllerApi();
final username = username_example; // String | 

try {
    final result = api_instance.getAuditTrailsByUsername(username);
    print(result);
} catch (e) {
    print('Exception when calling AuditTrailControllerApi->getAuditTrailsByUsername: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **username** | **String**|  | 

### Return type

[**List<AuditTrail>**](AuditTrail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAuditTrailsByUsernameAndAction**
> List<AuditTrail> getAuditTrailsByUsernameAndAction(username, action)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuditTrailControllerApi();
final username = username_example; // String | 
final action = action_example; // String | 

try {
    final result = api_instance.getAuditTrailsByUsernameAndAction(username, action);
    print(result);
} catch (e) {
    print('Exception when calling AuditTrailControllerApi->getAuditTrailsByUsernameAndAction: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **username** | **String**|  | 
 **action** | **String**|  | 

### Return type

[**List<AuditTrail>**](AuditTrail.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

