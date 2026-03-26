# openapi.api.PmScheduleControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createSchedule**](PmScheduleControllerApi.md#createschedule) | **POST** /api/admin/pm-schedules | 
[**createWorkOrderFromPM**](PmScheduleControllerApi.md#createworkorderfrompm) | **POST** /api/admin/pm-schedules/{id}/create-work-order | 
[**deactivateSchedule**](PmScheduleControllerApi.md#deactivateschedule) | **PATCH** /api/admin/pm-schedules/{id}/deactivate | 
[**deleteSchedule**](PmScheduleControllerApi.md#deleteschedule) | **DELETE** /api/admin/pm-schedules/{id} | 
[**getAllSchedules**](PmScheduleControllerApi.md#getallschedules) | **GET** /api/admin/pm-schedules | 
[**getDueSoonSchedules**](PmScheduleControllerApi.md#getduesoonschedules) | **GET** /api/admin/pm-schedules/due-soon | 
[**getOverdueSchedules**](PmScheduleControllerApi.md#getoverdueschedules) | **GET** /api/admin/pm-schedules/overdue | 
[**getScheduleById**](PmScheduleControllerApi.md#getschedulebyid) | **GET** /api/admin/pm-schedules/{id} | 
[**getSchedulesByVehicle**](PmScheduleControllerApi.md#getschedulesbyvehicle) | **GET** /api/admin/pm-schedules/vehicle/{vehicleId} | 
[**getSchedulesByVehicleType**](PmScheduleControllerApi.md#getschedulesbyvehicletype) | **GET** /api/admin/pm-schedules/vehicle-type/{vehicleType} | 
[**recordPMCompletion**](PmScheduleControllerApi.md#recordpmcompletion) | **POST** /api/admin/pm-schedules/{id}/record-completion | 
[**triggerManualPMCheck**](PmScheduleControllerApi.md#triggermanualpmcheck) | **POST** /api/admin/pm-schedules/trigger-check | 
[**updateSchedule**](PmScheduleControllerApi.md#updateschedule) | **PUT** /api/admin/pm-schedules/{id} | 


# **createSchedule**
> PMScheduleDto createSchedule(pMScheduleDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final pMScheduleDto = PMScheduleDto(); // PMScheduleDto | 

try {
    final result = api_instance.createSchedule(pMScheduleDto);
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->createSchedule: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pMScheduleDto** | [**PMScheduleDto**](PMScheduleDto.md)|  | 

### Return type

[**PMScheduleDto**](PMScheduleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createWorkOrderFromPM**
> WorkOrderDto createWorkOrderFromPM(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.createWorkOrderFromPM(id);
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->createWorkOrderFromPM: $e\n');
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

# **deactivateSchedule**
> deactivateSchedule(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final id = 789; // int | 

try {
    api_instance.deactivateSchedule(id);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->deactivateSchedule: $e\n');
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

# **deleteSchedule**
> deleteSchedule(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final id = 789; // int | 

try {
    api_instance.deleteSchedule(id);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->deleteSchedule: $e\n');
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

# **getAllSchedules**
> PagePMScheduleDto getAllSchedules(pageable, active)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final pageable = ; // Pageable | 
final active = true; // bool | 

try {
    final result = api_instance.getAllSchedules(pageable, active);
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->getAllSchedules: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 
 **active** | **bool**|  | [optional] 

### Return type

[**PagePMScheduleDto**](PagePMScheduleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDueSoonSchedules**
> List<PMScheduleDto> getDueSoonSchedules(daysAhead)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final daysAhead = 56; // int | 

try {
    final result = api_instance.getDueSoonSchedules(daysAhead);
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->getDueSoonSchedules: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **daysAhead** | **int**|  | [optional] [default to 7]

### Return type

[**List<PMScheduleDto>**](PMScheduleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOverdueSchedules**
> List<PMScheduleDto> getOverdueSchedules()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();

try {
    final result = api_instance.getOverdueSchedules();
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->getOverdueSchedules: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<PMScheduleDto>**](PMScheduleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getScheduleById**
> PMScheduleDto getScheduleById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getScheduleById(id);
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->getScheduleById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**PMScheduleDto**](PMScheduleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSchedulesByVehicle**
> List<PMScheduleDto> getSchedulesByVehicle(vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final vehicleId = 789; // int | 

try {
    final result = api_instance.getSchedulesByVehicle(vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->getSchedulesByVehicle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vehicleId** | **int**|  | 

### Return type

[**List<PMScheduleDto>**](PMScheduleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSchedulesByVehicleType**
> List<PMScheduleDto> getSchedulesByVehicleType(vehicleType)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final vehicleType = vehicleType_example; // String | 

try {
    final result = api_instance.getSchedulesByVehicleType(vehicleType);
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->getSchedulesByVehicleType: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vehicleType** | **String**|  | 

### Return type

[**List<PMScheduleDto>**](PMScheduleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recordPMCompletion**
> recordPMCompletion(id, workOrderId, performedAtKm, performedDate, performedEngineHours)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final id = 789; // int | 
final workOrderId = 789; // int | 
final performedAtKm = 56; // int | 
final performedDate = 2013-10-20; // DateTime | 
final performedEngineHours = 56; // int | 

try {
    api_instance.recordPMCompletion(id, workOrderId, performedAtKm, performedDate, performedEngineHours);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->recordPMCompletion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **workOrderId** | **int**|  | 
 **performedAtKm** | **int**|  | [optional] 
 **performedDate** | **DateTime**|  | [optional] 
 **performedEngineHours** | **int**|  | [optional] 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **triggerManualPMCheck**
> List<WorkOrderDto> triggerManualPMCheck()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();

try {
    final result = api_instance.triggerManualPMCheck();
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->triggerManualPMCheck: $e\n');
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

# **updateSchedule**
> PMScheduleDto updateSchedule(id, pMScheduleDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PmScheduleControllerApi();
final id = 789; // int | 
final pMScheduleDto = PMScheduleDto(); // PMScheduleDto | 

try {
    final result = api_instance.updateSchedule(id, pMScheduleDto);
    print(result);
} catch (e) {
    print('Exception when calling PmScheduleControllerApi->updateSchedule: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **pMScheduleDto** | [**PMScheduleDto**](PMScheduleDto.md)|  | 

### Return type

[**PMScheduleDto**](PMScheduleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

