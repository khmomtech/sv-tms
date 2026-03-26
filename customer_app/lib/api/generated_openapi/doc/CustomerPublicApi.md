# openapi.api.CustomerPublicApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getOrderForCustomer**](CustomerPublicApi.md#getorderforcustomer) | **GET** /api/customer/{customerId}/orders/{orderId} | Get a single order for a customer
[**listAddressesForCustomer**](CustomerPublicApi.md#listaddressesforcustomer) | **GET** /api/customer/{customerId}/addresses | List addresses for a customer
[**listOrdersForCustomer**](CustomerPublicApi.md#listordersforcustomer) | **GET** /api/customer/{customerId}/orders | List orders for a customer


# **getOrderForCustomer**
> ApiResponseTransportOrderDto getOrderForCustomer(customerId, orderId)

Get a single order for a customer

Returns a single transport order if it belongs to the customer

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerPublicApi();
final customerId = 789; // int | 
final orderId = 789; // int | 

try {
    final result = api_instance.getOrderForCustomer(customerId, orderId);
    print(result);
} catch (e) {
    print('Exception when calling CustomerPublicApi->getOrderForCustomer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **int**|  | 
 **orderId** | **int**|  | 

### Return type

[**ApiResponseTransportOrderDto**](ApiResponseTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAddressesForCustomer**
> ApiResponseListOrderAddressDto listAddressesForCustomer(customerId)

List addresses for a customer

Returns order addresses registered under the specified customer

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerPublicApi();
final customerId = 789; // int | 

try {
    final result = api_instance.listAddressesForCustomer(customerId);
    print(result);
} catch (e) {
    print('Exception when calling CustomerPublicApi->listAddressesForCustomer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **int**|  | 

### Return type

[**ApiResponseListOrderAddressDto**](ApiResponseListOrderAddressDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listOrdersForCustomer**
> ApiResponseListTransportOrderDto listOrdersForCustomer(customerId)

List orders for a customer

Returns transport orders belonging to the specified customer

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerPublicApi();
final customerId = 789; // int | 

try {
    final result = api_instance.listOrdersForCustomer(customerId);
    print(result);
} catch (e) {
    print('Exception when calling CustomerPublicApi->listOrdersForCustomer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **int**|  | 

### Return type

[**ApiResponseListTransportOrderDto**](ApiResponseListTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

