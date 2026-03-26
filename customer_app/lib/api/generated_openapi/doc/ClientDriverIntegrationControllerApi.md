# openapi.api.ClientDriverIntegrationControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getDriverById**](ClientDriverIntegrationControllerApi.md#getdriverbyid) | **GET** /api/v1/integrations/drivers/{id} | 
[**searchDrivers**](ClientDriverIntegrationControllerApi.md#searchdrivers) | **GET** /api/v1/integrations/drivers/search | 


# **getDriverById**
> DriverDto getDriverById(id, includeLocationHistory)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ClientDriverIntegrationControllerApi();
final id = 789; // int | 
final includeLocationHistory = true; // bool | 

try {
    final result = api_instance.getDriverById(id, includeLocationHistory);
    print(result);
} catch (e) {
    print('Exception when calling ClientDriverIntegrationControllerApi->getDriverById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **includeLocationHistory** | **bool**|  | [optional] [default to false]

### Return type

[**DriverDto**](DriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchDrivers**
> List<DriverDto> searchDrivers(keyword, truckType, status, zone, licensePlate, includeLocationHistory)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ClientDriverIntegrationControllerApi();
final keyword = keyword_example; // String | 
final truckType = truckType_example; // String | 
final status = status_example; // String | 
final zone = zone_example; // String | 
final licensePlate = licensePlate_example; // String | 
final includeLocationHistory = true; // bool | 

try {
    final result = api_instance.searchDrivers(keyword, truckType, status, zone, licensePlate, includeLocationHistory);
    print(result);
} catch (e) {
    print('Exception when calling ClientDriverIntegrationControllerApi->searchDrivers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **keyword** | **String**|  | [optional] 
 **truckType** | **String**|  | [optional] 
 **status** | **String**|  | [optional] 
 **zone** | **String**|  | [optional] 
 **licensePlate** | **String**|  | [optional] 
 **includeLocationHistory** | **bool**|  | [optional] [default to false]

### Return type

[**List<DriverDto>**](DriverDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

