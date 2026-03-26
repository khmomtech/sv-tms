# openapi.api.OrderAddressControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createAddress**](OrderAddressControllerApi.md#createaddress) | **POST** /api/admin/order-address | 
[**deleteAddress**](OrderAddressControllerApi.md#deleteaddress) | **DELETE** /api/admin/order-address/{id} | 
[**exportAddresses**](OrderAddressControllerApi.md#exportaddresses) | **GET** /api/admin/order-address/export | 
[**getAddressById**](OrderAddressControllerApi.md#getaddressbyid) | **GET** /api/admin/order-address/detail/{id} | 
[**importAddresses**](OrderAddressControllerApi.md#importaddresses) | **POST** /api/admin/order-address/import | 
[**searchLocations**](OrderAddressControllerApi.md#searchlocations) | **GET** /api/admin/order-address/search | 
[**updateAddress**](OrderAddressControllerApi.md#updateaddress) | **PUT** /api/admin/order-address/{id} | 


# **createAddress**
> ApiResponseOrderAddressDto createAddress(orderAddressDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = OrderAddressControllerApi();
final orderAddressDto = OrderAddressDto(); // OrderAddressDto | 

try {
    final result = api_instance.createAddress(orderAddressDto);
    print(result);
} catch (e) {
    print('Exception when calling OrderAddressControllerApi->createAddress: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **orderAddressDto** | [**OrderAddressDto**](OrderAddressDto.md)|  | 

### Return type

[**ApiResponseOrderAddressDto**](ApiResponseOrderAddressDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteAddress**
> ApiResponseString deleteAddress(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = OrderAddressControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteAddress(id);
    print(result);
} catch (e) {
    print('Exception when calling OrderAddressControllerApi->deleteAddress: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **exportAddresses**
> MultipartFile exportAddresses(customerId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = OrderAddressControllerApi();
final customerId = 789; // int | 

try {
    final result = api_instance.exportAddresses(customerId);
    print(result);
} catch (e) {
    print('Exception when calling OrderAddressControllerApi->exportAddresses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **int**|  | 

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAddressById**
> ApiResponseOrderAddressDto getAddressById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = OrderAddressControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getAddressById(id);
    print(result);
} catch (e) {
    print('Exception when calling OrderAddressControllerApi->getAddressById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseOrderAddressDto**](ApiResponseOrderAddressDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **importAddresses**
> ApiResponseString importAddresses(customerId, updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = OrderAddressControllerApi();
final customerId = 789; // int | 
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.importAddresses(customerId, updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling OrderAddressControllerApi->importAddresses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **int**|  | 
 **updateDocumentFileRequest** | [**UpdateDocumentFileRequest**](UpdateDocumentFileRequest.md)|  | [optional] 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchLocations**
> ApiResponseListOrderAddressDto searchLocations(name)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = OrderAddressControllerApi();
final name = name_example; // String | 

try {
    final result = api_instance.searchLocations(name);
    print(result);
} catch (e) {
    print('Exception when calling OrderAddressControllerApi->searchLocations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **String**|  | 

### Return type

[**ApiResponseListOrderAddressDto**](ApiResponseListOrderAddressDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateAddress**
> ApiResponseOrderAddressDto updateAddress(id, orderAddressDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = OrderAddressControllerApi();
final id = 789; // int | 
final orderAddressDto = OrderAddressDto(); // OrderAddressDto | 

try {
    final result = api_instance.updateAddress(id, orderAddressDto);
    print(result);
} catch (e) {
    print('Exception when calling OrderAddressControllerApi->updateAddress: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **orderAddressDto** | [**OrderAddressDto**](OrderAddressDto.md)|  | 

### Return type

[**ApiResponseOrderAddressDto**](ApiResponseOrderAddressDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

