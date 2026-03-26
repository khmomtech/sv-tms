# openapi.model.DriverIssueDto

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | [optional] 
**driverId** | **int** |  | 
**driverName** | **String** |  | [optional] 
**vehicleId** | **int** |  | 
**vehiclePlate** | **String** |  | [optional] 
**title** | **String** |  | 
**description** | **String** |  | 
**severity** | **String** |  | 
**status** | **String** |  | [optional] 
**location** | **String** |  | [optional] 
**currentKm** | **double** |  | [optional] 
**photoUrls** | **List<String>** |  | [optional] [default to const []]
**photos** | [**List<DriverIssuePhotoDto>**](DriverIssuePhotoDto.md) |  | [optional] [default to const []]
**workOrderId** | **int** |  | [optional] 
**assignedToId** | **int** |  | [optional] 
**assignedToName** | **String** |  | [optional] 
**reportedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**resolvedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**resolutionNotes** | **String** |  | [optional] 
**createdAt** | [**DateTime**](DateTime.md) |  | [optional] 
**images** | **List<String>** |  | [optional] [default to const []]
**dispatchId** | **int** |  | [optional] 
**orderReference** | **String** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


