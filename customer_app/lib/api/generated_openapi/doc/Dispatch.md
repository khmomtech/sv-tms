# openapi.model.Dispatch

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | [optional] 
**routeCode** | **String** |  | [optional] 
**trackingNo** | **String** |  | [optional] 
**truckTrip** | **String** |  | [optional] 
**fromLocation** | **String** |  | [optional] 
**toLocation** | **String** |  | [optional] 
**deliveryDate** | [**DateTime**](DateTime.md) |  | [optional] 
**customer** | [**Customer**](Customer.md) |  | [optional] 
**startTime** | [**DateTime**](DateTime.md) |  | [optional] 
**estimatedArrival** | [**DateTime**](DateTime.md) |  | [optional] 
**status** | **String** |  | [optional] 
**transportOrder** | [**TransportOrder**](TransportOrder.md) |  | [optional] 
**driver** | [**Driver**](Driver.md) |  | [optional] 
**vehicle** | [**Vehicle**](Vehicle.md) |  | [optional] 
**createdBy** | [**User**](User.md) |  | [optional] 
**tripType** | **String** |  | [optional] 
**createdDate** | [**DateTime**](DateTime.md) |  | [optional] 
**updatedDate** | [**DateTime**](DateTime.md) |  | [optional] 
**stops** | [**List<DispatchStop>**](DispatchStop.md) |  | [optional] [default to const []]
**items** | [**List<DispatchItem>**](DispatchItem.md) |  | [optional] [default to const []]
**cancelReason** | **String** |  | [optional] 
**loadProof** | [**LoadProof**](LoadProof.md) |  | [optional] 
**unloadProof** | [**UnloadProof**](UnloadProof.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


