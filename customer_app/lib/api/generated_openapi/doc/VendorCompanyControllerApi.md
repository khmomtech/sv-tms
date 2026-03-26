# openapi.api.VendorCompanyControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createVendor**](VendorCompanyControllerApi.md#createvendor) | **POST** /api/vendors | 
[**deactivateVendor**](VendorCompanyControllerApi.md#deactivatevendor) | **PATCH** /api/vendors/{id}/deactivate | 
[**deleteVendor**](VendorCompanyControllerApi.md#deletevendor) | **DELETE** /api/vendors/{id} | 
[**generateVendorCompanyCode**](VendorCompanyControllerApi.md#generatevendorcompanycode) | **GET** /api/vendors/generate-code | 
[**getActiveVendors**](VendorCompanyControllerApi.md#getactivevendors) | **GET** /api/vendors/active | 
[**getAllVendors**](VendorCompanyControllerApi.md#getallvendors) | **GET** /api/vendors | 
[**getVendorByCode**](VendorCompanyControllerApi.md#getvendorbycode) | **GET** /api/vendors/code/{code} | 
[**getVendorById**](VendorCompanyControllerApi.md#getvendorbyid) | **GET** /api/vendors/{id} | 
[**getVendorsByType**](VendorCompanyControllerApi.md#getvendorsbytype) | **GET** /api/vendors/type/{type} | 
[**licenseExists**](VendorCompanyControllerApi.md#licenseexists) | **GET** /api/vendors/license/{license}/exists | 
[**searchVendors**](VendorCompanyControllerApi.md#searchvendors) | **GET** /api/vendors/search | 
[**updateVendor**](VendorCompanyControllerApi.md#updatevendor) | **PUT** /api/vendors/{id} | 


# **createVendor**
> ApiResponsePartnerCompany createVendor(partnerCompany)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();
final partnerCompany = PartnerCompany(); // PartnerCompany | 

try {
    final result = api_instance.createVendor(partnerCompany);
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->createVendor: $e\n');
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

# **deactivateVendor**
> ApiResponseVoid deactivateVendor(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deactivateVendor(id);
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->deactivateVendor: $e\n');
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

# **deleteVendor**
> ApiResponseVoid deleteVendor(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.deleteVendor(id);
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->deleteVendor: $e\n');
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

# **generateVendorCompanyCode**
> ApiResponseString generateVendorCompanyCode()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();

try {
    final result = api_instance.generateVendorCompanyCode();
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->generateVendorCompanyCode: $e\n');
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

# **getActiveVendors**
> ApiResponseListPartnerCompany getActiveVendors()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();

try {
    final result = api_instance.getActiveVendors();
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->getActiveVendors: $e\n');
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

# **getAllVendors**
> ApiResponseListPartnerCompany getAllVendors()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();

try {
    final result = api_instance.getAllVendors();
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->getAllVendors: $e\n');
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

# **getVendorByCode**
> ApiResponsePartnerCompany getVendorByCode(code)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();
final code = code_example; // String | 

try {
    final result = api_instance.getVendorByCode(code);
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->getVendorByCode: $e\n');
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

# **getVendorById**
> ApiResponsePartnerCompany getVendorById(id)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();
final id = 789; // int | 

try {
    final result = api_instance.getVendorById(id);
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->getVendorById: $e\n');
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

# **getVendorsByType**
> ApiResponseListPartnerCompany getVendorsByType(type)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();
final type = type_example; // String | 

try {
    final result = api_instance.getVendorsByType(type);
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->getVendorsByType: $e\n');
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

# **licenseExists**
> ApiResponseBoolean licenseExists(license)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();
final license = license_example; // String | 

try {
    final result = api_instance.licenseExists(license);
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->licenseExists: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **license** | **String**|  | 

### Return type

[**ApiResponseBoolean**](ApiResponseBoolean.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchVendors**
> ApiResponseListPartnerCompany searchVendors(query)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();
final query = query_example; // String | 

try {
    final result = api_instance.searchVendors(query);
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->searchVendors: $e\n');
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

# **updateVendor**
> ApiResponsePartnerCompany updateVendor(id, partnerCompany)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorCompanyControllerApi();
final id = 789; // int | 
final partnerCompany = PartnerCompany(); // PartnerCompany | 

try {
    final result = api_instance.updateVendor(id, partnerCompany);
    print(result);
} catch (e) {
    print('Exception when calling VendorCompanyControllerApi->updateVendor: $e\n');
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

