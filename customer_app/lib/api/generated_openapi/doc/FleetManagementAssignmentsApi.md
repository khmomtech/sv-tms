# openapi.api.FleetManagementAssignmentsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assignDriver2**](FleetManagementAssignmentsApi.md#assigndriver2) | **POST** /api/admin/assignments/assign | Assign a driver to a vehicle
[**cancelAssignment**](FleetManagementAssignmentsApi.md#cancelassignment) | **POST** /api/admin/assignments/cancel/{id} | Cancel an assignment
[**completeAssignment**](FleetManagementAssignmentsApi.md#completeassignment) | **POST** /api/admin/assignments/complete/{id} | Mark an assignment as completed
[**deleteAssignment**](FleetManagementAssignmentsApi.md#deleteassignment) | **DELETE** /api/admin/assignments/{id} | Delete an assignment
[**getActiveAssignments**](FleetManagementAssignmentsApi.md#getactiveassignments) | **GET** /api/admin/assignments/active | Get all active assignments (currently assigned)
[**getAllAssignments**](FleetManagementAssignmentsApi.md#getallassignments) | **GET** /api/admin/assignments/all | Get all assignments
[**getAssignmentById**](FleetManagementAssignmentsApi.md#getassignmentbyid) | **GET** /api/admin/assignments/{id} | Get assignment by ID
[**getByDriver**](FleetManagementAssignmentsApi.md#getbydriver) | **GET** /api/admin/assignments/by-driver/{driverId} | Get all assignments for a specific driver
[**getByVehicle**](FleetManagementAssignmentsApi.md#getbyvehicle) | **GET** /api/admin/assignments/by-vehicle/{vehicleId} | Get all assignments for a specific vehicle
[**getVehiclesByDriver2**](FleetManagementAssignmentsApi.md#getvehiclesbydriver2) | **GET** /api/admin/assignments/vehicles/driver/{driverId} | Get all vehicles assigned to a specific driver
[**unassignDriver**](FleetManagementAssignmentsApi.md#unassigndriver) | **POST** /api/admin/assignments/unassign | Unassign a driver from all vehicles
[**updateAssignmentVehicle**](FleetManagementAssignmentsApi.md#updateassignmentvehicle) | **PUT** /api/admin/assignments/{id}/update-vehicle | Update the vehicle in an assignment


# **assignDriver2**
> ApiResponseDriverAssignmentDto assignDriver2(driverId, vehicleId)

Assign a driver to a vehicle

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final driverId = 789; // int | Driver ID
final vehicleId = 789; // int | Vehicle ID

try {
    final result = api_instance.assignDriver2(driverId, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->assignDriver2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**| Driver ID | 
 **vehicleId** | **int**| Vehicle ID | 

### Return type

[**ApiResponseDriverAssignmentDto**](ApiResponseDriverAssignmentDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **cancelAssignment**
> ApiResponseDriverAssignmentDto cancelAssignment(id)

Cancel an assignment

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final id = 789; // int | 

try {
    final result = api_instance.cancelAssignment(id);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->cancelAssignment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseDriverAssignmentDto**](ApiResponseDriverAssignmentDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **completeAssignment**
> ApiResponseDriverAssignmentDto completeAssignment(id)

Mark an assignment as completed

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final id = 789; // int | 

try {
    final result = api_instance.completeAssignment(id);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->completeAssignment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseDriverAssignmentDto**](ApiResponseDriverAssignmentDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteAssignment**
> ApiResponseVoid deleteAssignment(id)

Delete an assignment

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteAssignment(id);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->deleteAssignment: $e\n');
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

# **getActiveAssignments**
> ApiResponseListVehicleWithDriverDto getActiveAssignments()

Get all active assignments (currently assigned)

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();

try {
    final result = api_instance.getActiveAssignments();
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->getActiveAssignments: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListVehicleWithDriverDto**](ApiResponseListVehicleWithDriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllAssignments**
> ApiResponseListDriverAssignmentDto getAllAssignments()

Get all assignments

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();

try {
    final result = api_instance.getAllAssignments();
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->getAllAssignments: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListDriverAssignmentDto**](ApiResponseListDriverAssignmentDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAssignmentById**
> ApiResponseDriverAssignmentDto getAssignmentById(id)

Get assignment by ID

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final id = 789; // int | 

try {
    final result = api_instance.getAssignmentById(id);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->getAssignmentById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseDriverAssignmentDto**](ApiResponseDriverAssignmentDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getByDriver**
> ApiResponseListDriverAssignmentDto getByDriver(driverId)

Get all assignments for a specific driver

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getByDriver(driverId);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->getByDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseListDriverAssignmentDto**](ApiResponseListDriverAssignmentDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getByVehicle**
> ApiResponseListDriverAssignmentDto getByVehicle(vehicleId)

Get all assignments for a specific vehicle

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final vehicleId = 789; // int | 

try {
    final result = api_instance.getByVehicle(vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->getByVehicle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vehicleId** | **int**|  | 

### Return type

[**ApiResponseListDriverAssignmentDto**](ApiResponseListDriverAssignmentDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getVehiclesByDriver2**
> ApiResponseListVehicleDto getVehiclesByDriver2(driverId)

Get all vehicles assigned to a specific driver

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getVehiclesByDriver2(driverId);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->getVehiclesByDriver2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseListVehicleDto**](ApiResponseListVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unassignDriver**
> ApiResponseString unassignDriver(driverId)

Unassign a driver from all vehicles

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final driverId = 789; // int | Driver ID

try {
    final result = api_instance.unassignDriver(driverId);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->unassignDriver: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**| Driver ID | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateAssignmentVehicle**
> ApiResponseDriverAssignmentDto updateAssignmentVehicle(id, newVehicleId)

Update the vehicle in an assignment

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementAssignmentsApi();
final id = 789; // int | 
final newVehicleId = 789; // int | 

try {
    final result = api_instance.updateAssignmentVehicle(id, newVehicleId);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementAssignmentsApi->updateAssignmentVehicle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **newVehicleId** | **int**|  | 

### Return type

[**ApiResponseDriverAssignmentDto**](ApiResponseDriverAssignmentDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

