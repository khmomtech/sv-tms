# openapi.model.DispatchDto

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | [optional] 
**routeCode** | **String** |  | [optional] 
**startTime** | [**DateTime**](DateTime.md) |  | [optional] 
**estimatedArrival** | [**DateTime**](DateTime.md) |  | [optional] 
**status** | **String** |  | [optional] 
**tripType** | **String** |  | [optional] 
**transportOrderId** | **int** |  | [optional] 
**orderReference** | **String** |  | [optional] 
**transportOrder** | [**TransportOrderDto**](TransportOrderDto.md) |  | [optional] 
**customerId** | **int** |  | [optional] 
**customerName** | **String** |  | [optional] 
**customerPhone** | **String** |  | [optional] 
**pickupName** | **String** |  | [optional] 
**pickupLocation** | **String** |  | [optional] 
**pickupLat** | **double** |  | [optional] 
**pickupLng** | **double** |  | [optional] 
**dropoffName** | **String** |  | [optional] 
**dropoffLocation** | **String** |  | [optional] 
**dropoffLat** | **double** |  | [optional] 
**dropoffLng** | **double** |  | [optional] 
**driverId** | **int** |  | [optional] 
**driverName** | **String** |  | [optional] 
**driverPhone** | **String** |  | [optional] 
**vehicleId** | **int** |  | [optional] 
**licensePlate** | **String** |  | [optional] 
**createdBy** | **int** |  | [optional] 
**createdByUsername** | **String** |  | [optional] 
**createdDate** | [**DateTime**](DateTime.md) |  | [optional] 
**updatedDate** | [**DateTime**](DateTime.md) |  | [optional] 
**stops** | [**List<DispatchStopDto>**](DispatchStopDto.md) |  | [optional] [default to const []]
**items** | [**List<DispatchItemDto>**](DispatchItemDto.md) |  | [optional] [default to const []]
**loadProof** | [**LoadProofDto**](LoadProofDto.md) |  | [optional] 
**unloadProof** | [**UnloadProofDto**](UnloadProofDto.md) |  | [optional] 
**loadingProofImages** | **List<String>** |  | [optional] [default to const []]
**loadingSignature** | **String** |  | [optional] 
**unloadingProofImages** | **List<String>** |  | [optional] [default to const []]
**unloadingSignature** | **String** |  | [optional] 
**expectedDelivery** | [**DateTime**](DateTime.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


