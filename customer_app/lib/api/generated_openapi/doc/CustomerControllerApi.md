# openapi.api.CustomerControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createCustomer**](CustomerControllerApi.md#createcustomer) | **POST** /api/admin/customers | 
[**createCustomerAccount**](CustomerControllerApi.md#createcustomeraccount) | **POST** /api/admin/customers/{id}/account | 
[**deleteCustomer**](CustomerControllerApi.md#deletecustomer) | **DELETE** /api/admin/customers/{id} | 
[**filterCustomers**](CustomerControllerApi.md#filtercustomers) | **GET** /api/admin/customers/filter | 
[**getAllCustomers**](CustomerControllerApi.md#getallcustomers) | **GET** /api/admin/customers | 
[**getCustomerById**](CustomerControllerApi.md#getcustomerbyid) | **GET** /api/admin/customers/{id} | 
[**getCustomerWithAddresses**](CustomerControllerApi.md#getcustomerwithaddresses) | **GET** /api/admin/customers/{id}/addresses | 
[**importCustomers**](CustomerControllerApi.md#importcustomers) | **POST** /api/admin/customers/import | 
[**searchCustomers**](CustomerControllerApi.md#searchcustomers) | **GET** /api/admin/customers/search | 
[**updateCustomer**](CustomerControllerApi.md#updatecustomer) | **PUT** /api/admin/customers/{id} | 


# **createCustomer**
> ApiResponseCustomerDto createCustomer(customerDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final customerDto = CustomerDto(); // CustomerDto | 

try {
    final result = api_instance.createCustomer(customerDto);
    print(result);
} catch (e) {
    print('Exception when calling CustomerControllerApi->createCustomer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerDto** | [**CustomerDto**](CustomerDto.md)|  | 

### Return type

[**ApiResponseCustomerDto**](ApiResponseCustomerDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createCustomerAccount**
> ApiResponseMapStringObject createCustomerAccount(id, createAccountRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final id = 789; // int | 
final createAccountRequest = CreateAccountRequest(); // CreateAccountRequest | 

try {
    final result = api_instance.createCustomerAccount(id, createAccountRequest);
    print(result);
} catch (e) {
    print('Exception when calling CustomerControllerApi->createCustomerAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **createAccountRequest** | [**CreateAccountRequest**](CreateAccountRequest.md)|  | 

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteCustomer**
> deleteCustomer(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final id = 789; // int | 

try {
    api_instance.deleteCustomer(id);
} catch (e) {
    print('Exception when calling CustomerControllerApi->deleteCustomer: $e\n');
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

# **filterCustomers**
> ApiResponsePageCustomer filterCustomers(customerCode, name, phone, email, type, status, page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final customerCode = customerCode_example; // String | 
final name = name_example; // String | 
final phone = phone_example; // String | 
final email = email_example; // String | 
final type = type_example; // String | 
final status = status_example; // String | 
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.filterCustomers(customerCode, name, phone, email, type, status, page, size);
    print(result);
} catch (e) {
    print('Exception when calling CustomerControllerApi->filterCustomers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **customerCode** | **String**|  | [optional] 
 **name** | **String**|  | [optional] 
 **phone** | **String**|  | [optional] 
 **email** | **String**|  | [optional] 
 **type** | **String**|  | [optional] 
 **status** | **String**|  | [optional] 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 10]

### Return type

[**ApiResponsePageCustomer**](ApiResponsePageCustomer.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllCustomers**
> ApiResponsePageCustomer getAllCustomers(page, size)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final page = 56; // int | 
final size = 56; // int | 

try {
    final result = api_instance.getAllCustomers(page, size);
    print(result);
} catch (e) {
    print('Exception when calling CustomerControllerApi->getAllCustomers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 10]

### Return type

[**ApiResponsePageCustomer**](ApiResponsePageCustomer.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCustomerById**
> ApiResponseMapStringObject getCustomerById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getCustomerById(id);
    print(result);
} catch (e) {
    print('Exception when calling CustomerControllerApi->getCustomerById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCustomerWithAddresses**
> ApiResponseMapStringObject getCustomerWithAddresses(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getCustomerWithAddresses(id);
    print(result);
} catch (e) {
    print('Exception when calling CustomerControllerApi->getCustomerWithAddresses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseMapStringObject**](ApiResponseMapStringObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **importCustomers**
> ApiResponseListCustomerDto importCustomers(updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.importCustomers(updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling CustomerControllerApi->importCustomers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateDocumentFileRequest** | [**UpdateDocumentFileRequest**](UpdateDocumentFileRequest.md)|  | [optional] 

### Return type

[**ApiResponseListCustomerDto**](ApiResponseListCustomerDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchCustomers**
> ApiResponseListCustomer searchCustomers(keyword)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final keyword = keyword_example; // String | 

try {
    final result = api_instance.searchCustomers(keyword);
    print(result);
} catch (e) {
    print('Exception when calling CustomerControllerApi->searchCustomers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **keyword** | **String**|  | 

### Return type

[**ApiResponseListCustomer**](ApiResponseListCustomer.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateCustomer**
> ApiResponseCustomerDto updateCustomer(id, customerDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = CustomerControllerApi();
final id = 789; // int | 
final customerDto = CustomerDto(); // CustomerDto | 

try {
    final result = api_instance.updateCustomer(id, customerDto);
    print(result);
} catch (e) {
    print('Exception when calling CustomerControllerApi->updateCustomer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **customerDto** | [**CustomerDto**](CustomerDto.md)|  | 

### Return type

[**ApiResponseCustomerDto**](ApiResponseCustomerDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

