# openapi.api.FleetManagementTrailersApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assignTrailerToTruck**](FleetManagementTrailersApi.md#assigntrailertotruck) | **POST** /api/admin/trailers/{trailerId}/assign/{vehicleId} | Assign trailer to a truck
[**getAllTrailers**](FleetManagementTrailersApi.md#getalltrailers) | **GET** /api/admin/trailers/list | Get all trailers with pagination
[**getAllTrailersNoPage**](FleetManagementTrailersApi.md#getalltrailersnopage) | **GET** /api/admin/trailers/all | Get all trailers without pagination
[**getAvailableTrailers**](FleetManagementTrailersApi.md#getavailabletrailers) | **GET** /api/admin/trailers/available | Get all available trailers (not assigned to any truck)
[**getTrailersByTruck**](FleetManagementTrailersApi.md#gettrailersbytruck) | **GET** /api/admin/trailers/by-truck/{vehicleId} | Get trailers assigned to a specific truck
[**searchTrailers**](FleetManagementTrailersApi.md#searchtrailers) | **GET** /api/admin/trailers/search | Search trailers with filters
[**unassignTrailer**](FleetManagementTrailersApi.md#unassigntrailer) | **POST** /api/admin/trailers/{trailerId}/unassign | Unassign trailer from its current truck


# **assignTrailerToTruck**
> ApiResponseVehicleDto assignTrailerToTruck(trailerId, vehicleId)

Assign trailer to a truck

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementTrailersApi();
final trailerId = 789; // int | 
final vehicleId = 789; // int | 

try {
    final result = api_instance.assignTrailerToTruck(trailerId, vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementTrailersApi->assignTrailerToTruck: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **trailerId** | **int**|  | 
 **vehicleId** | **int**|  | 

### Return type

[**ApiResponseVehicleDto**](ApiResponseVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllTrailers**
> ApiResponsePageVehicleDto getAllTrailers(page, size)

Get all trailers with pagination

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementTrailersApi();
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getAllTrailers(page, size);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementTrailersApi->getAllTrailers: $e\n');
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

# **getAllTrailersNoPage**
> ApiResponseListVehicleDto getAllTrailersNoPage()

Get all trailers without pagination

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementTrailersApi();

try {
    final result = api_instance.getAllTrailersNoPage();
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementTrailersApi->getAllTrailersNoPage: $e\n');
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

# **getAvailableTrailers**
> ApiResponseListVehicleDto getAvailableTrailers()

Get all available trailers (not assigned to any truck)

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementTrailersApi();

try {
    final result = api_instance.getAvailableTrailers();
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementTrailersApi->getAvailableTrailers: $e\n');
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

# **getTrailersByTruck**
> ApiResponseListVehicleDto getTrailersByTruck(vehicleId)

Get trailers assigned to a specific truck

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementTrailersApi();
final vehicleId = 789; // int | 

try {
    final result = api_instance.getTrailersByTruck(vehicleId);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementTrailersApi->getTrailersByTruck: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **vehicleId** | **int**|  | 

### Return type

[**ApiResponseListVehicleDto**](ApiResponseListVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchTrailers**
> ApiResponsePageVehicleDto searchTrailers(search, status, zone, assigned, page, size)

Search trailers with filters

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementTrailersApi();
final search = search_example; // String | Search term for license plate, model, or manufacturer
final status = status_example; // String | Filter by trailer status
final zone = zone_example; // String | Filter by assigned zone
final assigned = true; // bool | Filter by assignment status (true=assigned to truck, false=unassigned)
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.searchTrailers(search, status, zone, assigned, page, size);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementTrailersApi->searchTrailers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**| Search term for license plate, model, or manufacturer | [optional] 
 **status** | **String**| Filter by trailer status | [optional] 
 **zone** | **String**| Filter by assigned zone | [optional] 
 **assigned** | **bool**| Filter by assignment status (true=assigned to truck, false=unassigned) | [optional] 
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

# **unassignTrailer**
> ApiResponseVehicleDto unassignTrailer(trailerId)

Unassign trailer from its current truck

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = FleetManagementTrailersApi();
final trailerId = 789; // int | 

try {
    final result = api_instance.unassignTrailer(trailerId);
    print(result);
} catch (e) {
    print('Exception when calling FleetManagementTrailersApi->unassignTrailer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **trailerId** | **int**|  | 

### Return type

[**ApiResponseVehicleDto**](ApiResponseVehicleDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

