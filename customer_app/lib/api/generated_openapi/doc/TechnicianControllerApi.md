# openapi.api.TechnicianControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMyPendingTasks**](TechnicianControllerApi.md#getmypendingtasks) | **GET** /api/technician/tasks/pending | 
[**getMyTasks**](TechnicianControllerApi.md#getmytasks) | **GET** /api/technician/tasks | 
[**getMyWorkOrderDetails**](TechnicianControllerApi.md#getmyworkorderdetails) | **GET** /api/technician/work-orders/{woId} | 
[**getMyWorkOrders**](TechnicianControllerApi.md#getmyworkorders) | **GET** /api/technician/work-orders | 
[**updateMyWorkOrderStatus**](TechnicianControllerApi.md#updatemyworkorderstatus) | **PATCH** /api/technician/work-orders/{woId}/status | 
[**updateTaskHours**](TechnicianControllerApi.md#updatetaskhours) | **PATCH** /api/technician/tasks/{taskId}/hours | 
[**updateTaskStatus**](TechnicianControllerApi.md#updatetaskstatus) | **PATCH** /api/technician/tasks/{taskId}/status | 


# **getMyPendingTasks**
> List<WorkOrderTaskDto> getMyPendingTasks()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TechnicianControllerApi();

try {
    final result = api_instance.getMyPendingTasks();
    print(result);
} catch (e) {
    print('Exception when calling TechnicianControllerApi->getMyPendingTasks: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<WorkOrderTaskDto>**](WorkOrderTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyTasks**
> List<WorkOrderTaskDto> getMyTasks()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TechnicianControllerApi();

try {
    final result = api_instance.getMyTasks();
    print(result);
} catch (e) {
    print('Exception when calling TechnicianControllerApi->getMyTasks: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<WorkOrderTaskDto>**](WorkOrderTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyWorkOrderDetails**
> WorkOrderDto getMyWorkOrderDetails(woId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TechnicianControllerApi();
final woId = 789; // int | 

try {
    final result = api_instance.getMyWorkOrderDetails(woId);
    print(result);
} catch (e) {
    print('Exception when calling TechnicianControllerApi->getMyWorkOrderDetails: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **woId** | **int**|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyWorkOrders**
> List<WorkOrderDto> getMyWorkOrders()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TechnicianControllerApi();

try {
    final result = api_instance.getMyWorkOrders();
    print(result);
} catch (e) {
    print('Exception when calling TechnicianControllerApi->getMyWorkOrders: $e\n');
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

# **updateMyWorkOrderStatus**
> WorkOrderDto updateMyWorkOrderStatus(woId, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TechnicianControllerApi();
final woId = 789; // int | 
final status = status_example; // String | 

try {
    final result = api_instance.updateMyWorkOrderStatus(woId, status);
    print(result);
} catch (e) {
    print('Exception when calling TechnicianControllerApi->updateMyWorkOrderStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **woId** | **int**|  | 
 **status** | **String**|  | 

### Return type

[**WorkOrderDto**](WorkOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateTaskHours**
> WorkOrderTaskDto updateTaskHours(taskId, actualHours)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TechnicianControllerApi();
final taskId = 789; // int | 
final actualHours = 1.2; // double | 

try {
    final result = api_instance.updateTaskHours(taskId, actualHours);
    print(result);
} catch (e) {
    print('Exception when calling TechnicianControllerApi->updateTaskHours: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **taskId** | **int**|  | 
 **actualHours** | **double**|  | 

### Return type

[**WorkOrderTaskDto**](WorkOrderTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateTaskStatus**
> WorkOrderTaskDto updateTaskStatus(taskId, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TechnicianControllerApi();
final taskId = 789; // int | 
final status = status_example; // String | 

try {
    final result = api_instance.updateTaskStatus(taskId, status);
    print(result);
} catch (e) {
    print('Exception when calling TechnicianControllerApi->updateTaskStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **taskId** | **int**|  | 
 **status** | **String**|  | 

### Return type

[**WorkOrderTaskDto**](WorkOrderTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

