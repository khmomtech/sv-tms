# openapi.api.PartsMasterControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**countActiveParts**](PartsMasterControllerApi.md#countactiveparts) | **GET** /api/admin/parts/stats/active-count | 
[**createPart**](PartsMasterControllerApi.md#createpart) | **POST** /api/admin/parts | 
[**deactivatePart**](PartsMasterControllerApi.md#deactivatepart) | **PATCH** /api/admin/parts/{id}/deactivate | 
[**deletePart**](PartsMasterControllerApi.md#deletepart) | **DELETE** /api/admin/parts/{id} | 
[**getAllCategories**](PartsMasterControllerApi.md#getallcategories) | **GET** /api/admin/parts/categories | 
[**getAllParts**](PartsMasterControllerApi.md#getallparts) | **GET** /api/admin/parts | 
[**getPartByCode**](PartsMasterControllerApi.md#getpartbycode) | **GET** /api/admin/parts/code/{partCode} | 
[**getPartById**](PartsMasterControllerApi.md#getpartbyid) | **GET** /api/admin/parts/{id} | 
[**getPartsByCategory**](PartsMasterControllerApi.md#getpartsbycategory) | **GET** /api/admin/parts/category/{category} | 
[**searchParts**](PartsMasterControllerApi.md#searchparts) | **GET** /api/admin/parts/search | 
[**updatePart**](PartsMasterControllerApi.md#updatepart) | **PUT** /api/admin/parts/{id} | 


# **countActiveParts**
> int countActiveParts()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();

try {
    final result = api_instance.countActiveParts();
    print(result);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->countActiveParts: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**int**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createPart**
> PartsMasterDto createPart(partsMasterDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();
final partsMasterDto = PartsMasterDto(); // PartsMasterDto | 

try {
    final result = api_instance.createPart(partsMasterDto);
    print(result);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->createPart: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **partsMasterDto** | [**PartsMasterDto**](PartsMasterDto.md)|  | 

### Return type

[**PartsMasterDto**](PartsMasterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deactivatePart**
> deactivatePart(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();
final id = 789; // int | 

try {
    api_instance.deactivatePart(id);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->deactivatePart: $e\n');
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

# **deletePart**
> deletePart(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();
final id = 789; // int | 

try {
    api_instance.deletePart(id);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->deletePart: $e\n');
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

# **getAllCategories**
> List<String> getAllCategories()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();

try {
    final result = api_instance.getAllCategories();
    print(result);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->getAllCategories: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**List<String>**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllParts**
> PagePartsMasterDto getAllParts(pageable, active)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();
final pageable = ; // Pageable | 
final active = true; // bool | 

try {
    final result = api_instance.getAllParts(pageable, active);
    print(result);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->getAllParts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 
 **active** | **bool**|  | [optional] 

### Return type

[**PagePartsMasterDto**](PagePartsMasterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPartByCode**
> PartsMasterDto getPartByCode(partCode)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();
final partCode = partCode_example; // String | 

try {
    final result = api_instance.getPartByCode(partCode);
    print(result);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->getPartByCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **partCode** | **String**|  | 

### Return type

[**PartsMasterDto**](PartsMasterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPartById**
> PartsMasterDto getPartById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getPartById(id);
    print(result);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->getPartById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**PartsMasterDto**](PartsMasterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPartsByCategory**
> PagePartsMasterDto getPartsByCategory(category, pageable, active)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();
final category = category_example; // String | 
final pageable = ; // Pageable | 
final active = true; // bool | 

try {
    final result = api_instance.getPartsByCategory(category, pageable, active);
    print(result);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->getPartsByCategory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **category** | **String**|  | 
 **pageable** | [**Pageable**](.md)|  | 
 **active** | **bool**|  | [optional] 

### Return type

[**PagePartsMasterDto**](PagePartsMasterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchParts**
> PagePartsMasterDto searchParts(pageable, keyword, category)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();
final pageable = ; // Pageable | 
final keyword = keyword_example; // String | 
final category = category_example; // String | 

try {
    final result = api_instance.searchParts(pageable, keyword, category);
    print(result);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->searchParts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **pageable** | [**Pageable**](.md)|  | 
 **keyword** | **String**|  | [optional] 
 **category** | **String**|  | [optional] 

### Return type

[**PagePartsMasterDto**](PagePartsMasterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePart**
> PartsMasterDto updatePart(id, partsMasterDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartsMasterControllerApi();
final id = 789; // int | 
final partsMasterDto = PartsMasterDto(); // PartsMasterDto | 

try {
    final result = api_instance.updatePart(id, partsMasterDto);
    print(result);
} catch (e) {
    print('Exception when calling PartsMasterControllerApi->updatePart: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **partsMasterDto** | [**PartsMasterDto**](PartsMasterDto.md)|  | 

### Return type

[**PartsMasterDto**](PartsMasterDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

