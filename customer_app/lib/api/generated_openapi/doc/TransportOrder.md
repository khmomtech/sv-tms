# openapi.model.TransportOrder

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | [optional] 
**version** | **int** |  | [optional] 
**orderReference** | **String** |  | [optional] 
**customer** | [**Customer**](Customer.md) |  | [optional] 
**billTo** | **String** |  | [optional] 
**orderDate** | [**DateTime**](DateTime.md) |  | [optional] 
**deliveryDate** | [**DateTime**](DateTime.md) |  | [optional] 
**shipmentType** | **String** |  | [optional] 
**courierAssigned** | **String** |  | [optional] 
**tripNo** | **String** |  | [optional] 
**truckNumber** | **String** |  | [optional] 
**truckTripCount** | **int** |  | [optional] 
**status** | **String** |  | [optional] 
**createdBy** | [**User**](User.md) |  | [optional] 
**seller** | [**Employee**](Employee.md) |  | [optional] 
**items** | [**List<OrderItem>**](OrderItem.md) |  | [optional] [default to const []]
**pickupAddress** | [**OrderAddress**](OrderAddress.md) |  | [optional] 
**dropAddress** | [**OrderAddress**](OrderAddress.md) |  | [optional] 
**pickupAddresses** | [**List<OrderAddress>**](OrderAddress.md) |  | [optional] [default to const []]
**dropAddresses** | [**List<OrderAddress>**](OrderAddress.md) |  | [optional] [default to const []]
**dispatches** | [**List<Dispatch>**](Dispatch.md) |  | [optional] [default to const []]
**invoice** | [**Invoice**](Invoice.md) |  | [optional] 
**stops** | [**List<OrderStop>**](OrderStop.md) |  | [optional] [default to const []]
**remark** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


