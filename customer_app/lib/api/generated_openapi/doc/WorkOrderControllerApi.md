# openapi.api.WorkOrderControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addPart**](WorkOrderControllerApi.md#addpart) | **POST** /api/admin/work-orders/{id}/parts | 
[**addTask**](WorkOrderControllerApi.md#addtask) | **POST** /api/admin/work-orders/{id}/tasks | 
[**approveWorkOrder**](WorkOrderControllerApi.md#approveworkorder) | **POST** /api/admin/work-orders/{id}/approve | 
[**countByStatus**](WorkOrderControllerApi.md#countbystatus) | **GET** /api/admin/work-orders/stats/by-status | 
[**countByType**](WorkOrderControllerApi.md#countbytype) | **GET** /api/admin/work-orders/stats/by-type | 
[**createWorkOrder**](WorkOrderControllerApi.md#createworkorder) | **POST** /api/admin/work-orders | 
[**deleteWorkOrder**](WorkOrderControllerApi.md#deleteworkorder) | **DELETE** /api/admin/work-orders/{id} | 
[**filterWorkOrders**](WorkOrderControllerApi.md#filterworkorders) | **GET** /api/admin/work-orders/filter | 
[**getAllWorkOrders**](WorkOrderControllerApi.md#getallworkorders) | **GET** /api/admin/work-orders | 
[**getPendingApproval**](WorkOrderControllerApi.md#getpendingapproval) | **GET** /api/admin/work-orders/pending-approval | 
[**getTechnicianWorkOrder**](WorkOrderControllerApi.md#gettechnicianworkorder) | **GET** /api/technician/work-orders/{id} | 
[**getUrgentWorkOrders**](WorkOrderControllerApi.md#geturgentworkorders) | **GET** /api/admin/work-orders/urgent | 
[**getWorkOrderById**](WorkOrderControllerApi.md#getworkorderbyid) | **GET** /api/admin/work-orders/{id} | 
[**technicianUpdateStatus**](WorkOrderControllerApi.md#technicianupdatestatus) | **PATCH** /api/technician/work-orders/{id}/status | 
[**updateStatus1**](WorkOrderControllerApi.md#updatestatus1) | **PATCH** /api/admin/work-orders/{id}/status | 


# **addPart**
> WorkOrderDto addPart(id, workOrderPartDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final id = 789; // int | 
final workOrderPartDto = WorkOrderPartDto(); // WorkOrderPartDto | 

try {
    final result = api_instance.addPart(id, workOrderPartDto);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->addPart: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **workOrderPartDto** | [**WorkOrderPartDto**](WorkOrderPartDto.md)|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addTask**
> WorkOrderDto addTask(id, workOrderTaskDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final id = 789; // int | 
final workOrderTaskDto = WorkOrderTaskDto(); // WorkOrderTaskDto | 

try {
    final result = api_instance.addTask(id, workOrderTaskDto);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->addTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **workOrderTaskDto** | [**WorkOrderTaskDto**](WorkOrderTaskDto.md)|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **approveWorkOrder**
> WorkOrderDto approveWorkOrder(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.approveWorkOrder(id);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->approveWorkOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **countByStatus**
> int countByStatus(status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final status = status_example; // String | 

try {
    final result = api_instance.countByStatus(status);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->countByStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | 

### Return type

**int**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **countByType**
> int countByType(type)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final type = type_example; // String | 

try {
    final result = api_instance.countByType(type);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->countByType: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String**|  | 

### Return type

**int**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createWorkOrder**
> WorkOrderDto createWorkOrder(workOrderDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final workOrderDto = WorkOrderDto(); // WorkOrderDto | 

try {
    final result = api_instance.createWorkOrder(workOrderDto);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->createWorkOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **workOrderDto** | [**WorkOrderDto**](WorkOrderDto.md)|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteWorkOrder**
> deleteWorkOrder(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final id = 789; // int | 

try {
    api_instance.deleteWorkOrder(id);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->deleteWorkOrder: $e\n');
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

# **filterWorkOrders**
> PageWorkOrderDto filterWorkOrders(pageable, status, type, priority, vehicleId, technicianId, scheduledAfter, scheduledBefore)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final pageable = ; // Pageable | 
final status = status_example; // String | 
final type = type_example; // String | 
final priority = priority_example; // String | 
final vehicleId = 789; // int | 
final technicianId = 789; // int | 
final scheduledAfter = 2013-10-20T19:20:30+01:00; // DateTime | 
final scheduledBefore = 2013-10-20T19:20:30+01:00; // DateTime | 

try {
    final result = api_instance.filterWorkOrders(pageable, status, type, priority, vehicleId, technicianId, scheduledAfter, scheduledBefore);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->filterWorkOrders: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 
 **status** | **String**|  | [optional] 
 **type** | **String**|  | [optional] 
 **priority** | **String**|  | [optional] 
 **vehicleId** | **int**|  | [optional] 
 **technicianId** | **int**|  | [optional] 
 **scheduledAfter** | **DateTime**|  | [optional] 
 **scheduledBefore** | **DateTime**|  | [optional] 

### Return type

[**PageWorkOrderDto**](PageWorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllWorkOrders**
> PageWorkOrderDto getAllWorkOrders(pageable)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final pageable = ; // Pageable | 

try {
    final result = api_instance.getAllWorkOrders(pageable);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->getAllWorkOrders: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 

### Return type

[**PageWorkOrderDto**](PageWorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPendingApproval**
> List<WorkOrderDto> getPendingApproval()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();

try {
    final result = api_instance.getPendingApproval();
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->getPendingApproval: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<WorkOrderDto>**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTechnicianWorkOrder**
> WorkOrderDto getTechnicianWorkOrder(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getTechnicianWorkOrder(id);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->getTechnicianWorkOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUrgentWorkOrders**
> List<WorkOrderDto> getUrgentWorkOrders()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();

try {
    final result = api_instance.getUrgentWorkOrders();
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->getUrgentWorkOrders: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<WorkOrderDto>**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getWorkOrderById**
> WorkOrderDto getWorkOrderById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getWorkOrderById(id);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->getWorkOrderById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **technicianUpdateStatus**
> WorkOrderDto technicianUpdateStatus(id, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final id = 789; // int | 
final status = status_example; // String | 

try {
    final result = api_instance.technicianUpdateStatus(id, status);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->technicianUpdateStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **status** | **String**|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateStatus1**
> WorkOrderDto updateStatus1(id, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = WorkOrderControllerApi();
final id = 789; // int | 
final status = status_example; // String | 

try {
    final result = api_instance.updateStatus1(id, status);
    print(result);
} catch (e) {
    print('Exception when calling WorkOrderControllerApi->updateStatus1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **status** | **String**|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

