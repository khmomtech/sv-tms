# openapi.api.DispatchControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptDispatch**](DispatchControllerApi.md#acceptdispatch) | **POST** /api/driver/dispatches/{id}/accept | 
[**assignDispatch**](DispatchControllerApi.md#assigndispatch) | **POST** /api/driver/dispatches/{id}/assign | 
[**assignDriverOnly**](DispatchControllerApi.md#assigndriveronly) | **POST** /api/driver/dispatches/{id}/assign-driver | 
[**assignTruckOnly**](DispatchControllerApi.md#assigntruckonly) | **POST** /api/driver/dispatches/{id}/assign-truck | 
[**changeDriver**](DispatchControllerApi.md#changedriver) | **PUT** /api/driver/dispatches/{id}/change-driver | 
[**changeTruck**](DispatchControllerApi.md#changetruck) | **PUT** /api/driver/dispatches/{id}/change-truck | 
[**createDispatch**](DispatchControllerApi.md#createdispatch) | **POST** /api/driver/dispatches | 
[**deleteDispatch**](DispatchControllerApi.md#deletedispatch) | **DELETE** /api/driver/dispatches/{id} | 
[**driverSubmitLoadProof**](DispatchControllerApi.md#driversubmitloadproof) | **POST** /api/driver/dispatches/driver/load-proof/{dispatchId}/load | 
[**filterDispatches**](DispatchControllerApi.md#filterdispatches) | **GET** /api/driver/dispatches/filter | 
[**getAllDispatches**](DispatchControllerApi.md#getalldispatches) | **GET** /api/driver/dispatches | 
[**getDispatchById**](DispatchControllerApi.md#getdispatchbyid) | **GET** /api/driver/dispatches/{id} | 
[**getDispatchStatusHistory**](DispatchControllerApi.md#getdispatchstatushistory) | **GET** /api/driver/dispatches/{id}/status-history | 
[**getDispatchesByDriverWithDateRange**](DispatchControllerApi.md#getdispatchesbydriverwithdaterange) | **GET** /api/driver/dispatches/driver/{driverId} | 
[**getDispatchesByDriverWithStatusFilter**](DispatchControllerApi.md#getdispatchesbydriverwithstatusfilter) | **GET** /api/driver/dispatches/driver/{driverId}/status | 
[**getFilteredLoadProofs**](DispatchControllerApi.md#getfilteredloadproofs) | **GET** /api/driver/dispatches/proofs/load | 
[**importBulkDispatches**](DispatchControllerApi.md#importbulkdispatches) | **POST** /api/driver/dispatches/import-bulk | 
[**markAsUnloaded**](DispatchControllerApi.md#markasunloaded) | **POST** /api/driver/dispatches/{dispatchId}/unload | 
[**notifyAssignedDriver**](DispatchControllerApi.md#notifyassigneddriver) | **POST** /api/driver/dispatches/{id}/notify-assigned-driver | 
[**planTrip**](DispatchControllerApi.md#plantrip) | **POST** /api/driver/dispatches/plan-trip | 
[**rejectDispatch**](DispatchControllerApi.md#rejectdispatch) | **POST** /api/driver/dispatches/{id}/reject | 
[**submitLoadProof**](DispatchControllerApi.md#submitloadproof) | **POST** /api/driver/dispatches/{dispatchId}/load | 
[**submitUnloadProof**](DispatchControllerApi.md#submitunloadproof) | **POST** /api/driver/dispatches/driver/unload-proof/{dispatchId}/unload | 
[**updateDispatch**](DispatchControllerApi.md#updatedispatch) | **PUT** /api/driver/dispatches/{id} | 
[**updateDispatchStatus**](DispatchControllerApi.md#updatedispatchstatus) | **PATCH** /api/driver/dispatches/{id}/status | 


# **acceptDispatch**
> ApiResponseDispatchDto acceptDispatch(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.acceptDispatch(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->acceptDispatch: $e\n');
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

# **assignDispatch**
> ApiResponseDispatchDto assignDispatch(id, driverId, vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 
final driverId = 789; // int | 
final vehicleId = 789; // int | 

try {
    final result = api_instance.assignDispatch(id, driverId, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->assignDispatch: $e\n');
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

# **assignDriverOnly**
> ApiResponseDispatchDto assignDriverOnly(id, driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 
final driverId = 789; // int | 

try {
    final result = api_instance.assignDriverOnly(id, driverId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->assignDriverOnly: $e\n');
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

# **assignTruckOnly**
> ApiResponseDispatchDto assignTruckOnly(id, vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 
final vehicleId = 789; // int | 

try {
    final result = api_instance.assignTruckOnly(id, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->assignTruckOnly: $e\n');
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

# **changeDriver**
> ApiResponseDispatchDto changeDriver(id, driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 
final driverId = 789; // int | 

try {
    final result = api_instance.changeDriver(id, driverId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->changeDriver: $e\n');
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

# **changeTruck**
> ApiResponseDispatchDto changeTruck(id, vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 
final vehicleId = 789; // int | 

try {
    final result = api_instance.changeTruck(id, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->changeTruck: $e\n');
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

# **createDispatch**
> ApiResponseDispatchDto createDispatch(dispatchDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final dispatchDto = DispatchDto(); // DispatchDto | 

try {
    final result = api_instance.createDispatch(dispatchDto);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->createDispatch: $e\n');
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

# **deleteDispatch**
> ApiResponseVoid deleteDispatch(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteDispatch(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->deleteDispatch: $e\n');
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

# **driverSubmitLoadProof**
> ApiResponseLoadProofDto driverSubmitLoadProof(dispatchId, remarks, images, signature)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final dispatchId = 789; // int | 
final remarks = remarks_example; // String | 
final images = [/path/to/file.txt]; // List<MultipartFile> | 
final signature = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.driverSubmitLoadProof(dispatchId, remarks, images, signature);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->driverSubmitLoadProof: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dispatchId** | **int**|  | 
 **remarks** | **String**|  | [optional] 
 **images** | [**List<MultipartFile>**](MultipartFile.md)|  | [optional] 
 **signature** | **MultipartFile**|  | [optional] 

### Return type

[**ApiResponseLoadProofDto**](ApiResponseLoadProofDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **filterDispatches**
> ApiResponsePageDispatchDto filterDispatches(pageable, driverId, vehicleId, status, driverName, routeCode, q, customerName, destinationTo, truckPlate, tripNo, start, end)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
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
    final result = api_instance.filterDispatches(pageable, driverId, vehicleId, status, driverName, routeCode, q, customerName, destinationTo, truckPlate, tripNo, start, end);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->filterDispatches: $e\n');
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

# **getAllDispatches**
> ApiResponsePageDispatchDto getAllDispatches(pageable)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final pageable = ; // Pageable | 

try {
    final result = api_instance.getAllDispatches(pageable);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->getAllDispatches: $e\n');
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

# **getDispatchById**
> ApiResponseDispatchDto getDispatchById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDispatchById(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->getDispatchById: $e\n');
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

# **getDispatchStatusHistory**
> ApiResponseListDispatchStatusHistoryDto getDispatchStatusHistory(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getDispatchStatusHistory(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->getDispatchStatusHistory: $e\n');
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

# **getDispatchesByDriverWithDateRange**
> PageDispatchDto getDispatchesByDriverWithDateRange(driverId, pageable, from, to)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final driverId = 789; // int | 
final pageable = ; // Pageable | 
final from = 2013-10-20; // DateTime | 
final to = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getDispatchesByDriverWithDateRange(driverId, pageable, from, to);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->getDispatchesByDriverWithDateRange: $e\n');
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

# **getDispatchesByDriverWithStatusFilter**
> PageDispatchDto getDispatchesByDriverWithStatusFilter(driverId, pageable, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final driverId = 789; // int | 
final pageable = ; // Pageable | 
final status = status_example; // String | 

try {
    final result = api_instance.getDispatchesByDriverWithStatusFilter(driverId, pageable, status);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->getDispatchesByDriverWithStatusFilter: $e\n');
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

# **getFilteredLoadProofs**
> ApiResponseListLoadProofDto getFilteredLoadProofs(search, driver, route, from, to)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final search = search_example; // String | 
final driver = driver_example; // String | 
final route = route_example; // String | 
final from = 2013-10-20; // DateTime | 
final to = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getFilteredLoadProofs(search, driver, route, from, to);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->getFilteredLoadProofs: $e\n');
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

# **importBulkDispatches**
> ApiResponseString importBulkDispatches(file)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final file = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.importBulkDispatches(file);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->importBulkDispatches: $e\n');
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

# **markAsUnloaded**
> Object markAsUnloaded(dispatchId, remarks, address, latitude, longitude, markAsUnloadedRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final dispatchId = 789; // int | 
final remarks = remarks_example; // String | 
final address = address_example; // String | 
final latitude = 1.2; // double | 
final longitude = 1.2; // double | 
final markAsUnloadedRequest = MarkAsUnloadedRequest(); // MarkAsUnloadedRequest | 

try {
    final result = api_instance.markAsUnloaded(dispatchId, remarks, address, latitude, longitude, markAsUnloadedRequest);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->markAsUnloaded: $e\n');
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

# **notifyAssignedDriver**
> ApiResponseDispatchDto notifyAssignedDriver(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.notifyAssignedDriver(id);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->notifyAssignedDriver: $e\n');
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

# **planTrip**
> ApiResponseDispatchDto planTrip(requestBody)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final requestBody = Map<String, Object>(); // Map<String, Object> | 

try {
    final result = api_instance.planTrip(requestBody);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->planTrip: $e\n');
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

# **rejectDispatch**
> ApiResponseDispatchDto rejectDispatch(id, reason)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 
final reason = reason_example; // String | 

try {
    final result = api_instance.rejectDispatch(id, reason);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->rejectDispatch: $e\n');
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

# **submitLoadProof**
> ApiResponseLoadProofDto submitLoadProof(dispatchId, remarks, images, signature)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final dispatchId = 789; // int | 
final remarks = remarks_example; // String | 
final images = [/path/to/file.txt]; // List<MultipartFile> | 
final signature = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.submitLoadProof(dispatchId, remarks, images, signature);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->submitLoadProof: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dispatchId** | **int**|  | 
 **remarks** | **String**|  | [optional] 
 **images** | [**List<MultipartFile>**](MultipartFile.md)|  | [optional] 
 **signature** | **MultipartFile**|  | [optional] 

### Return type

[**ApiResponseLoadProofDto**](ApiResponseLoadProofDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitUnloadProof**
> ApiResponseUnloadProofDto submitUnloadProof(dispatchId, remarks, address, latitude, longitude, images, signature)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final dispatchId = 789; // int | 
final remarks = remarks_example; // String | 
final address = address_example; // String | 
final latitude = 1.2; // double | 
final longitude = 1.2; // double | 
final images = [/path/to/file.txt]; // List<MultipartFile> | 
final signature = BINARY_DATA_HERE; // MultipartFile | 

try {
    final result = api_instance.submitUnloadProof(dispatchId, remarks, address, latitude, longitude, images, signature);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->submitUnloadProof: $e\n');
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

# **updateDispatch**
> ApiResponseDispatchDto updateDispatch(id, dispatchDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 
final dispatchDto = DispatchDto(); // DispatchDto | 

try {
    final result = api_instance.updateDispatch(id, dispatchDto);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->updateDispatch: $e\n');
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

# **updateDispatchStatus**
> ApiResponseDispatchDto updateDispatchStatus(id, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DispatchControllerApi();
final id = 789; // int | 
final status = status_example; // String | 

try {
    final result = api_instance.updateDispatchStatus(id, status);
    print(result);
} catch (e) {
    print('Exception when calling DispatchControllerApi->updateDispatchStatus: $e\n');
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

