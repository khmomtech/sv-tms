# openapi.api.ShipmentControllerApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost:8085*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createShipment**](ShipmentControllerApi.md#createshipment) | **POST** /create | 
[**getAllShipments**](ShipmentControllerApi.md#getallshipments) | **GET** / | 


# **createShipment**
> Shipment createShipment(shipment)



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ShipmentControllerApi();
final shipment = Shipment(); // Shipment | 

try {
    final result = api_instance.createShipment(shipment);
    print(result);
} catch (e) {
    print('Exception when calling ShipmentControllerApi->createShipment: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **shipment** | [**Shipment**](Shipment.md)|  | 

### Return type

[**Shipment**](Shipment.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllShipments**
> List<Shipment> getAllShipments()



### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ShipmentControllerApi();

try {
    final result = api_instance.getAllShipments();
    print(result);
} catch (e) {
    print('Exception when calling ShipmentControllerApi->getAllShipments: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<Shipment>**](Shipment.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: */*

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

