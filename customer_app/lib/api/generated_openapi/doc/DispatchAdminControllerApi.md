# openapi.api.DispatchAdminControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptDispatch1**](DispatchAdminControllerApi.md#acceptdispatch1) | **POST** /api/admin/dispatches/{id}/accept | 
[**assignDispatch1**](DispatchAdminControllerApi.md#assigndispatch1) | **POST** /api/admin/dispatches/{id}/assign | 
[**assignDriverOnly1**](DispatchAdminControllerApi.md#assigndriveronly1) | **POST** /api/admin/dispatches/{id}/assign-driver | 
[**assignTruckOnly1**](DispatchAdminControllerApi.md#assigntruckonly1) | **POST** /api/admin/dispatches/{id}/assign-truck | 
[**changeDriver1**](DispatchAdminControllerApi.md#changedriver1) | **PUT** /api/admin/dispatches/{id}/change-driver | 
[**changeTruck1**](DispatchAdminControllerApi.md#changetruck1) | **PUT** /api/admin/dispatches/{id}/change-truck | 
[**createDispatch1**](DispatchAdminControllerApi.md#createdispatch1) | **POST** /api/admin/dispatches | 
[**deleteDispatch1**](DispatchAdminControllerApi.md#deletedispatch1) | **DELETE** /api/admin/dispatches/{id} | 
[**driverSubmitLoadProof1**](DispatchAdminControllerApi.md#driversubmitloadproof1) | **POST** /api/admin/dispatches/driver/load-proof/{dispatchId}/load | 
[**filterDispatches1**](DispatchAdminControllerApi.md#filterdispatches1) | **GET** /api/admin/dispatches/filter | 
[**getAllDispatches1**](DispatchAdminControllerApi.md#getalldispatches1) | **GET** /api/admin/dispatches | 
[**getDispatchById1**](DispatchAdminControllerApi.md#getdispatchbyid1) | **GET** /api/admin/dispatches/{id} | 
[**getDispatchStatusHistory1**](DispatchAdminControllerApi.md#getdispatchstatushistory1) | **GET** /api/admin/dispatches/{id}/status-history | 
[**getDispatchesByDriverWithDateRange1**](DispatchAdminControllerApi.md#getdispatchesbydriverwithdaterange1) | **GET** /api/admin/dispatches/driver/{driverId} | 
[**getDispatchesByDriverWithStatusFilter1**](DispatchAdminControllerApi.md#getdispatchesbydriverwithstatusfilter1) | **GET** /api/admin/dispatches/driver/{driverId}/status | 
[**getFilteredLoadProofs1**](DispatchAdminControllerApi.md#getfilteredloadproofs1) | **GET** /api/admin/dispatches/proofs/load | 
[**importBulkDispatches1**](DispatchAdminControllerApi.md#importbulkdispatches1) | **POST** /api/admin/dispatches/import-bulk | 
[**markAsUnloaded1**](DispatchAdminControllerApi.md#markasunloaded1) | **POST** /api/admin/dispatches/{dispatchId}/unload | 
[**notifyAssignedDriver1**](DispatchAdminControllerApi.md#notifyassigneddriver1) | **POST** /api/admin/dispatches/{id}/notify-assigned-driver | 
[**planTrip1**](DispatchAdminControllerApi.md#plantrip1) | **POST** /api/admin/dispatches/plan-trip | 
[**rejectDispatch1**](DispatchAdminControllerApi.md#rejectdispatch1) | **POST** /api/admin/dispatches/{id}/reject | 
[**submitLoadProof1**](DispatchAdminControllerApi.md#submitloadproof1) | **POST** /api/admin/dispatches/{dispatchId}/load | 
[**submitUnloadProof1**](DispatchAdminControllerApi.md#submitunloadproof1) | **POST** /api/admin/dispatches/driver/unload-proof/{dispatchId}/unload | 
[**updateDispatch1**](DispatchAdminControllerApi.md#updatedispatch1) | **PUT** /api/admin/dispatches/{id} | 
[**updateDispatchStatus1**](DispatchAdminControllerApi.md#updatedispatchstatus1) | **PATCH** /api/admin/dispatches/{id}/status | 


# **acceptDispatch1**
> ApiResponseDispatchDto acceptDispatch1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.acceptDispatch1(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->acceptDispatch1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assignDispatch1**
> ApiResponseDispatchDto assignDispatch1(id, driverId, vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 
final driverId = 789; // int | 
final vehicleId = 789; // int | 

try {
    final result = api_instance.assignDispatch1(id, driverId, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->assignDispatch1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **driverId** | **int**|  | 
 **vehicleId** | **int**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assignDriverOnly1**
> ApiResponseDispatchDto assignDriverOnly1(id, driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 
final driverId = 789; // int | 

try {
    final result = api_instance.assignDriverOnly1(id, driverId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->assignDriverOnly1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **driverId** | **int**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assignTruckOnly1**
> ApiResponseDispatchDto assignTruckOnly1(id, vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 
final vehicleId = 789; // int | 

try {
    final result = api_instance.assignTruckOnly1(id, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->assignTruckOnly1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **vehicleId** | **int**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **changeDriver1**
> ApiResponseDispatchDto changeDriver1(id, driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 
final driverId = 789; // int | 

try {
    final result = api_instance.changeDriver1(id, driverId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->changeDriver1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **driverId** | **int**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **changeTruck1**
> ApiResponseDispatchDto changeTruck1(id, vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 
final vehicleId = 789; // int | 

try {
    final result = api_instance.changeTruck1(id, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->changeTruck1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **vehicleId** | **int**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createDispatch1**
> ApiResponseDispatchDto createDispatch1(dispatchDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final dispatchDto = DispatchDto(); // DispatchDto | 

try {
    final result = api_instance.createDispatch1(dispatchDto);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->createDispatch1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dispatchDto** | [**DispatchDto**](DispatchDto.md)|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDispatch1**
> ApiResponseVoid deleteDispatch1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteDispatch1(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->deleteDispatch1: $e\n');
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

# **driverSubmitLoadProof1**
> ApiResponseLoadProofDto driverSubmitLoadProof1(dispatchId, images, remarks, signature)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final dispatchId = 789; // int | 
final images = [/path/to/file.txt]; // List<MultipartFile> | 
final remarks = remarks_example; // String | 
final signature = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.driverSubmitLoadProof1(dispatchId, images, remarks, signature);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->driverSubmitLoadProof1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dispatchId** | **int**|  | 
 **images** | [**List<MultipartFile>**](MultipartFile.md)|  | 
 **remarks** | **String**|  | [optional] 
 **signature** | **MultipartFile**|  | [optional] 

### Return type

[**ApiResponseLoadProofDto**](ApiResponseLoadProofDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **filterDispatches1**
> ApiResponsePageDispatchDto filterDispatches1(pageable, driverId, vehicleId, status, driverName, routeCode, q, customerName, destinationTo, truckPlate, tripNo, start, end)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final pageable = ; // Pageable | 
final driverId = 789; // int | 
final vehicleId = 789; // int | 
final status = status_example; // String | 
final driverName = driverName_example; // String | 
final routeCode = routeCode_example; // String | 
final q = q_example; // String | 
final customerName = customerName_example; // String | 
final destinationTo = destinationTo_example; // String | 
final truckPlate = truckPlate_example; // String | 
final tripNo = tripNo_example; // String | 
final start = 2013-10-20T19:20:30+01:00; // DateTime | 
final end = 2013-10-20T19:20:30+01:00; // DateTime | 

try {
    final result = api_instance.filterDispatches1(pageable, driverId, vehicleId, status, driverName, routeCode, q, customerName, destinationTo, truckPlate, tripNo, start, end);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->filterDispatches1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 
 **driverId** | **int**|  | [optional] 
 **vehicleId** | **int**|  | [optional] 
 **status** | **String**|  | [optional] 
 **driverName** | **String**|  | [optional] 
 **routeCode** | **String**|  | [optional] 
 **q** | **String**|  | [optional] 
 **customerName** | **String**|  | [optional] 
 **destinationTo** | **String**|  | [optional] 
 **truckPlate** | **String**|  | [optional] 
 **tripNo** | **String**|  | [optional] 
 **start** | **DateTime**|  | [optional] 
 **end** | **DateTime**|  | [optional] 

### Return type

[**ApiResponsePageDispatchDto**](ApiResponsePageDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllDispatches1**
> ApiResponsePageDispatchDto getAllDispatches1(pageable)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final pageable = ; // Pageable | 

try {
    final result = api_instance.getAllDispatches1(pageable);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->getAllDispatches1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 

### Return type

[**ApiResponsePageDispatchDto**](ApiResponsePageDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDispatchById1**
> ApiResponseDispatchDto getDispatchById1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDispatchById1(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->getDispatchById1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDispatchStatusHistory1**
> ApiResponseListDispatchStatusHistoryDto getDispatchStatusHistory1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDispatchStatusHistory1(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->getDispatchStatusHistory1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseListDispatchStatusHistoryDto**](ApiResponseListDispatchStatusHistoryDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDispatchesByDriverWithDateRange1**
> PageDispatchDto getDispatchesByDriverWithDateRange1(driverId, pageable, from, to)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final driverId = 789; // int | 
final pageable = ; // Pageable | 
final from = 2013-10-20; // DateTime | 
final to = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getDispatchesByDriverWithDateRange1(driverId, pageable, from, to);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->getDispatchesByDriverWithDateRange1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **pageable** | [**Pageable**](.md)|  | 
 **from** | **DateTime**|  | [optional] 
 **to** | **DateTime**|  | [optional] 

### Return type

[**PageDispatchDto**](PageDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDispatchesByDriverWithStatusFilter1**
> PageDispatchDto getDispatchesByDriverWithStatusFilter1(driverId, pageable, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final driverId = 789; // int | 
final pageable = ; // Pageable | 
final status = status_example; // String | 

try {
    final result = api_instance.getDispatchesByDriverWithStatusFilter1(driverId, pageable, status);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->getDispatchesByDriverWithStatusFilter1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **pageable** | [**Pageable**](.md)|  | 
 **status** | **String**|  | [optional] 

### Return type

[**PageDispatchDto**](PageDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFilteredLoadProofs1**
> ApiResponseListLoadProofDto getFilteredLoadProofs1(search, driver, route, from, to)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final search = search_example; // String | 
final driver = driver_example; // String | 
final route = route_example; // String | 
final from = 2013-10-20; // DateTime | 
final to = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getFilteredLoadProofs1(search, driver, route, from, to);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->getFilteredLoadProofs1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**|  | [optional] 
 **driver** | **String**|  | [optional] 
 **route** | **String**|  | [optional] 
 **from** | **DateTime**|  | [optional] 
 **to** | **DateTime**|  | [optional] 

### Return type

[**ApiResponseListLoadProofDto**](ApiResponseListLoadProofDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **importBulkDispatches1**
> ApiResponseString importBulkDispatches1(file)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.importBulkDispatches1(file);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->importBulkDispatches1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **MultipartFile**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markAsUnloaded1**
> Object markAsUnloaded1(dispatchId, remarks, address, latitude, longitude, markAsUnloadedRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final dispatchId = 789; // int | 
final remarks = remarks_example; // String | 
final address = address_example; // String | 
final latitude = 1.2; // double | 
final longitude = 1.2; // double | 
final markAsUnloadedRequest = MarkAsUnloadedRequest(); // MarkAsUnloadedRequest | 

try {
    final result = api_instance.markAsUnloaded1(dispatchId, remarks, address, latitude, longitude, markAsUnloadedRequest);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->markAsUnloaded1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dispatchId** | **int**|  | 
 **remarks** | **String**|  | [optional] 
 **address** | **String**|  | [optional] 
 **latitude** | **double**|  | [optional] 
 **longitude** | **double**|  | [optional] 
 **markAsUnloadedRequest** | [**MarkAsUnloadedRequest**](MarkAsUnloadedRequest.md)|  | [optional] 

### Return type

**Object**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **notifyAssignedDriver1**
> ApiResponseDispatchDto notifyAssignedDriver1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.notifyAssignedDriver1(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->notifyAssignedDriver1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **planTrip1**
> ApiResponseDispatchDto planTrip1(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.planTrip1(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->planTrip1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestBody** | [**Map<String, Object>**](Object.md)|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rejectDispatch1**
> ApiResponseDispatchDto rejectDispatch1(id, reason)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 
final reason = reason_example; // String | 

try {
    final result = api_instance.rejectDispatch1(id, reason);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->rejectDispatch1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **reason** | **String**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitLoadProof1**
> ApiResponseLoadProofDto submitLoadProof1(dispatchId, images, remarks, signature)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final dispatchId = 789; // int | 
final images = [/path/to/file.txt]; // List<MultipartFile> | 
final remarks = remarks_example; // String | 
final signature = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.submitLoadProof1(dispatchId, images, remarks, signature);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->submitLoadProof1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dispatchId** | **int**|  | 
 **images** | [**List<MultipartFile>**](MultipartFile.md)|  | 
 **remarks** | **String**|  | [optional] 
 **signature** | **MultipartFile**|  | [optional] 

### Return type

[**ApiResponseLoadProofDto**](ApiResponseLoadProofDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitUnloadProof1**
> ApiResponseUnloadProofDto submitUnloadProof1(dispatchId, remarks, address, latitude, longitude, images, signature)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final dispatchId = 789; // int | 
final remarks = remarks_example; // String | 
final address = address_example; // String | 
final latitude = 1.2; // double | 
final longitude = 1.2; // double | 
final images = [/path/to/file.txt]; // List<MultipartFile> | 
final signature = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.submitUnloadProof1(dispatchId, remarks, address, latitude, longitude, images, signature);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->submitUnloadProof1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dispatchId** | **int**|  | 
 **remarks** | **String**|  | [optional] 
 **address** | **String**|  | [optional] 
 **latitude** | **double**|  | [optional] 
 **longitude** | **double**|  | [optional] 
 **images** | [**List<MultipartFile>**](MultipartFile.md)|  | [optional] 
 **signature** | **MultipartFile**|  | [optional] 

### Return type

[**ApiResponseUnloadProofDto**](ApiResponseUnloadProofDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDispatch1**
> ApiResponseDispatchDto updateDispatch1(id, dispatchDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 
final dispatchDto = DispatchDto(); // DispatchDto | 

try {
    final result = api_instance.updateDispatch1(id, dispatchDto);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->updateDispatch1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **dispatchDto** | [**DispatchDto**](DispatchDto.md)|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDispatchStatus1**
> ApiResponseDispatchDto updateDispatchStatus1(id, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchAdminControllerApi();
final id = 789; // int | 
final status = status_example; // String | 

try {
    final result = api_instance.updateDispatchStatus1(id, status);
    print(result);
} catch (e) {
    print('Exception when calling DispatchAdminControllerApi->updateDispatchStatus1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **status** | **String**|  | 

### Return type

[**ApiResponseDispatchDto**](ApiResponseDispatchDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

