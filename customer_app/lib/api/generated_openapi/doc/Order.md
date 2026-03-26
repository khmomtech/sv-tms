# openapi.model.Order

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | [optional] 
**orderNumber** | **String** |  | [optional] 
**customerName** | **String** |  | [optional] 
**deliveryAddress** | **String** |  | [optional] 
**pickupAddress** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | [optional] 
**status** | **String** |  | [optional] 
**assignedVehicle** | **String** |  | [optional] 
**assignedDriver** | **String** |  | [optional] 
**proofOfDelivery** | **String** |  | [optional] 
**shipments** | [**List<Shipment>**](Shipment.md) |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


