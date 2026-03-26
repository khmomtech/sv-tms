# openapi.api.MaintenanceTaskControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**completeTask**](MaintenanceTaskControllerApi.md#completetask) | **POST** /api/admin/maintenance-tasks/{id}/complete | 
[**createTask**](MaintenanceTaskControllerApi.md#createtask) | **POST** /api/admin/maintenance-tasks | 
[**deleteTask**](MaintenanceTaskControllerApi.md#deletetask) | **DELETE** /api/admin/maintenance-tasks/{id} | 
[**getOverdueTasks**](MaintenanceTaskControllerApi.md#getoverduetasks) | **GET** /api/admin/maintenance-tasks/overdue | 
[**getTask**](MaintenanceTaskControllerApi.md#gettask) | **GET** /api/admin/maintenance-tasks/{id} | 
[**getTasksByVehicle**](MaintenanceTaskControllerApi.md#gettasksbyvehicle) | **GET** /api/admin/maintenance-tasks/vehicle/{vehicleId} | 
[**getUpcomingTasks**](MaintenanceTaskControllerApi.md#getupcomingtasks) | **GET** /api/admin/maintenance-tasks/upcoming | 
[**listTasks**](MaintenanceTaskControllerApi.md#listtasks) | **GET** /api/admin/maintenance-tasks | 
[**updateTask**](MaintenanceTaskControllerApi.md#updatetask) | **PUT** /api/admin/maintenance-tasks/{id} | 


# **completeTask**
> ApiResponseMaintenanceTaskDto completeTask(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.completeTask(id);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskControllerApi->completeTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseMaintenanceTaskDto**](ApiResponseMaintenanceTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createTask**
> ApiResponseMaintenanceTaskDto createTask(maintenanceTaskDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskControllerApi();
final maintenanceTaskDto = MaintenanceTaskDto(); // MaintenanceTaskDto | 

try {
    final result = api_instance.createTask(maintenanceTaskDto);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskControllerApi->createTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **maintenanceTaskDto** | [**MaintenanceTaskDto**](MaintenanceTaskDto.md)|  | 

### Return type

[**ApiResponseMaintenanceTaskDto**](ApiResponseMaintenanceTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteTask**
> ApiResponseVoid deleteTask(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteTask(id);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskControllerApi->deleteTask: $e\n');
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

# **getOverdueTasks**
> ApiResponseListMaintenanceTaskDto getOverdueTasks()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskControllerApi();

try {
    final result = api_instance.getOverdueTasks();
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskControllerApi->getOverdueTasks: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListMaintenanceTaskDto**](ApiResponseListMaintenanceTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTask**
> ApiResponseMaintenanceTaskDto getTask(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getTask(id);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskControllerApi->getTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseMaintenanceTaskDto**](ApiResponseMaintenanceTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTasksByVehicle**
> ApiResponseListMaintenanceTaskDto getTasksByVehicle(vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskControllerApi();
final vehicleId = 789; // int | 

try {
    final result = api_instance.getTasksByVehicle(vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskControllerApi->getTasksByVehicle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vehicleId** | **int**|  | 

### Return type

[**ApiResponseListMaintenanceTaskDto**](ApiResponseListMaintenanceTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUpcomingTasks**
> ApiResponseListMaintenanceTaskDto getUpcomingTasks(days)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskControllerApi();
final days = 56; // int | 

try {
    final result = api_instance.getUpcomingTasks(days);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskControllerApi->getUpcomingTasks: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **days** | **int**|  | [optional] [default to 7]

### Return type

[**ApiResponseListMaintenanceTaskDto**](ApiResponseListMaintenanceTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listTasks**
> ApiResponsePageMaintenanceTaskDto listTasks(keyword, status, vehicleId, dueBefore, dueAfter, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskControllerApi();
final keyword = keyword_example; // String | 
final status = status_example; // String | 
final vehicleId = 789; // int | 
final dueBefore = 2013-10-20; // DateTime | 
final dueAfter = 2013-10-20; // DateTime | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.listTasks(keyword, status, vehicleId, dueBefore, dueAfter, page, size);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskControllerApi->listTasks: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **keyword** | **String**|  | [optional] 
 **status** | **String**|  | [optional] 
 **vehicleId** | **int**|  | [optional] 
 **dueBefore** | **DateTime**|  | [optional] 
 **dueAfter** | **DateTime**|  | [optional] 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 10]

### Return type

[**ApiResponsePageMaintenanceTaskDto**](ApiResponsePageMaintenanceTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateTask**
> ApiResponseMaintenanceTaskDto updateTask(id, maintenanceTaskDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskControllerApi();
final id = 789; // int | 
final maintenanceTaskDto = MaintenanceTaskDto(); // MaintenanceTaskDto | 

try {
    final result = api_instance.updateTask(id, maintenanceTaskDto);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskControllerApi->updateTask: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **maintenanceTaskDto** | [**MaintenanceTaskDto**](MaintenanceTaskDto.md)|  | 

### Return type

[**ApiResponseMaintenanceTaskDto**](ApiResponseMaintenanceTaskDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

