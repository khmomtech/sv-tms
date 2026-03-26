# openapi.api.MaintenanceTaskTypeControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create1**](MaintenanceTaskTypeControllerApi.md#create1) | **POST** /api/admin/maintenance-task-types | 
[**delete1**](MaintenanceTaskTypeControllerApi.md#delete1) | **DELETE** /api/admin/maintenance-task-types/{id} | 
[**getAll1**](MaintenanceTaskTypeControllerApi.md#getall1) | **GET** /api/admin/maintenance-task-types/list | 
[**getAllNoPage**](MaintenanceTaskTypeControllerApi.md#getallnopage) | **GET** /api/admin/maintenance-task-types/all | 
[**getById2**](MaintenanceTaskTypeControllerApi.md#getbyid2) | **GET** /api/admin/maintenance-task-types/{id} | 
[**update1**](MaintenanceTaskTypeControllerApi.md#update1) | **PUT** /api/admin/maintenance-task-types/{id} | 


# **create1**
> ApiResponseMaintenanceTaskTypeDto create1(maintenanceTaskTypeDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskTypeControllerApi();
final maintenanceTaskTypeDto = MaintenanceTaskTypeDto(); // MaintenanceTaskTypeDto | 

try {
    final result = api_instance.create1(maintenanceTaskTypeDto);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskTypeControllerApi->create1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **maintenanceTaskTypeDto** | [**MaintenanceTaskTypeDto**](MaintenanceTaskTypeDto.md)|  | 

### Return type

[**ApiResponseMaintenanceTaskTypeDto**](ApiResponseMaintenanceTaskTypeDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete1**
> ApiResponseVoid delete1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskTypeControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.delete1(id);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskTypeControllerApi->delete1: $e\n');
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

# **getAll1**
> ApiResponsePageMaintenanceTaskTypeDto getAll1(search, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskTypeControllerApi();
final search = search_example; // String | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getAll1(search, page, size);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskTypeControllerApi->getAll1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **search** | **String**|  | [optional] [default to '']
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 10]

### Return type

[**ApiResponsePageMaintenanceTaskTypeDto**](ApiResponsePageMaintenanceTaskTypeDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllNoPage**
> ApiResponseListMaintenanceTaskTypeDto getAllNoPage()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskTypeControllerApi();

try {
    final result = api_instance.getAllNoPage();
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskTypeControllerApi->getAllNoPage: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListMaintenanceTaskTypeDto**](ApiResponseListMaintenanceTaskTypeDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getById2**
> ApiResponseMaintenanceTaskTypeDto getById2(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskTypeControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getById2(id);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskTypeControllerApi->getById2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseMaintenanceTaskTypeDto**](ApiResponseMaintenanceTaskTypeDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **update1**
> ApiResponseMaintenanceTaskTypeDto update1(id, maintenanceTaskTypeDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = MaintenanceTaskTypeControllerApi();
final id = 789; // int | 
final maintenanceTaskTypeDto = MaintenanceTaskTypeDto(); // MaintenanceTaskTypeDto | 

try {
    final result = api_instance.update1(id, maintenanceTaskTypeDto);
    print(result);
} catch (e) {
    print('Exception when calling MaintenanceTaskTypeControllerApi->update1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **maintenanceTaskTypeDto** | [**MaintenanceTaskTypeDto**](MaintenanceTaskTypeDto.md)|  | 

### Return type

[**ApiResponseMaintenanceTaskTypeDto**](ApiResponseMaintenanceTaskTypeDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

