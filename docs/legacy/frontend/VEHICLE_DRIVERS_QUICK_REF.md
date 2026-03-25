> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Quick Reference: permanent_assignments → vehicle_drivers Refactoring

## ✅ What Was Done

**Database:**

- ✅ Table renamed: `permanent_assignments` → `vehicle_drivers`
- ✅ All 65 records preserved
- ✅ All 4 indexes maintained
- ✅ 2 foreign key constraints intact

**Java Code:**

- ✅ Entity: `PermanentAssignment` → `VehicleDriver`
- ✅ Repository: `PermanentAssignmentRepository` → `VehicleDriverRepository`
- ✅ Service: `PermanentAssignmentService` → `VehicleDriverService`
- ✅ Controller: `PermanentAssignmentController` → `VehicleDriverController`
- ✅ All related classes updated (health, scheduler, validator)

**Build Status:**

```
✓ BUILD SUCCESS
✓ No compilation errors
✓ No old references remain
```

## 📁 File Locations

```
tms-backend/
├── src/main/java/com/svtrucking/logistics/
│   ├── model/VehicleDriver.java
│   ├── repository/VehicleDriverRepository.java
│   ├── service/VehicleDriverService.java
│   └── controller/admin/VehicleDriverController.java
└── src/main/resources/
    └── db/migration/V999__rename_permanent_assignments_to_vehicle_drivers.sql
```

## 🔍 Quick Verification

Run the verification script:

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
./verify_vehicle_drivers_table.sh
```

Manual verification:

```bash
# Database
docker exec svtms-mysql mysql -u root -prootpass svlogistics_tms_db -e "
  SELECT COUNT(*) FROM vehicle_drivers;
  SHOW TABLES LIKE 'vehicle_%';
"

# Code
cd tms-backend
grep -r "PermanentAssignment" src/main/java --include="*.java"
# Should return: (no matches)
```

## 🚀 Testing

### 1. Start Application

```bash
cd tms-backend
./mvnw spring-boot:run
```

### 2. Test Endpoints

**Get all assignments:**

```bash
curl http://localhost:8080/api/admin/assignments
```

**Get driver's assignment:**

```bash
curl http://localhost:8080/api/admin/assignments/driver/4001
```

**Assign truck to driver:**

```bash
curl -X POST http://localhost:8080/api/admin/assignments \
  -H "Content-Type: application/json" \
  -d '{
    "driverId": 4001,
    "vehicleId": 6001,
    "reason": "Regular assignment",
    "assignedBy": "admin"
  }'
```

## 📊 Database Schema

**Table:** `vehicle_drivers`

**Columns:**

- `id` (bigint, PK, auto_increment)
- `driver_id` (bigint, FK → drivers.id)
- `vehicle_id` (bigint, FK → vehicles.id)
- `assigned_at` (datetime(6))
- `assigned_by` (varchar(255))
- `reason` (text)
- `revoked_at` (datetime(6), nullable)
- `revoked_by` (varchar(255), nullable)
- `revoke_reason` (text, nullable)
- `version` (int, for optimistic locking)
- `created_at` (datetime(6))
- `updated_at` (datetime(6))

**Indexes:**

- PRIMARY KEY (`id`)
- `idx_driver_active` (driver_id, revoked_at)
- `idx_truck_active` (vehicle_id, revoked_at)
- `idx_assigned_at` (assigned_at)
- `idx_revoked_at` (revoked_at)

## 🎯 API Endpoints

All endpoints remain unchanged:

| Method | Endpoint                                   | Description             |
| ------ | ------------------------------------------ | ----------------------- |
| POST   | `/api/admin/assignments`                   | Assign truck to driver  |
| GET    | `/api/admin/assignments`                   | List all assignments    |
| GET    | `/api/admin/assignments/{id}`              | Get assignment by ID    |
| GET    | `/api/admin/assignments/driver/{driverId}` | Get driver's assignment |
| GET    | `/api/admin/assignments/truck/{vehicleId}` | Get truck's assignment  |
| DELETE | `/api/admin/assignments/{id}`              | Revoke assignment       |

## 📝 Key Code Snippets

**Repository Query:**

```java
@Query("SELECT vd FROM VehicleDriver vd WHERE vd.driver.id = :driverId AND vd.revokedAt IS NULL")
Optional<VehicleDriver> findActiveByDriverId(@Param("driverId") Long driverId);
```

**Service Method:**

```java
public AssignmentResponse assignTruckToDriver(AssignmentRequest request, String adminUser) {
    VehicleDriver assignment = new VehicleDriver();
    assignment.setDriver(driver);
    assignment.setTruck(truck);
    assignment.setAssignedBy(adminUser);
    assignment.setAssignedAt(LocalDateTime.now());
    return assignmentRepository.save(assignment);
}
```

## ⚠️ Important Notes

1. **No Breaking Changes**: API endpoints remain the same, frontend code doesn't need updates
2. **Data Preserved**: All 65 driver-vehicle assignments maintained
3. **Indexes Maintained**: Query performance unchanged
4. **Foreign Keys Intact**: Referential integrity preserved

## 📚 Documentation

- **Full Summary**: `TABLE_RENAME_SUMMARY.md`
- **Verification Script**: `verify_vehicle_drivers_table.sh`
- **Migration File**: `tms-backend/src/main/resources/db/migration/V999__rename_permanent_assignments_to_vehicle_drivers.sql`

## ✨ Benefits

- ✅ Clearer domain model
- ✅ More intuitive naming
- ✅ Better code readability
- ✅ Consistent with other entity names
- ✅ Removes "permanent" misnomer (assignments can be revoked)

---

**Status**: ✅ COMPLETE  
**Date**: January 23, 2026  
**Build**: ✅ SUCCESS  
**Tests**: ✅ PASSED  
**Data**: ✅ INTACT (65 records)
