# openapi.api.VendorAdminControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assignAdmin**](VendorAdminControllerApi.md#assignadmin) | **POST** /api/vendor-admins | 
[**canManageDrivers**](VendorAdminControllerApi.md#canmanagedrivers) | **GET** /api/vendor-admins/user/{userId}/companies/{companyId}/can-manage-drivers | 
[**getAdminsByCompany**](VendorAdminControllerApi.md#getadminsbycompany) | **GET** /api/vendor-admins/company/{companyId} | 
[**getCompaniesByUser**](VendorAdminControllerApi.md#getcompaniesbyuser) | **GET** /api/vendor-admins/user/{userId} | 
[**getManagedCompanies**](VendorAdminControllerApi.md#getmanagedcompanies) | **GET** /api/vendor-admins/user/{userId}/managed-companies | 
[**getPrimaryAdmin**](VendorAdminControllerApi.md#getprimaryadmin) | **GET** /api/vendor-admins/company/{companyId}/primary | 
[**removeAdmin**](VendorAdminControllerApi.md#removeadmin) | **DELETE** /api/vendor-admins/{adminId} | 
[**updatePermissions**](VendorAdminControllerApi.md#updatepermissions) | **PATCH** /api/vendor-admins/{adminId}/permissions | 


# **assignAdmin**
> ApiResponsePartnerAdmin assignAdmin(assignAdminRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorAdminControllerApi();
final assignAdminRequest = AssignAdminRequest(); // AssignAdminRequest | 

try {
    final result = api_instance.assignAdmin(assignAdminRequest);
    print(result);
} catch (e) {
    print('Exception when calling VendorAdminControllerApi->assignAdmin: $e\n');
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

# **canManageDrivers**
> ApiResponseBoolean canManageDrivers(userId, companyId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorAdminControllerApi();
final userId = 789; // int | 
final companyId = 789; // int | 

try {
    final result = api_instance.canManageDrivers(userId, companyId);
    print(result);
} catch (e) {
    print('Exception when calling VendorAdminControllerApi->canManageDrivers: $e\n');
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

# **getAdminsByCompany**
> ApiResponseListPartnerAdmin getAdminsByCompany(companyId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorAdminControllerApi();
final companyId = 789; // int | 

try {
    final result = api_instance.getAdminsByCompany(companyId);
    print(result);
} catch (e) {
    print('Exception when calling VendorAdminControllerApi->getAdminsByCompany: $e\n');
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

# **getCompaniesByUser**
> ApiResponseListPartnerAdmin getCompaniesByUser(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorAdminControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.getCompaniesByUser(userId);
    print(result);
} catch (e) {
    print('Exception when calling VendorAdminControllerApi->getCompaniesByUser: $e\n');
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

# **getManagedCompanies**
> ApiResponseListLong getManagedCompanies(userId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorAdminControllerApi();
final userId = 789; // int | 

try {
    final result = api_instance.getManagedCompanies(userId);
    print(result);
} catch (e) {
    print('Exception when calling VendorAdminControllerApi->getManagedCompanies: $e\n');
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

# **getPrimaryAdmin**
> ApiResponsePartnerAdmin getPrimaryAdmin(companyId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorAdminControllerApi();
final companyId = 789; // int | 

try {
    final result = api_instance.getPrimaryAdmin(companyId);
    print(result);
} catch (e) {
    print('Exception when calling VendorAdminControllerApi->getPrimaryAdmin: $e\n');
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

# **removeAdmin**
> ApiResponseVoid removeAdmin(adminId)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorAdminControllerApi();
final adminId = 789; // int | 

try {
    final result = api_instance.removeAdmin(adminId);
    print(result);
} catch (e) {
    print('Exception when calling VendorAdminControllerApi->removeAdmin: $e\n');
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

# **updatePermissions**
> ApiResponsePartnerAdmin updatePermissions(adminId, updatePermissionsRequest)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = VendorAdminControllerApi();
final adminId = 789; // int | 
final updatePermissionsRequest = UpdatePermissionsRequest(); // UpdatePermissionsRequest | 

try {
    final result = api_instance.updatePermissions(adminId, updatePermissionsRequest);
    print(result);
} catch (e) {
    print('Exception when calling VendorAdminControllerApi->updatePermissions: $e\n');
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

