# openapi.api.PartnerAdminControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assignAdmin2**](PartnerAdminControllerApi.md#assignadmin2) | **POST** /api/partner-admins | 
[**canManageDrivers2**](PartnerAdminControllerApi.md#canmanagedrivers2) | **GET** /api/partner-admins/user/{userId}/companies/{companyId}/can-manage-drivers | 
[**getAdminsByCompany2**](PartnerAdminControllerApi.md#getadminsbycompany2) | **GET** /api/partner-admins/company/{companyId} | 
[**getCompaniesByUser2**](PartnerAdminControllerApi.md#getcompaniesbyuser2) | **GET** /api/partner-admins/user/{userId} | 
[**getManagedCompanies2**](PartnerAdminControllerApi.md#getmanagedcompanies2) | **GET** /api/partner-admins/user/{userId}/managed-companies | 
[**getPrimaryAdmin2**](PartnerAdminControllerApi.md#getprimaryadmin2) | **GET** /api/partner-admins/company/{companyId}/primary | 
[**removeAdmin2**](PartnerAdminControllerApi.md#removeadmin2) | **DELETE** /api/partner-admins/{adminId} | 
[**updatePermissions2**](PartnerAdminControllerApi.md#updatepermissions2) | **PATCH** /api/partner-admins/{adminId}/permissions | 


# **assignAdmin2**
> ApiResponsePartnerAdmin assignAdmin2(assignAdminRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerAdminControllerApi();
final assignAdminRequest = AssignAdminRequest(); // AssignAdminRequest | 

try {
    final result = api_instance.assignAdmin2(assignAdminRequest);
    print(result);
} catch (e) {
    print('Exception when calling PartnerAdminControllerApi->assignAdmin2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **assignAdminRequest** | [**AssignAdminRequest**](AssignAdminRequest.md)|  | 

### Return type

[**ApiResponsePartnerAdmin**](ApiResponsePartnerAdmin.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **canManageDrivers2**
> ApiResponseBoolean canManageDrivers2(userId, companyId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerAdminControllerApi();
final userId = 789; // int | 
final companyId = 789; // int | 

try {
    final result = api_instance.canManageDrivers2(userId, companyId);
    print(result);
} catch (e) {
    print('Exception when calling PartnerAdminControllerApi->canManageDrivers2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 
 **companyId** | **int**|  | 

### Return type

[**ApiResponseBoolean**](ApiResponseBoolean.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAdminsByCompany2**
> ApiResponseListPartnerAdmin getAdminsByCompany2(companyId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerAdminControllerApi();
final companyId = 789; // int | 

try {
    final result = api_instance.getAdminsByCompany2(companyId);
    print(result);
} catch (e) {
    print('Exception when calling PartnerAdminControllerApi->getAdminsByCompany2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **companyId** | **int**|  | 

### Return type

[**ApiResponseListPartnerAdmin**](ApiResponseListPartnerAdmin.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getCompaniesByUser2**
> ApiResponseListPartnerAdmin getCompaniesByUser2(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerAdminControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.getCompaniesByUser2(userId);
    print(result);
} catch (e) {
    print('Exception when calling PartnerAdminControllerApi->getCompaniesByUser2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

[**ApiResponseListPartnerAdmin**](ApiResponseListPartnerAdmin.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getManagedCompanies2**
> ApiResponseListLong getManagedCompanies2(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerAdminControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.getManagedCompanies2(userId);
    print(result);
} catch (e) {
    print('Exception when calling PartnerAdminControllerApi->getManagedCompanies2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **userId** | **int**|  | 

### Return type

[**ApiResponseListLong**](ApiResponseListLong.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPrimaryAdmin2**
> ApiResponsePartnerAdmin getPrimaryAdmin2(companyId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerAdminControllerApi();
final companyId = 789; // int | 

try {
    final result = api_instance.getPrimaryAdmin2(companyId);
    print(result);
} catch (e) {
    print('Exception when calling PartnerAdminControllerApi->getPrimaryAdmin2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **companyId** | **int**|  | 

### Return type

[**ApiResponsePartnerAdmin**](ApiResponsePartnerAdmin.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **removeAdmin2**
> ApiResponseVoid removeAdmin2(adminId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerAdminControllerApi();
final adminId = 789; // int | 

try {
    final result = api_instance.removeAdmin2(adminId);
    print(result);
} catch (e) {
    print('Exception when calling PartnerAdminControllerApi->removeAdmin2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adminId** | **int**|  | 

### Return type

[**ApiResponseVoid**](ApiResponseVoid.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePermissions2**
> ApiResponsePartnerAdmin updatePermissions2(adminId, updatePermissionsRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = PartnerAdminControllerApi();
final adminId = 789; // int | 
final updatePermissionsRequest = UpdatePermissionsRequest(); // UpdatePermissionsRequest | 

try {
    final result = api_instance.updatePermissions2(adminId, updatePermissionsRequest);
    print(result);
} catch (e) {
    print('Exception when calling PartnerAdminControllerApi->updatePermissions2: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adminId** | **int**|  | 
 **updatePermissionsRequest** | [**UpdatePermissionsRequest**](UpdatePermissionsRequest.md)|  | 

### Return type

[**ApiResponsePartnerAdmin**](ApiResponsePartnerAdmin.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

