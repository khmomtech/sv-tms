# openapi.api.TransportOrderControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createOrder**](TransportOrderControllerApi.md#createorder) | **POST** /api/admin/transportorders | 
[**deleteOrder**](TransportOrderControllerApi.md#deleteorder) | **DELETE** /api/admin/transportorders/{id} | 
[**filterByDateRange**](TransportOrderControllerApi.md#filterbydaterange) | **GET** /api/admin/transportorders/filter/date | 
[**filterByStatus**](TransportOrderControllerApi.md#filterbystatus) | **GET** /api/admin/transportorders/filter/status | 
[**filterOrders**](TransportOrderControllerApi.md#filterorders) | **GET** /api/admin/transportorders/filter | 
[**getAllOrderLists**](TransportOrderControllerApi.md#getallorderlists) | **GET** /api/admin/transportorders/list | 
[**getAllOrders**](TransportOrderControllerApi.md#getallorders) | **GET** /api/admin/transportorders | 
[**getOrderAddresses**](TransportOrderControllerApi.md#getorderaddresses) | **GET** /api/admin/transportorders/{id}/addresses | 
[**getOrderById**](TransportOrderControllerApi.md#getorderbyid) | **GET** /api/admin/transportorders/{id} | 
[**getOrderItems**](TransportOrderControllerApi.md#getorderitems) | **GET** /api/admin/transportorders/{id}/items | 
[**getOrdersByCustomer**](TransportOrderControllerApi.md#getordersbycustomer) | **GET** /api/admin/transportorders/customer/{customerId} | 
[**getUnscheduledOrders**](TransportOrderControllerApi.md#getunscheduledorders) | **GET** /api/admin/transportorders/unscheduled | 
[**importBulkOrders**](TransportOrderControllerApi.md#importbulkorders) | **POST** /api/admin/transportorders/import-bulk | 
[**searchOrders**](TransportOrderControllerApi.md#searchorders) | **GET** /api/admin/transportorders/search | 
[**searchOrderss**](TransportOrderControllerApi.md#searchorderss) | **GET** /api/admin/transportorders/searchs | 
[**updateOrder**](TransportOrderControllerApi.md#updateorder) | **PUT** /api/admin/transportorders/{id} | 
[**updateOrderStatus**](TransportOrderControllerApi.md#updateorderstatus) | **PUT** /api/admin/transportorders/{id}/status | 


# **createOrder**
> ApiResponseTransportOrderDto createOrder(transportOrderDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final transportOrderDto = TransportOrderDto(); // TransportOrderDto | 

try {
    final result = api_instance.createOrder(transportOrderDto);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->createOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **transportOrderDto** | [**TransportOrderDto**](TransportOrderDto.md)|  | 

### Return type

[**ApiResponseTransportOrderDto**](ApiResponseTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteOrder**
> ApiResponseString deleteOrder(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteOrder(id);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->deleteOrder: $e\n');
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

# **filterByDateRange**
> ApiResponsePageTransportOrder filterByDateRange(startDate, endDate, pageable)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final startDate = 2013-10-20; // DateTime | 
final endDate = 2013-10-20; // DateTime | 
final pageable = ; // Pageable | 

try {
    final result = api_instance.filterByDateRange(startDate, endDate, pageable);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->filterByDateRange: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **startDate** | **DateTime**|  | 
 **endDate** | **DateTime**|  | 
 **pageable** | [**Pageable**](.md)|  | 

### Return type

[**ApiResponsePageTransportOrder**](ApiResponsePageTransportOrder.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **filterByStatus**
> ApiResponsePageTransportOrder filterByStatus(status, pageable)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final status = status_example; // String | 
final pageable = ; // Pageable | 

try {
    final result = api_instance.filterByStatus(status, pageable);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->filterByStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | 
 **pageable** | [**Pageable**](.md)|  | 

### Return type

[**ApiResponsePageTransportOrder**](ApiResponsePageTransportOrder.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **filterOrders**
> ApiResponsePageTransportOrderDto filterOrders(pageable, query, status, fromDate, toDate)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final pageable = ; // Pageable | 
final query = query_example; // String | 
final status = status_example; // String | 
final fromDate = 2013-10-20; // DateTime | 
final toDate = 2013-10-20; // DateTime | 

try {
    final result = api_instance.filterOrders(pageable, query, status, fromDate, toDate);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->filterOrders: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 
 **query** | **String**|  | [optional] 
 **status** | **String**|  | [optional] 
 **fromDate** | **DateTime**|  | [optional] 
 **toDate** | **DateTime**|  | [optional] 

### Return type

[**ApiResponsePageTransportOrderDto**](ApiResponsePageTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllOrderLists**
> ApiResponseListTransportOrderDto getAllOrderLists()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();

try {
    final result = api_instance.getAllOrderLists();
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->getAllOrderLists: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListTransportOrderDto**](ApiResponseListTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllOrders**
> ApiResponsePageTransportOrderDto getAllOrders(pageable)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final pageable = ; // Pageable | 

try {
    final result = api_instance.getAllOrders(pageable);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->getAllOrders: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 

### Return type

[**ApiResponsePageTransportOrderDto**](ApiResponsePageTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOrderAddresses**
> ApiResponseListOrderAddress getOrderAddresses(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getOrderAddresses(id);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->getOrderAddresses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseListOrderAddress**](ApiResponseListOrderAddress.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOrderById**
> ApiResponseTransportOrderDto getOrderById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getOrderById(id);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->getOrderById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseTransportOrderDto**](ApiResponseTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOrderItems**
> ApiResponseListOrderItem getOrderItems(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getOrderItems(id);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->getOrderItems: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponseListOrderItem**](ApiResponseListOrderItem.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getOrdersByCustomer**
> ApiResponseListTransportOrderDto getOrdersByCustomer(customerId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final customerId = 789; // int | 

try {
    final result = api_instance.getOrdersByCustomer(customerId);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->getOrdersByCustomer: $e\n');
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

# **getUnscheduledOrders**
> ApiResponseListTransportOrderDto getUnscheduledOrders()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();

try {
    final result = api_instance.getUnscheduledOrders();
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->getUnscheduledOrders: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListTransportOrderDto**](ApiResponseListTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **importBulkOrders**
> ApiResponseObject importBulkOrders(updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.importBulkOrders(updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->importBulkOrders: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateDocumentFileRequest** | [**UpdateDocumentFileRequest**](UpdateDocumentFileRequest.md)|  | [optional] 

### Return type

[**ApiResponseObject**](ApiResponseObject.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchOrders**
> ApiResponsePageTransportOrderDto searchOrders(query, pageable)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final query = query_example; // String | 
final pageable = ; // Pageable | 

try {
    final result = api_instance.searchOrders(query, pageable);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->searchOrders: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **query** | **String**|  | 
 **pageable** | [**Pageable**](.md)|  | 

### Return type

[**ApiResponsePageTransportOrderDto**](ApiResponsePageTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchOrderss**
> ApiResponseListTransportOrderDto searchOrderss(query)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final query = query_example; // String | 

try {
    final result = api_instance.searchOrderss(query);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->searchOrderss: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **query** | **String**|  | 

### Return type

[**ApiResponseListTransportOrderDto**](ApiResponseListTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateOrder**
> ApiResponseTransportOrderDto updateOrder(id, updateTransportOrderDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final id = 789; // int | 
final updateTransportOrderDto = UpdateTransportOrderDto(); // UpdateTransportOrderDto | 

try {
    final result = api_instance.updateOrder(id, updateTransportOrderDto);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->updateOrder: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **updateTransportOrderDto** | [**UpdateTransportOrderDto**](UpdateTransportOrderDto.md)|  | 

### Return type

[**ApiResponseTransportOrderDto**](ApiResponseTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateOrderStatus**
> ApiResponseTransportOrderDto updateOrderStatus(id, status)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = TransportOrderControllerApi();
final id = 789; // int | 
final status = status_example; // String | 

try {
    final result = api_instance.updateOrderStatus(id, status);
    print(result);
} catch (e) {
    print('Exception when calling TransportOrderControllerApi->updateOrderStatus: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **status** | **String**|  | 

### Return type

[**ApiResponseTransportOrderDto**](ApiResponseTransportOrderDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

