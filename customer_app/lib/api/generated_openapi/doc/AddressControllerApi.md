# openapi.api.AddressControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteAddress1**](AddressControllerApi.md#deleteaddress1) | **DELETE** /api/admin/addresses/delete/{id} | 
[**getAddressById1**](AddressControllerApi.md#getaddressbyid1) | **GET** /api/admin/addresses/{id} | 
[**getAddressesByCustomer**](AddressControllerApi.md#getaddressesbycustomer) | **GET** /api/admin/addresses/customer/{customerId} | 
[**getAllAddresses**](AddressControllerApi.md#getalladdresses) | **GET** /api/admin/addresses/list | 
[**saveAddress**](AddressControllerApi.md#saveaddress) | **POST** /api/admin/addresses/save | 
[**updateAddress1**](AddressControllerApi.md#updateaddress1) | **PUT** /api/admin/addresses/update/{id} | 


# **deleteAddress1**
> deleteAddress1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AddressControllerApi();
final id = 789; // int | 

try {
    api_instance.deleteAddress1(id);
} catch (e) {
    print('Exception when calling AddressControllerApi->deleteAddress1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAddressById1**
> Address getAddressById1(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AddressControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getAddressById1(id);
    print(result);
} catch (e) {
    print('Exception when calling AddressControllerApi->getAddressById1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**Address**](Address.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAddressesByCustomer**
> List<Address> getAddressesByCustomer(customerId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AddressControllerApi();
final customerId = 789; // int | 

try {
    final result = api_instance.getAddressesByCustomer(customerId);
    print(result);
} catch (e) {
    print('Exception when calling AddressControllerApi->getAddressesByCustomer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerId** | **int**|  | 

### Return type

[**List<Address>**](Address.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllAddresses**
> List<Address> getAllAddresses()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AddressControllerApi();

try {
    final result = api_instance.getAllAddresses();
    print(result);
} catch (e) {
    print('Exception when calling AddressControllerApi->getAllAddresses: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Address>**](Address.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **saveAddress**
> Address saveAddress(address)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AddressControllerApi();
final address = Address(); // Address | 

try {
    final result = api_instance.saveAddress(address);
    print(result);
} catch (e) {
    print('Exception when calling AddressControllerApi->saveAddress: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **address** | [**Address**](Address.md)|  | 

### Return type

[**Address**](Address.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateAddress1**
> Address updateAddress1(id, address)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AddressControllerApi();
final id = 789; // int | 
final address = Address(); // Address | 

try {
    final result = api_instance.updateAddress1(id, address);
    print(result);
} catch (e) {
    print('Exception when calling AddressControllerApi->updateAddress1: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **address** | [**Address**](Address.md)|  | 

### Return type

[**Address**](Address.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

