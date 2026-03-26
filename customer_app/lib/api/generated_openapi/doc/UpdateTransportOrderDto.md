# openapi.model.UpdateTransportOrderDto

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | [optional] 
**orderReference** | **String** |  | [optional] 
**customerId** | **int** |  | [optional] 
**billTo** | **String** |  | [optional] 
**orderDate** | [**DateTime**](DateTime.md) |  | [optional] 
**deliveryDate** | [**DateTime**](DateTime.md) |  | [optional] 
**shipmentType** | **String** |  | [optional] 
**courierAssigned** | **String** |  | [optional] 
**status** | **String** |  | [optional] 
**remark** | **String** |  | [optional] 
**createdById** | **int** |  | [optional] 
**sellerId** | **int** |  | [optional] 
**pickupAddress** | [**OrderAddressDto**](OrderAddressDto.md) |  | [optional] 
**dropAddress** | [**OrderAddressDto**](OrderAddressDto.md) |  | [optional] 
**pickupLocations** | [**List<OrderAddressDto>**](OrderAddressDto.md) |  | [optional] [default to const []]
**dropLocations** | [**List<OrderAddressDto>**](OrderAddressDto.md) |  | [optional] [default to const []]
**items** | [**List<OrderItemDto>**](OrderItemDto.md) |  | [optional] [default to const []]
**stops** | [**List<OrderStopDto>**](OrderStopDto.md) |  | [optional] [default to const []]
**customer** | [**CustomerDto**](CustomerDto.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


