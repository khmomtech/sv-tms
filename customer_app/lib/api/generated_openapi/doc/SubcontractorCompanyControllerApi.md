# openapi.api.SubcontractorCompanyControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**create**](SubcontractorCompanyControllerApi.md#create) | **POST** /api/subcontractors | 
[**deactivate**](SubcontractorCompanyControllerApi.md#deactivate) | **PATCH** /api/subcontractors/{id}/deactivate | 
[**delete**](SubcontractorCompanyControllerApi.md#delete) | **DELETE** /api/subcontractors/{id} | 
[**generateCode**](SubcontractorCompanyControllerApi.md#generatecode) | **GET** /api/subcontractors/generate-code | 
[**getActive**](SubcontractorCompanyControllerApi.md#getactive) | **GET** /api/subcontractors/active | 
[**getAll**](SubcontractorCompanyControllerApi.md#getall) | **GET** /api/subcontractors | 
[**getByCode**](SubcontractorCompanyControllerApi.md#getbycode) | **GET** /api/subcontractors/code/{code} | 
[**getById**](SubcontractorCompanyControllerApi.md#getbyid) | **GET** /api/subcontractors/{id} | 
[**getByType**](SubcontractorCompanyControllerApi.md#getbytype) | **GET** /api/subcontractors/type/{type} | 
[**search**](SubcontractorCompanyControllerApi.md#search) | **GET** /api/subcontractors/search | 
[**update**](SubcontractorCompanyControllerApi.md#update) | **PUT** /api/subcontractors/{id} | 


# **create**
> ApiResponsePartnerCompany create(partnerCompany)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();
final partnerCompany = PartnerCompany(); // PartnerCompany | 

try {
    final result = api_instance.create(partnerCompany);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->create: $e\n');
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

# **deactivate**
> ApiResponseVoid deactivate(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deactivate(id);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->deactivate: $e\n');
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

# **delete**
> ApiResponseVoid delete(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.delete(id);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->delete: $e\n');
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

# **generateCode**
> ApiResponseString generateCode()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();

try {
    final result = api_instance.generateCode();
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->generateCode: $e\n');
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

# **getActive**
> ApiResponseListPartnerCompany getActive()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();

try {
    final result = api_instance.getActive();
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->getActive: $e\n');
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

# **getAll**
> ApiResponseListPartnerCompany getAll()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();

try {
    final result = api_instance.getAll();
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->getAll: $e\n');
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

# **getByCode**
> ApiResponsePartnerCompany getByCode(code)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();
final code = code_example; // String | 

try {
    final result = api_instance.getByCode(code);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->getByCode: $e\n');
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

# **getById**
> ApiResponsePartnerCompany getById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getById(id);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->getById: $e\n');
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

# **getByType**
> ApiResponseListPartnerCompany getByType(type)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();
final type = type_example; // String | 

try {
    final result = api_instance.getByType(type);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->getByType: $e\n');
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

# **search**
> ApiResponseListPartnerCompany search(query)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();
final query = query_example; // String | 

try {
    final result = api_instance.search(query);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->search: $e\n');
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

# **update**
> ApiResponsePartnerCompany update(id, partnerCompany)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorCompanyControllerApi();
final id = 789; // int | 
final partnerCompany = PartnerCompany(); // PartnerCompany | 

try {
    final result = api_instance.update(id, partnerCompany);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorCompanyControllerApi->update: $e\n');
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

