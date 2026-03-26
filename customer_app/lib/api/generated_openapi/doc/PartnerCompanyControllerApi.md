# openapi.api.PartnerCompanyControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createPartner**](PartnerCompanyControllerApi.md#createpartner) | **POST** /api/partners | 
[**deactivatePartner**](PartnerCompanyControllerApi.md#deactivatepartner) | **PATCH** /api/partners/{id}/deactivate | 
[**deletePartner**](PartnerCompanyControllerApi.md#deletepartner) | **DELETE** /api/partners/{id} | 
[**generateCompanyCode**](PartnerCompanyControllerApi.md#generatecompanycode) | **GET** /api/partners/generate-code | 
[**getActivePartners**](PartnerCompanyControllerApi.md#getactivepartners) | **GET** /api/partners/active | 
[**getAllPartners**](PartnerCompanyControllerApi.md#getallpartners) | **GET** /api/partners | 
[**getPartnerByCode**](PartnerCompanyControllerApi.md#getpartnerbycode) | **GET** /api/partners/code/{code} | 
[**getPartnerById**](PartnerCompanyControllerApi.md#getpartnerbyid) | **GET** /api/partners/{id} | 
[**getPartnersByType**](PartnerCompanyControllerApi.md#getpartnersbytype) | **GET** /api/partners/type/{type} | 
[**searchPartners**](PartnerCompanyControllerApi.md#searchpartners) | **GET** /api/partners/search | 
[**updatePartner**](PartnerCompanyControllerApi.md#updatepartner) | **PUT** /api/partners/{id} | 


# **createPartner**
> ApiResponsePartnerCompany createPartner(partnerCompany)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();
final partnerCompany = PartnerCompany(); // PartnerCompany | 

try {
    final result = api_instance.createPartner(partnerCompany);
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->createPartner: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **partnerCompany** | [**PartnerCompany**](PartnerCompany.md)|  | 

### Return type

[**ApiResponsePartnerCompany**](ApiResponsePartnerCompany.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deactivatePartner**
> ApiResponseVoid deactivatePartner(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deactivatePartner(id);
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->deactivatePartner: $e\n');
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

# **deletePartner**
> ApiResponseVoid deletePartner(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deletePartner(id);
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->deletePartner: $e\n');
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

# **generateCompanyCode**
> ApiResponseString generateCompanyCode()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();

try {
    final result = api_instance.generateCompanyCode();
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->generateCompanyCode: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getActivePartners**
> ApiResponseListPartnerCompany getActivePartners()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();

try {
    final result = api_instance.getActivePartners();
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->getActivePartners: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListPartnerCompany**](ApiResponseListPartnerCompany.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllPartners**
> ApiResponseListPartnerCompany getAllPartners()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();

try {
    final result = api_instance.getAllPartners();
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->getAllPartners: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ApiResponseListPartnerCompany**](ApiResponseListPartnerCompany.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPartnerByCode**
> ApiResponsePartnerCompany getPartnerByCode(code)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();
final code = code_example; // String | 

try {
    final result = api_instance.getPartnerByCode(code);
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->getPartnerByCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **code** | **String**|  | 

### Return type

[**ApiResponsePartnerCompany**](ApiResponsePartnerCompany.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPartnerById**
> ApiResponsePartnerCompany getPartnerById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getPartnerById(id);
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->getPartnerById: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 

### Return type

[**ApiResponsePartnerCompany**](ApiResponsePartnerCompany.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPartnersByType**
> ApiResponseListPartnerCompany getPartnersByType(type)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();
final type = type_example; // String | 

try {
    final result = api_instance.getPartnersByType(type);
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->getPartnersByType: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String**|  | 

### Return type

[**ApiResponseListPartnerCompany**](ApiResponseListPartnerCompany.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchPartners**
> ApiResponseListPartnerCompany searchPartners(query)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();
final query = query_example; // String | 

try {
    final result = api_instance.searchPartners(query);
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->searchPartners: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **query** | **String**|  | 

### Return type

[**ApiResponseListPartnerCompany**](ApiResponseListPartnerCompany.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePartner**
> ApiResponsePartnerCompany updatePartner(id, partnerCompany)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerCompanyControllerApi();
final id = 789; // int | 
final partnerCompany = PartnerCompany(); // PartnerCompany | 

try {
    final result = api_instance.updatePartner(id, partnerCompany);
    print(result);
} catch (e) {
    print('Exception when calling PartnerCompanyControllerApi->updatePartner: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **int**|  | 
 **partnerCompany** | [**PartnerCompany**](PartnerCompany.md)|  | 

### Return type

[**ApiResponsePartnerCompany**](ApiResponsePartnerCompany.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

