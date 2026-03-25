> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Maintenance Module Entity-DTO Field Name Mismatches - Comprehensive Fix Plan

## Problem Summary
87 compilation errors due to field name mismatches between entity models and DTOs/services. The entities were created in a previous session with different naming conventions than the DTOs I generated.

## Critical Mismatches

### WorkOrder Entity
**Actual fields** (from model):
- `issueSummary` (TEXT) - NOT `title`, NOT `description`
- `laborCost`, `partsCost`, `totalCost` (BigDecimal) - NOT `estimatedCost`, NOT `actualCost`
- `remarks` (TEXT) - NOT `notes`
- `approved` (Boolean) - no `approvedBy` user reference
- NO `pmSchedule` field
- NO `driverIssue` field  
- NO `maintenanceTask` field

**Used in DTO but missing**:
- `title`, `description`, `estimatedCost`, `actualCost`, `notes`
- `approvedBy` (User), `pmSchedule`, `driverIssue`, `maintenanceTask`

### PMSchedule Entity
**Actual fields**:
- `scheduleName` (String 200) - NOT `pmName`
- `triggerInterval` (Integer) - NOT `intervalKm`, `intervalDays`, `intervalEngineHours`
- `triggerType` (Enum: PMTriggerType) - determines what interval means
- `lastPerformedAt` (LocalDateTime) - NOT `lastPerformedDate` (LocalDate)
- `taskType` (MaintenanceTaskType entity) - NOT `maintenanceTaskType` String/ID

**Used in DTO but missing**:
- `pmName`, `intervalKm`, `intervalDays`, `intervalEngineHours`
- `lastPerformedDate`, `maintenanceTaskType`

### DriverIssue Entity
**Actual fields**:
- `locationAddress` (String 500) - NOT `location`
- NO `currentKm` field - vehicle mileage is in Vehicle entity
- NO `resolutionNotes` field - use `remarks` or add field

**Missing fields**:
- `location`, `currentKm`, `resolutionNotes`

### WorkOrderTask Entity
**Actual fields**:
- `category` (String 100) - NOT `taskName`
- `timeSpentMinutes` (Integer) - NOT `estimatedHours`, NOT `actualHours`
- `diagnosisResult`, `actionsTaken` (TEXT) - NOT `notes`

**Missing fields**:
- `taskName`, `estimatedHours`, `actualHours`, `notes`

### WorkOrderPhoto Entity
**Actual fields**:
- NO `description` field - only `photoUrl` and `photoType`

### WorkOrderPart Entity
**Actual fields**:
- `quantity` (Integer), `unitCost` (BigDecimal), `totalCost` (BigDecimal)
- NO quantity as Double

### PartsMaster Entity
**Actual fields**:
- `cost` (BigDecimal) - NOT `unitPrice`
- NO `unit`, NO `supplier` fields

## Fix Strategy

### Option 1: Modify Entities (RECOMMENDED)
Add missing fields to entities to match the DTO contract. This preserves the API design.

**WorkOrder additions:**
- Add title, description, estimatedCost, actualCost, notes
- Add @ManyToOne pmSchedule, driverIssue
- Add @ManyToOne approvedBy (User)
- Add @ManyToOne maintenanceTask

**PMSchedule additions:**
- Add pmName (copy scheduleName logic)
- Add computed fields: intervalKm, intervalDays, intervalEngineHours based on triggerType
- Add lastPerformedDate (copy lastPerformedAt)

**DriverIssue additions:**
- Add location (alias to locationAddress)
- Add currentKm (snapshot from vehicle)
- Add resolutionNotes

**WorkOrderTask additions:**
- Add taskName (alias to category)
- Add estimatedHours, actualHours (convert from timeSpentMinutes)
- Add notes (alias to diagnosisResult + actionsTaken)

**PartsMaster additions:**
- Add unitPrice (alias to cost)
- Add unit, supplier

### Option 2: Modify DTOs
Update all DTOs to match existing entity field names. This breaks API contract.

**NOT RECOMMENDED** - Would break existing frontend code and API consumers.

## Immediate Actions

1. Fixed: Vehicle.getPlate() → Vehicle.getLicensePlate()
2. Fixed: @NotBlank annotation missing message() method
3. ⚠️ PENDING: Add missing entity fields (Option 1)
4. ⚠️ PENDING: Update service layer to use correct field names
5. ⚠️ PENDING: Fix WorkOrder.generateWoNumber() - remove repository parameter
6. ⚠️ PENDING: Fix WorkOrder.addPart() method signature

## Files Requiring Updates

### Entities (add fields):
- WorkOrder.java
- PMSchedule.java
- DriverIssue.java
- WorkOrderTask.java
- WorkOrderPhoto.java
- PartsMaster.java

### Services (fix method calls):
- WorkOrderService.java - 14 errors
- PMScheduleService.java - 18 errors
- PMSchedulerService.java - 7 errors
- DriverIssueService.java - 5 errors
- PartsMasterService.java - 3 errors

### DTOs (already correct, no changes needed):
- WorkOrderDto.java
- PMScheduleDto.java
- DriverIssueDto.java
- WorkOrderTaskDto.java
- WorkOrderPartDto.java
- PartsMasterDto.java

### Controllers (fix method calls):
- PMScheduleController.java - 2 errors
- TechnicianController.java - 1 error

## Estimated Effort
- Entity updates: ~30 minutes (add ~20 new fields across 6 entities)
- Service fixes: ~45 minutes (fix 47 method call errors)
- Controller fixes: ~5 minutes (3 errors)
- Database migration: ~15 minutes (Flyway script for new columns)
- Testing: ~30 minutes (verify all changes compile and tests pass)

**Total: ~2 hours**

## Next Steps
1. Update entities with missing fields
2. Create Flyway migration for new columns
3. Recompile and verify zero errors
4. Run test suite
5. Generate updated OpenAPI documentation
