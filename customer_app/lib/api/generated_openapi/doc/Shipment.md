# openapi.model.Shipment

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | [optional] 
**order** | [**Order**](Order.md) |  | [optional] 
**trackingNumber** | **String** |  | [optional] 
**estimatedDeliveryDate** | [**DateTime**](DateTime.md) |  | [optional] 
**actualDeliveryDate** | [**DateTime**](DateTime.md) |  | [optional] 
**shipmentStatus** | **String** |  | [optional] 
**assignedVehicle** | **String** |  | [optional] 
**assignedDriver** | **String** |  | [optional] 
**proofOfDelivery** | **String** |  | [optional] 
**loadingAddresses** | [**List<LoadingAddress>**](LoadingAddress.md) |  | [optional] [default to const []]
**dropAddresses** | [**List<DropAddress>**](DropAddress.md) |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


