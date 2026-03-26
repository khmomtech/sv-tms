# openapi.model.TransportOrderDto

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
**customerName** | **String** |  | [optional] 
**billTo** | **String** |  | [optional] 
**orderDate** | [**DateTime**](DateTime.md) |  | [optional] 
**deliveryDate** | [**DateTime**](DateTime.md) |  | [optional] 
**createDate** | [**DateTime**](DateTime.md) |  | [optional] 
**shipmentType** | **String** |  | [optional] 
**courierAssigned** | **String** |  | [optional] 
**tripNo** | **String** |  | [optional] 
**truckNumber** | **String** |  | [optional] 
**truckTripCount** | **int** |  | [optional] 
**status** | **String** |  | [optional] 
**remark** | **String** |  | [optional] 
**createdById** | **int** |  | [optional] 
**createdByUsername** | **String** |  | [optional] 
**seller** | [**EmployeeDto**](EmployeeDto.md) |  | [optional] 
**items** | [**List<OrderItemDto>**](OrderItemDto.md) |  | [optional] [default to const []]
**pickupAddress** | [**OrderAddressDto**](OrderAddressDto.md) |  | [optional] 
**dropAddress** | [**OrderAddressDto**](OrderAddressDto.md) |  | [optional] 
**pickupAddresses** | [**List<OrderAddressDto>**](OrderAddressDto.md) |  | [optional] [default to const []]
**dropAddresses** | [**List<OrderAddressDto>**](OrderAddressDto.md) |  | [optional] [default to const []]
**dispatches** | [**List<DispatchDto>**](DispatchDto.md) |  | [optional] [default to const []]
**invoice** | [**InvoiceDto**](InvoiceDto.md) |  | [optional] 
**stops** | [**List<OrderStopDto>**](OrderStopDto.md) |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


