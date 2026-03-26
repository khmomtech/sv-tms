# openapi.api.SubcontractorAdminControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assignAdmin1**](SubcontractorAdminControllerApi.md#assignadmin1) | **POST** /api/subcontractor-admins | 
[**canManageDrivers1**](SubcontractorAdminControllerApi.md#canmanagedrivers1) | **GET** /api/subcontractor-admins/user/{userId}/companies/{companyId}/can-manage-drivers | 
[**getAdminsByCompany1**](SubcontractorAdminControllerApi.md#getadminsbycompany1) | **GET** /api/subcontractor-admins/company/{companyId} | 
[**getCompaniesByUser1**](SubcontractorAdminControllerApi.md#getcompaniesbyuser1) | **GET** /api/subcontractor-admins/user/{userId} | 
[**getManagedCompanies1**](SubcontractorAdminControllerApi.md#getmanagedcompanies1) | **GET** /api/subcontractor-admins/user/{userId}/managed-companies | 
[**getPrimaryAdmin1**](SubcontractorAdminControllerApi.md#getprimaryadmin1) | **GET** /api/subcontractor-admins/company/{companyId}/primary | 
[**removeAdmin1**](SubcontractorAdminControllerApi.md#removeadmin1) | **DELETE** /api/subcontractor-admins/{adminId} | 
[**updatePermissions1**](SubcontractorAdminControllerApi.md#updatepermissions1) | **PATCH** /api/subcontractor-admins/{adminId}/permissions | 


# **assignAdmin1**
> ApiResponsePartnerAdmin assignAdmin1(assignAdminRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorAdminControllerApi();
final assignAdminRequest = AssignAdminRequest(); // AssignAdminRequest | 

try {
    final result = api_instance.assignAdmin1(assignAdminRequest);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorAdminControllerApi->assignAdmin1: $e\n');
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

# **canManageDrivers1**
> ApiResponseBoolean canManageDrivers1(userId, companyId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorAdminControllerApi();
final userId = 789; // int | 
final companyId = 789; // int | 

try {
    final result = api_instance.canManageDrivers1(userId, companyId);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorAdminControllerApi->canManageDrivers1: $e\n');
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

# **getAdminsByCompany1**
> ApiResponseListPartnerAdmin getAdminsByCompany1(companyId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorAdminControllerApi();
final companyId = 789; // int | 

try {
    final result = api_instance.getAdminsByCompany1(companyId);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorAdminControllerApi->getAdminsByCompany1: $e\n');
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

# **getCompaniesByUser1**
> ApiResponseListPartnerAdmin getCompaniesByUser1(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorAdminControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.getCompaniesByUser1(userId);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorAdminControllerApi->getCompaniesByUser1: $e\n');
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

# **getManagedCompanies1**
> ApiResponseListLong getManagedCompanies1(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorAdminControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.getManagedCompanies1(userId);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorAdminControllerApi->getManagedCompanies1: $e\n');
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

# **getPrimaryAdmin1**
> ApiResponsePartnerAdmin getPrimaryAdmin1(companyId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorAdminControllerApi();
final companyId = 789; // int | 

try {
    final result = api_instance.getPrimaryAdmin1(companyId);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorAdminControllerApi->getPrimaryAdmin1: $e\n');
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

# **removeAdmin1**
> ApiResponseVoid removeAdmin1(adminId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorAdminControllerApi();
final adminId = 789; // int | 

try {
    final result = api_instance.removeAdmin1(adminId);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorAdminControllerApi->removeAdmin1: $e\n');
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

# **updatePermissions1**
> ApiResponsePartnerAdmin updatePermissions1(adminId, updatePermissionsRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = SubcontractorAdminControllerApi();
final adminId = 789; // int | 
final updatePermissionsRequest = UpdatePermissionsRequest(); // UpdatePermissionsRequest | 

try {
    final result = api_instance.updatePermissions1(adminId, updatePermissionsRequest);
    print(result);
} catch (e) {
    print('Exception when calling SubcontractorAdminControllerApi->updatePermissions1: $e\n');
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

