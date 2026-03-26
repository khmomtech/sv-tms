# openapi.api.FleetManagementVehiclesApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addVehicle**](FleetManagementVehiclesApi.md#addvehicle) | **POST** /api/admin/vehicles | Create a new vehicle
[**deleteVehicle**](FleetManagementVehiclesApi.md#deletevehicle) | **DELETE** /api/admin/vehicles/{id} | Delete a vehicle
[**filterVehicles**](FleetManagementVehiclesApi.md#filtervehicles) | **GET** /api/admin/vehicles/filter | Filter vehicles (legacy endpoint)
[**getAllVehicles**](FleetManagementVehiclesApi.md#getallvehicles) | **GET** /api/admin/vehicles/list | Get all vehicles with pagination
[**getAllVehiclesNoPage**](FleetManagementVehiclesApi.md#getallvehiclesnopage) | **GET** /api/admin/vehicles/all | Get all vehicles without pagination
[**getByLicensePlate**](FleetManagementVehiclesApi.md#getbylicenseplate) | **GET** /api/admin/vehicles/license/{licensePlate} | Get vehicle by license plate
[**getFleetStatistics**](FleetManagementVehiclesApi.md#getfleetstatistics) | **GET** /api/admin/vehicles/statistics | Get comprehensive fleet statistics
[**getTrailers**](FleetManagementVehiclesApi.md#gettrailers) | **GET** /api/admin/vehicles/trailers | Get all trailers
[**getUnassignedVehicles**](FleetManagementVehiclesApi.md#getunassignedvehicles) | **GET** /api/admin/vehicles/unassigned | Get all unassigned vehicles
[**getVehicleById**](FleetManagementVehiclesApi.md#getvehiclebyid) | **GET** /api/admin/vehicles/{id} | Get vehicle by ID
[**getVehiclesByStatus**](FleetManagementVehiclesApi.md#getvehiclesbystatus) | **GET** /api/admin/vehicles/status/{status} | Get vehicles by status
[**getVehiclesRequiringService**](FleetManagementVehiclesApi.md#getvehiclesrequiringservice) | **GET** /api/admin/vehicles/service-due | Get vehicles requiring service
[**searchVehicles**](FleetManagementVehiclesApi.md#searchvehicles) | **GET** /api/admin/vehicles/search | Advanced vehicle search with multiple criteria
[**updateVehicle**](FleetManagementVehiclesApi.md#updatevehicle) | **PUT** /api/admin/vehicles/{id} | Update an existing vehicle


# **addVehicle**
> ApiResponseVehicleDto addVehicle(vehicleDto)

Create a new vehicle

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();
final vehicleDto = VehicleDto(); // VehicleDto | 

try {
    final result = api_instance.addVehicle(vehicleDto);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->addVehicle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vehicleDto** | [**VehicleDto**](VehicleDto.md)|  | 

### Return type

[**ApiResponseVehicleDto**](ApiResponseVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteVehicle**
> ApiResponseVoid deleteVehicle(id)

Delete a vehicle

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteVehicle(id);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->deleteVehicle: $e\n');
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

# **filterVehicles**
> ApiResponsePageVehicleDto filterVehicles(search, truckSize, status, zone, driverAssignment, page, size)

Filter vehicles (legacy endpoint)

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();
final search = search_example; // String | 
final truckSize = truckSize_example; // String | 
final status = status_example; // String | 
final zone = zone_example; // String | 
final driverAssignment = driverAssignment_example; // String | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.filterVehicles(search, truckSize, status, zone, driverAssignment, page, size);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->filterVehicles: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**|  | [optional] 
 **truckSize** | **String**|  | [optional] 
 **status** | **String**|  | [optional] 
 **zone** | **String**|  | [optional] 
 **driverAssignment** | **String**|  | [optional] 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 15]

### Return type

[**ApiResponsePageVehicleDto**](ApiResponsePageVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllVehicles**
> ApiResponsePageVehicleDto getAllVehicles(page, size)

Get all vehicles with pagination

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getAllVehicles(page, size);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->getAllVehicles: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 15]

### Return type

[**ApiResponsePageVehicleDto**](ApiResponsePageVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllVehiclesNoPage**
> ApiResponseListVehicleDto getAllVehiclesNoPage()

Get all vehicles without pagination

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();

try {
    final result = api_instance.getAllVehiclesNoPage();
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->getAllVehiclesNoPage: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListVehicleDto**](ApiResponseListVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getByLicensePlate**
> ApiResponseVehicleDto getByLicensePlate(licensePlate)

Get vehicle by license plate

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();
final licensePlate = licensePlate_example; // String | 

try {
    final result = api_instance.getByLicensePlate(licensePlate);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->getByLicensePlate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **licensePlate** | **String**|  | 

### Return type

[**ApiResponseVehicleDto**](ApiResponseVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getFleetStatistics**
> ApiResponseVehicleStatisticsDto getFleetStatistics()

Get comprehensive fleet statistics

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();

try {
    final result = api_instance.getFleetStatistics();
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->getFleetStatistics: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseVehicleStatisticsDto**](ApiResponseVehicleStatisticsDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTrailers**
> ApiResponseListVehicleDto getTrailers()

Get all trailers

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();

try {
    final result = api_instance.getTrailers();
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->getTrailers: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListVehicleDto**](ApiResponseListVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getUnassignedVehicles**
> ApiResponseListVehicleDto getUnassignedVehicles()

Get all unassigned vehicles

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();

try {
    final result = api_instance.getUnassignedVehicles();
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->getUnassignedVehicles: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListVehicleDto**](ApiResponseListVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getVehicleById**
> ApiResponseVehicleDto getVehicleById(id)

Get vehicle by ID

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();
final id = 789; // int | 

try {
    final result = api_instance.getVehicleById(id);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->getVehicleById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseVehicleDto**](ApiResponseVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getVehiclesByStatus**
> ApiResponseListVehicleDto getVehiclesByStatus(status)

Get vehicles by status

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();
final status = status_example; // String | 

try {
    final result = api_instance.getVehiclesByStatus(status);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->getVehiclesByStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | 

### Return type

[**ApiResponseListVehicleDto**](ApiResponseListVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getVehiclesRequiringService**
> ApiResponseListVehicleDto getVehiclesRequiringService()

Get vehicles requiring service

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();

try {
    final result = api_instance.getVehiclesRequiringService();
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->getVehiclesRequiringService: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListVehicleDto**](ApiResponseListVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchVehicles**
> ApiResponsePageVehicleDto searchVehicles(search, status, type, truckSize, zone, page, size)

Advanced vehicle search with multiple criteria

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();
final search = search_example; // String | Search term for license plate, model, or manufacturer
final status = status_example; // String | Filter by vehicle status
final type = type_example; // String | Filter by vehicle type
final truckSize = truckSize_example; // String | Filter by truck size
final zone = zone_example; // String | Filter by assigned zone
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.searchVehicles(search, status, type, truckSize, zone, page, size);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->searchVehicles: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**| Search term for license plate, model, or manufacturer | [optional] 
 **status** | **String**| Filter by vehicle status | [optional] 
 **type** | **String**| Filter by vehicle type | [optional] 
 **truckSize** | **String**| Filter by truck size | [optional] 
 **zone** | **String**| Filter by assigned zone | [optional] 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 15]

### Return type

[**ApiResponsePageVehicleDto**](ApiResponsePageVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateVehicle**
> ApiResponseVehicleDto updateVehicle(id, vehicleDto)

Update an existing vehicle

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementVehiclesApi();
final id = 789; // int | 
final vehicleDto = VehicleDto(); // VehicleDto | 

try {
    final result = api_instance.updateVehicle(id, vehicleDto);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementVehiclesApi->updateVehicle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **vehicleDto** | [**VehicleDto**](VehicleDto.md)|  | 

### Return type

[**ApiResponseVehicleDto**](ApiResponseVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

