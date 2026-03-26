# openapi.api.ItemControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**bulkImport**](ItemControllerApi.md#bulkimport) | **POST** /api/admin/items/bulk-import | 
[**createItem**](ItemControllerApi.md#createitem) | **POST** /api/admin/items | 
[**deleteItem**](ItemControllerApi.md#deleteitem) | **DELETE** /api/admin/items/{id} | 
[**getAllItems**](ItemControllerApi.md#getallitems) | **GET** /api/admin/items | 
[**getItemById**](ItemControllerApi.md#getitembyid) | **GET** /api/admin/items/{id} | 
[**searchItems**](ItemControllerApi.md#searchitems) | **GET** /api/admin/items/search | 
[**updateItem**](ItemControllerApi.md#updateitem) | **PUT** /api/admin/items/{id} | 


# **bulkImport**
> ApiResponseListItemDto bulkImport(itemDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ItemControllerApi();
final itemDto = [List<ItemDto>()]; // List<ItemDto> | 

try {
    final result = api_instance.bulkImport(itemDto);
    print(result);
} catch (e) {
    print('Exception when calling ItemControllerApi->bulkImport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **itemDto** | [**List<ItemDto>**](ItemDto.md)|  | 

### Return type

[**ApiResponseListItemDto**](ApiResponseListItemDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createItem**
> ApiResponseItemDto createItem(itemDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ItemControllerApi();
final itemDto = ItemDto(); // ItemDto | 

try {
    final result = api_instance.createItem(itemDto);
    print(result);
} catch (e) {
    print('Exception when calling ItemControllerApi->createItem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **itemDto** | [**ItemDto**](ItemDto.md)|  | 

### Return type

[**ApiResponseItemDto**](ApiResponseItemDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteItem**
> deleteItem(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ItemControllerApi();
final id = 789; // int | 

try {
    api_instance.deleteItem(id);
} catch (e) {
    print('Exception when calling ItemControllerApi->deleteItem: $e\n');
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

# **getAllItems**
> List<ItemDto> getAllItems()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ItemControllerApi();

try {
    final result = api_instance.getAllItems();
    print(result);
} catch (e) {
    print('Exception when calling ItemControllerApi->getAllItems: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<ItemDto>**](ItemDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getItemById**
> ItemDto getItemById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ItemControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getItemById(id);
    print(result);
} catch (e) {
    print('Exception when calling ItemControllerApi->getItemById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ItemDto**](ItemDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchItems**
> List<ItemDto> searchItems(keyword)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ItemControllerApi();
final keyword = keyword_example; // String | 

try {
    final result = api_instance.searchItems(keyword);
    print(result);
} catch (e) {
    print('Exception when calling ItemControllerApi->searchItems: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **keyword** | **String**|  | 

### Return type

[**List<ItemDto>**](ItemDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateItem**
> ApiResponseItemDto updateItem(id, itemDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ItemControllerApi();
final id = 789; // int | 
final itemDto = ItemDto(); // ItemDto | 

try {
    final result = api_instance.updateItem(id, itemDto);
    print(result);
} catch (e) {
    print('Exception when calling ItemControllerApi->updateItem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **itemDto** | [**ItemDto**](ItemDto.md)|  | 

### Return type

[**ApiResponseItemDto**](ApiResponseItemDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

