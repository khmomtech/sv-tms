# openapi.api.DriverAssignmentControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assignDriver1**](DriverAssignmentControllerApi.md#assigndriver1) | **POST** /api/admin/drivers/assign | 
[**getVehiclesByDriver1**](DriverAssignmentControllerApi.md#getvehiclesbydriver1) | **GET** /api/admin/drivers/by-driver/{driverId} | 
[**getVehiclesWithCurrentDrivers1**](DriverAssignmentControllerApi.md#getvehicleswithcurrentdrivers1) | **GET** /api/admin/drivers/vehicles-with-drivers | 


# **assignDriver1**
> ApiResponseDriverAssignment assignDriver1(driverId, vehicleId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAssignmentControllerApi();
final driverId = 789; // int | 
final vehicleId = 789; // int | 

try {
    final result = api_instance.assignDriver1(driverId, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling DriverAssignmentControllerApi->assignDriver1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **vehicleId** | **int**|  | 

### Return type

[**ApiResponseDriverAssignment**](ApiResponseDriverAssignment.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getVehiclesByDriver1**
> ApiResponseListVehicleDto getVehiclesByDriver1(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAssignmentControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getVehiclesByDriver1(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverAssignmentControllerApi->getVehiclesByDriver1: $e\n');
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

# **getVehiclesWithCurrentDrivers1**
> ApiResponseListVehicleWithDriverDto getVehiclesWithCurrentDrivers1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverAssignmentControllerApi();

try {
    final result = api_instance.getVehiclesWithCurrentDrivers1();
    print(result);
} catch (e) {
    print('Exception when calling DriverAssignmentControllerApi->getVehiclesWithCurrentDrivers1: $e\n');
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

