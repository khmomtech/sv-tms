# openapi.api.CountsControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**driversCount**](CountsControllerApi.md#driverscount) | **GET** /api/public/counts/drivers | 
[**driversCount1**](CountsControllerApi.md#driverscount1) | **GET** /api/drivers/count | 
[**vehiclesCount**](CountsControllerApi.md#vehiclescount) | **GET** /api/public/counts/vehicles | 
[**vehiclesCount1**](CountsControllerApi.md#vehiclescount1) | **GET** /api/vehicles/count | 
[**workOrdersCount**](CountsControllerApi.md#workorderscount) | **GET** /api/maintenance/work-orders/count | 
[**workOrdersCount1**](CountsControllerApi.md#workorderscount1) | **GET** /api/public/counts/work-orders | 


# **driversCount**
> Map<String, int> driversCount()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CountsControllerApi();

try {
    final result = api_instance.driversCount();
    print(result);
} catch (e) {
    print('Exception when calling CountsControllerApi->driversCount: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, int>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **driversCount1**
> Map<String, int> driversCount1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CountsControllerApi();

try {
    final result = api_instance.driversCount1();
    print(result);
} catch (e) {
    print('Exception when calling CountsControllerApi->driversCount1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, int>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vehiclesCount**
> Map<String, int> vehiclesCount()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CountsControllerApi();

try {
    final result = api_instance.vehiclesCount();
    print(result);
} catch (e) {
    print('Exception when calling CountsControllerApi->vehiclesCount: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, int>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **vehiclesCount1**
> Map<String, int> vehiclesCount1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CountsControllerApi();

try {
    final result = api_instance.vehiclesCount1();
    print(result);
} catch (e) {
    print('Exception when calling CountsControllerApi->vehiclesCount1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, int>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **workOrdersCount**
> Map<String, int> workOrdersCount()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CountsControllerApi();

try {
    final result = api_instance.workOrdersCount();
    print(result);
} catch (e) {
    print('Exception when calling CountsControllerApi->workOrdersCount: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, int>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **workOrdersCount1**
> Map<String, int> workOrdersCount1()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CountsControllerApi();

try {
    final result = api_instance.workOrdersCount1();
    print(result);
} catch (e) {
    print('Exception when calling CountsControllerApi->workOrdersCount1: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, int>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

