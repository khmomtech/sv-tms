# openapi.model.WorkOrderDto

## Load the model package
```dart
import 'package:openapi/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** |  | [optional] 
**woNumber** | **String** |  | [optional] 
**vehicleId** | **int** |  | 
**vehiclePlate** | **String** |  | [optional] 
**type** | **String** |  | 
**priority** | **String** |  | 
**status** | **String** |  | [optional] 
**title** | **String** |  | 
**description** | **String** |  | [optional] 
**assignedTechnicianId** | **int** |  | [optional] 
**assignedTechnicianName** | **String** |  | [optional] 
**scheduledDate** | [**DateTime**](DateTime.md) |  | [optional] 
**completedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**estimatedCost** | **double** |  | [optional] 
**actualCost** | **double** |  | [optional] 
**laborCost** | **double** |  | [optional] 
**partsCost** | **double** |  | [optional] 
**notes** | **String** |  | [optional] 
**requiresApproval** | **bool** |  | [optional] 
**approved** | **bool** |  | [optional] 
**approvedById** | **int** |  | [optional] 
**approvedByName** | **String** |  | [optional] 
**approvedAt** | [**DateTime**](DateTime.md) |  | [optional] 
**maintenanceTaskId** | **int** |  | [optional] 
**maintenanceTaskName** | **String** |  | [optional] 
**driverIssueId** | **int** |  | [optional] 
**pmScheduleId** | **int** |  | [optional] 
**tasks** | [**List<WorkOrderTaskDto>**](WorkOrderTaskDto.md) |  | [optional] [default to const []]
**photos** | [**List<WorkOrderPhotoDto>**](WorkOrderPhotoDto.md) |  | [optional] [default to const []]
**parts** | [**List<WorkOrderPartDto>**](WorkOrderPartDto.md) |  | [optional] [default to const []]
**totalTasks** | **int** |  | [optional] 
**completedTasks** | **int** |  | [optional] 
**totalPartsCost** | **double** |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


