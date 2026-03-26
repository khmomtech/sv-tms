# openapi.api.HealthControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**detailedHealth**](HealthControllerApi.md#detailedhealth) | **GET** /api/health/detailed | 
[**health**](HealthControllerApi.md#health) | **GET** /api/health | 


# **detailedHealth**
> Map<String, Object> detailedHealth()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = HealthControllerApi();

try {
    final result = api_instance.detailedHealth();
    print(result);
} catch (e) {
    print('Exception when calling HealthControllerApi->detailedHealth: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, Object>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **health**
> Map<String, Object> health()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = HealthControllerApi();

try {
    final result = api_instance.health();
    print(result);
} catch (e) {
    print('Exception when calling HealthControllerApi->health: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**Map<String, Object>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

