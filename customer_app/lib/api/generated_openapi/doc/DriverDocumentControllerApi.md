# openapi.api.DriverDocumentControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createDocument**](DriverDocumentControllerApi.md#createdocument) | **POST** /api/admin/drivers/{driverId}/documents | 
[**deleteDocument**](DriverDocumentControllerApi.md#deletedocument) | **DELETE** /api/admin/drivers/{driverId}/documents/{documentId} | 
[**downloadDriverDocument**](DriverDocumentControllerApi.md#downloaddriverdocument) | **GET** /api/admin/drivers/{driverId}/documents/{documentId}/download | 
[**getDocument**](DriverDocumentControllerApi.md#getdocument) | **GET** /api/admin/drivers/documents/{documentId} | 
[**getDocumentAudit**](DriverDocumentControllerApi.md#getdocumentaudit) | **GET** /api/admin/drivers/{driverId}/documents/{documentId}/audit | 
[**getDocumentsByCategory**](DriverDocumentControllerApi.md#getdocumentsbycategory) | **GET** /api/admin/drivers/{driverId}/documents/category/{category} | 
[**getDriverDocuments**](DriverDocumentControllerApi.md#getdriverdocuments) | **GET** /api/admin/drivers/{driverId}/documents | 
[**getExpiredDocuments**](DriverDocumentControllerApi.md#getexpireddocuments) | **GET** /api/admin/drivers/{driverId}/documents/expired | 
[**getExpiringDocuments**](DriverDocumentControllerApi.md#getexpiringdocuments) | **GET** /api/admin/drivers/{driverId}/documents/expiring | 
[**getRequiredDocuments**](DriverDocumentControllerApi.md#getrequireddocuments) | **GET** /api/admin/drivers/{driverId}/documents/required | 
[**updateDocument**](DriverDocumentControllerApi.md#updatedocument) | **PUT** /api/admin/drivers/{driverId}/documents/{documentId} | 
[**updateDocumentFile**](DriverDocumentControllerApi.md#updatedocumentfile) | **PUT** /api/admin/drivers/{driverId}/documents/{documentId}/file | 
[**uploadDocument**](DriverDocumentControllerApi.md#uploaddocument) | **POST** /api/admin/drivers/{driverId}/documents/upload | 


# **createDocument**
> ApiResponseDriverDocument createDocument(driverId, driverDocumentCreateDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 
final driverDocumentCreateDto = DriverDocumentCreateDto(); // DriverDocumentCreateDto | 

try {
    final result = api_instance.createDocument(driverId, driverDocumentCreateDto);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->createDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **driverDocumentCreateDto** | [**DriverDocumentCreateDto**](DriverDocumentCreateDto.md)|  | 

### Return type

[**ApiResponseDriverDocument**](ApiResponseDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDocument**
> ApiResponseString deleteDocument(driverId, documentId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 
final documentId = 789; // int | 

try {
    final result = api_instance.deleteDocument(driverId, documentId);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->deleteDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **documentId** | **int**|  | 

### Return type

[**ApiResponseString**](ApiResponseString.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **downloadDriverDocument**
> MultipartFile downloadDriverDocument(driverId, documentId, disposition)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 
final documentId = 789; // int | 
final disposition = disposition_example; // String | 

try {
    final result = api_instance.downloadDriverDocument(driverId, documentId, disposition);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->downloadDriverDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **documentId** | **int**|  | 
 **disposition** | **String**|  | [optional] [default to 'inline']

### Return type

[**MultipartFile**](MultipartFile.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDocument**
> ApiResponseDriverDocument getDocument(documentId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final documentId = 789; // int | 

try {
    final result = api_instance.getDocument(documentId);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->getDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **documentId** | **int**|  | 

### Return type

[**ApiResponseDriverDocument**](ApiResponseDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDocumentAudit**
> ApiResponseDocumentAuditDto getDocumentAudit(driverId, documentId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 
final documentId = 789; // int | 

try {
    final result = api_instance.getDocumentAudit(driverId, documentId);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->getDocumentAudit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **documentId** | **int**|  | 

### Return type

[**ApiResponseDocumentAuditDto**](ApiResponseDocumentAuditDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDocumentsByCategory**
> ApiResponseListDriverDocument getDocumentsByCategory(driverId, category)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 
final category = category_example; // String | 

try {
    final result = api_instance.getDocumentsByCategory(driverId, category);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->getDocumentsByCategory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **category** | **String**|  | 

### Return type

[**ApiResponseListDriverDocument**](ApiResponseListDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getDriverDocuments**
> ApiResponseListDriverDocument getDriverDocuments(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getDriverDocuments(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->getDriverDocuments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseListDriverDocument**](ApiResponseListDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getExpiredDocuments**
> ApiResponseListDriverDocument getExpiredDocuments(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getExpiredDocuments(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->getExpiredDocuments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseListDriverDocument**](ApiResponseListDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getExpiringDocuments**
> ApiResponseListDriverDocument getExpiringDocuments(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getExpiringDocuments(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->getExpiringDocuments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseListDriverDocument**](ApiResponseListDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRequiredDocuments**
> ApiResponseListDriverDocument getRequiredDocuments(driverId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 

try {
    final result = api_instance.getRequiredDocuments(driverId);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->getRequiredDocuments: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 

### Return type

[**ApiResponseListDriverDocument**](ApiResponseListDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDocument**
> ApiResponseDriverDocument updateDocument(driverId, documentId, driverDocumentUpdateDto)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 
final documentId = 789; // int | 
final driverDocumentUpdateDto = DriverDocumentUpdateDto(); // DriverDocumentUpdateDto | 

try {
    final result = api_instance.updateDocument(driverId, documentId, driverDocumentUpdateDto);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->updateDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **documentId** | **int**|  | 
 **driverDocumentUpdateDto** | [**DriverDocumentUpdateDto**](DriverDocumentUpdateDto.md)|  | 

### Return type

[**ApiResponseDriverDocument**](ApiResponseDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateDocumentFile**
> ApiResponseDriverDocument updateDocumentFile(driverId, documentId, name, category, expiryDate, description, isRequired, updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 
final documentId = 789; // int | 
final name = name_example; // String | 
final category = category_example; // String | 
final expiryDate = expiryDate_example; // String | 
final description = description_example; // String | 
final isRequired = true; // bool | 
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.updateDocumentFile(driverId, documentId, name, category, expiryDate, description, isRequired, updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->updateDocumentFile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **documentId** | **int**|  | 
 **name** | **String**|  | [optional] 
 **category** | **String**|  | [optional] 
 **expiryDate** | **String**|  | [optional] 
 **description** | **String**|  | [optional] 
 **isRequired** | **bool**|  | [optional] 
 **updateDocumentFileRequest** | [**UpdateDocumentFileRequest**](UpdateDocumentFileRequest.md)|  | [optional] 

### Return type

[**ApiResponseDriverDocument**](ApiResponseDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **uploadDocument**
> ApiResponseDriverDocument uploadDocument(driverId, name, category, expiryDate, description, isRequired, updateDocumentFileRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DriverDocumentControllerApi();
final driverId = 789; // int | 
final name = name_example; // String | 
final category = category_example; // String | 
final expiryDate = expiryDate_example; // String | 
final description = description_example; // String | 
final isRequired = true; // bool | 
final updateDocumentFileRequest = UpdateDocumentFileRequest(); // UpdateDocumentFileRequest | 

try {
    final result = api_instance.uploadDocument(driverId, name, category, expiryDate, description, isRequired, updateDocumentFileRequest);
    print(result);
} catch (e) {
    print('Exception when calling DriverDocumentControllerApi->uploadDocument: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **driverId** | **int**|  | 
 **name** | **String**|  | [optional] 
 **category** | **String**|  | [optional] 
 **expiryDate** | **String**|  | [optional] 
 **description** | **String**|  | [optional] 
 **isRequired** | **bool**|  | [optional] 
 **updateDocumentFileRequest** | [**UpdateDocumentFileRequest**](UpdateDocumentFileRequest.md)|  | [optional] 

### Return type

[**ApiResponseDriverDocument**](ApiResponseDriverDocument.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

