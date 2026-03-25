> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# SV-TMS Data Import Template Guide

## Overview

This guide provides comprehensive templates and instructions for importing Drivers, Vehicles, and Driver-to-Vehicle Assignments for the Transport Management System (TMS) pre-deployment data migration.

## System Architecture

The TMS uses three core entities:
- **Driver** - Individual drivers with licenses, performance metrics
- **Vehicle** - Fleet vehicles with specs and maintenance history
- **AssignmentVehicleToDriver** - Linking drivers to vehicles (permanent or temporary)

## Database Relationships

```
Driver (1) ----< (Many) AssignmentVehicleToDriver (Many) ----> (1) Vehicle
```

## Import Order

1. **Drivers** (independent)
2. **Vehicles** (independent)
3. **Assignments** (depends on both Driver and Vehicle)

---

# 1. DRIVER IMPORT TEMPLATE

## Data Model

```java
@Entity
@Table(name = "drivers")
public class Driver {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;           // Auto-generated
  
  @Column(name = "first_name")
  private String firstName;
  
  @Column(name = "last_name")
  private String lastName;
  
  @Column(name = "name")
  private String name;       // Full name (can be computed)
  
  @Column(nullable = false)
  private String phone;      // Required, unique per driver
  
  @Column(name = "license_class", length = 10)
  private String licenseClass;  // A1, A, B1, B, C, C1, D, E (Cambodia)
  
  @Column(name = "id_card_expiry")
  private LocalDate idCardExpiry;
  
  @Column(name = "performance_score")
  private Integer performanceScore;  // Default: 92
  
  @Column(name = "safety_score")
  private String safetyScore;  // Default: "Excellent"
  
  @Column(name = "on_time_percent")
  private Integer onTimePercent;  // Default: 98
  
  @Enumerated(EnumType.STRING)
  @Column(name = "status")
  private DriverStatus status;  // ACTIVE, INACTIVE, ON_LEAVE, TERMINATED
  
  @Column(name = "zone")
  private String zone;  // Geographic zone
  
  @Column(name = "is_active")
  private Boolean isActive;
  
  @Column(name = "created_at")
  private LocalDateTime createdAt;  // Auto-set
  
  @Column(name = "updated_at")
  private LocalDateTime updatedAt;  // Auto-set
}
```

## CSV Template: `drivers_import.csv`

```csv
first_name,last_name,phone,license_class,id_card_expiry,zone,status,performance_score,safety_score,on_time_percent
Sophea,Kong,+855971234567,C,2025-12-31,North,ACTIVE,92,Excellent,98
Visal,Mok,+855978901234,B,2026-06-30,South,ACTIVE,85,Good,90
Dara,Sarith,+855985551234,C1,2025-09-15,East,INACTIVE,78,Good,85
Bun,Rith,+855992223456,B1,2026-12-31,West,ACTIVE,95,Excellent,99
Thom,Rorn,+855981234567,A,2025-03-31,Central,ON_LEAVE,88,Good,92
```

### Column Definitions

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| first_name | String(80) | ✓ | Driver's first name |
| last_name | String(80) | ✓ | Driver's last name |
| phone | String(20) | ✓ | Phone number (must be unique) |
| license_class | String(10) | ✗ | Cambodia: A1, A, B1, B, C, C1, D, E |
| id_card_expiry | Date (YYYY-MM-DD) | ✗ | ID card expiration date |
| zone | String(50) | ✗ | Geographic zone assignment |
| status | Enum | ✗ | ACTIVE, INACTIVE, ON_LEAVE, TERMINATED (default: ACTIVE) |
| performance_score | Integer | ✗ | 0-100 (default: 92) |
| safety_score | String | ✗ | Excellent, Good, Fair, Poor (default: Excellent) |
| on_time_percent | Integer | ✗ | 0-100 (default: 98) |

---

# 2. VEHICLE IMPORT TEMPLATE

## Data Model

```java
@Entity
@Table(name = "vehicles")
public class Vehicle {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;           // Auto-generated
  
  @Column(name = "license_plate", nullable = false, unique = true)
  private String licensePlate;  // Required, must be unique
  
  @Enumerated(EnumType.STRING)
  @Column(name = "type")
  private VehicleType type;  // TRUCK, CAR, MOTORCYCLE, VAN
  
  @Enumerated(EnumType.STRING)
  @Column(name = "truck_size")
  private TruckSize truckSize;  // SMALL (1-3T), MEDIUM (3-5T), LARGE (5T+)
  
  @Column(name = "manufacturer", nullable = false)
  private String manufacturer;  // e.g., Hyundai, Isuzu, Hino
  
  @Column(name = "year_made")
  private Integer year;  // Manufacturing year
  
  @Column(name = "fuel_consumption", precision = 8, scale = 2)
  private BigDecimal fuelConsumption;  // Liters per km
  
  @Column(name = "max_weight", precision = 10, scale = 2)
  private BigDecimal maxWeight;  // kg or tons
  
  @Column(name = "max_volume", precision = 10, scale = 2)
  private BigDecimal maxVolume;  // cubic meters
  
  @Column(name = "last_inspection_date")
  private LocalDate lastInspectionDate;
  
  @Column(name = "next_service_due")
  private LocalDate nextServiceDue;
  
  @Column(name = "last_service_date")
  private LocalDate lastServiceDate;
  
  @Column(name = "current_km")
  private Integer currentKm;
  
  @Enumerated(EnumType.STRING)
  @Column(name = "status")
  private VehicleStatus status;  // ACTIVE, MAINTENANCE, RETIRED, INACTIVE
  
  @Column(name = "created_at")
  private LocalDateTime createdAt;  // Auto-set
  
  @Column(name = "updated_at")
  private LocalDateTime updatedAt;  // Auto-set
}
```

## CSV Template: `vehicles_import.csv`

```csv
license_plate,type,truck_size,manufacturer,year,fuel_consumption,max_weight,max_volume,last_inspection_date,next_service_due,last_service_date,current_km,status
HH-1234,TRUCK,LARGE,Hino,2020,0.08,15000,30,2024-12-01,2025-03-01,2024-12-01,125000,ACTIVE
KH-5678,TRUCK,MEDIUM,Isuzu,2021,0.07,8000,20,2024-11-15,2025-02-15,2024-11-15,98500,ACTIVE
PP-9012,VAN,SMALL,Toyota,2022,0.06,3500,8,2024-10-20,2025-01-20,2024-10-20,45200,ACTIVE
SR-3456,TRUCK,LARGE,Hyundai,2019,0.09,12000,28,2024-09-10,2025-03-10,2024-09-10,201500,MAINTENANCE
BB-7890,CAR,SMALL,Toyota,2023,0.05,1500,2.5,2024-12-15,2025-03-15,2024-12-15,12300,ACTIVE
```

### Column Definitions

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| license_plate | String(20) | ✓ | License plate (unique) |
| type | Enum | ✓ | TRUCK, CAR, MOTORCYCLE, VAN |
| truck_size | Enum | ✗ | SMALL, MEDIUM, LARGE (for trucks) |
| manufacturer | String(80) | ✓ | Brand/manufacturer |
| year | Integer(4) | ✗ | Manufacturing year (1900-2100) |
| fuel_consumption | Decimal | ✗ | Liters per km (0.00-999.99) |
| max_weight | Decimal | ✗ | Maximum weight capacity |
| max_volume | Decimal | ✗ | Maximum volume capacity |
| last_inspection_date | Date (YYYY-MM-DD) | ✗ | Last inspection date |
| next_service_due | Date (YYYY-MM-DD) | ✗ | Next service due date |
| last_service_date | Date (YYYY-MM-DD) | ✗ | Last service date |
| current_km | Integer | ✗ | Current odometer reading |
| status | Enum | ✗ | ACTIVE, MAINTENANCE, RETIRED, INACTIVE (default: ACTIVE) |

---

# 3. ASSIGNMENT (DRIVER-TO-VEHICLE) IMPORT TEMPLATE

## Data Model

```java
@Entity
@Table(name = "assignment_vehicle_to_driver")
public class AssignmentVehicleToDriver {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;           // Auto-generated
  
  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "driver_id", nullable = false)
  private Driver driver;     // Required reference to Driver
  
  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "vehicle_id", nullable = false)
  private Vehicle vehicle;   // Required reference to Vehicle
  
  @Column(name = "assigned_at", nullable = false)
  private LocalDateTime assignedAt;  // When assignment started
  
  @Column(name = "completed_at")
  private LocalDateTime completedAt;  // When assignment naturally finished
  
  @Column(name = "unassigned_at")
  private LocalDateTime unassignedAt;  // When forcefully unassigned
  
  @Enumerated(EnumType.STRING)
  @Column(nullable = false)
  private AssignmentStatus status;  // ASSIGNED, COMPLETED, UNASSIGNED
  
  @Enumerated(EnumType.STRING)
  @Column(name = "assignment_type")
  private AssignmentType assignmentType;  // PERMANENT, TEMPORARY
  
  @Column(name = "reason", length = 255)
  private String reason;  // Audit trail reason
}
```

## CSV Template: `assignments_import.csv`

```csv
driver_phone,vehicle_license_plate,assignment_type,status,assigned_at,completed_at,unassigned_at,reason
+855971234567,HH-1234,PERMANENT,ASSIGNED,2025-01-01 09:00:00,,,"Initial permanent assignment"
+855978901234,KH-5678,PERMANENT,ASSIGNED,2025-01-05 10:30:00,,,"Initial permanent assignment"
+855985551234,PP-9012,TEMPORARY,UNASSIGNED,2024-12-20 08:00:00,,2024-12-27 17:00:00,"Temporary route completion"
+855992223456,SR-3456,PERMANENT,ASSIGNED,2025-01-10 07:00:00,,,"Initial permanent assignment"
+855981234567,BB-7890,TEMPORARY,ASSIGNED,2025-01-15 06:00:00,,,"Temporary assignment for special delivery"
```

### Column Definitions

| Column | Type | Required | Notes |
|--------|------|----------|-------|
| driver_phone | String(20) | ✓ | Phone number to match driver (must exist in drivers) |
| vehicle_license_plate | String(20) | ✓ | License plate to match vehicle (must exist in vehicles) |
| assignment_type | Enum | ✓ | PERMANENT or TEMPORARY |
| status | Enum | ✓ | ASSIGNED, COMPLETED, UNASSIGNED |
| assigned_at | DateTime (YYYY-MM-DD HH:MM:SS) | ✓ | When assignment started |
| completed_at | DateTime (YYYY-MM-DD HH:MM:SS) | ✗ | When assignment naturally finished |
| unassigned_at | DateTime (YYYY-MM-DD HH:MM:SS) | ✗ | When forcefully unassigned |
| reason | String(255) | ✗ | Reason/notes for assignment |

### Assignment Status Logic

- **ASSIGNED**: Currently active assignment
- **COMPLETED**: Assignment finished naturally (completed_at set)
- **UNASSIGNED**: Assignment forcefully ended (unassigned_at set)

### Assignment Type

- **PERMANENT**: Long-term assignment (continuous service)
- **TEMPORARY**: Short-term assignment (specific route or task)

---

# 4. VALIDATION RULES

## Driver Validation

- ✓ **first_name**: 1-80 characters, required
- ✓ **last_name**: 1-80 characters, required
- ✓ **phone**: Must be unique, required, valid format
- ✓ **license_class**: Optional, valid values (A1, A, B1, B, C, C1, D, E)
- ✓ **id_card_expiry**: Valid date (YYYY-MM-DD format)
- ✓ **status**: Valid enum value
- ✓ **performance_score**: 0-100 range
- ✓ **on_time_percent**: 0-100 range

## Vehicle Validation

- ✓ **license_plate**: Must be unique, required, max 20 chars
- ✓ **type**: Required, valid enum value
- ✓ **truck_size**: Optional, must be valid if provided
- ✓ **manufacturer**: Required, 1-80 characters
- ✓ **year**: Optional, 1900-2100 range
- ✓ **fuel_consumption**: Positive decimal
- ✓ **max_weight**: Positive decimal
- ✓ **max_volume**: Positive decimal

## Assignment Validation

- ✓ **driver_phone**: Must exist in imported drivers
- ✓ **vehicle_license_plate**: Must exist in imported vehicles
- ✓ **assignment_type**: Must be PERMANENT or TEMPORARY
- ✓ **status**: Must be ASSIGNED, COMPLETED, or UNASSIGNED
- ✓ **assigned_at**: Required, valid DateTime
- ✓ **completed_at**: Only set if status is COMPLETED
- ✓ **unassigned_at**: Only set if status is UNASSIGNED
- ✓ No duplicate active assignments (same driver+vehicle combination)

---

# 5. IMPORT PROCESS

## Step 1: Prepare Data Files

1. Create CSV files in `data/import/` directory:
   - `drivers_import.csv`
   - `vehicles_import.csv`
   - `assignments_import.csv`

2. Validate CSV format:
   - Use correct encoding (UTF-8)
   - Use comma delimiter
   - Include header row
   - Match column names exactly

## Step 2: Run Import via Backend API

### Option A: Direct Database Import (SQL)

See `data/import/migration_import.sql`

### Option B: REST API Import

```bash
# Upload and import drivers
curl -X POST http://localhost:8080/api/admin/import/drivers \
  -H "Authorization: Bearer <token>" \
  -F "file=@drivers_import.csv"

# Upload and import vehicles
curl -X POST http://localhost:8080/api/admin/import/vehicles \
  -H "Authorization: Bearer <token>" \
  -F "file=@vehicles_import.csv"

# Upload and import assignments
curl -X POST http://localhost:8080/api/admin/import/assignments \
  -H "Authorization: Bearer <token>" \
  -F "file=@assignments_import.csv"
```

## Step 3: Validate Import

```bash
# Verify drivers count
curl -X GET http://localhost:8080/api/admin/drivers/count \
  -H "Authorization: Bearer <token>"

# Verify vehicles count
curl -X GET http://localhost:8080/api/admin/vehicles/count \
  -H "Authorization: Bearer <token>"

# Verify assignments count
curl -X GET http://localhost:8080/api/admin/assignments/count \
  -H "Authorization: Bearer <token>"
```

---

# 6. DATA EXAMPLES

## Real-World Scenario: Small Fleet (5 Drivers, 5 Vehicles, 5 Assignments)

### drivers_import.csv
```csv
first_name,last_name,phone,license_class,id_card_expiry,zone,status,performance_score,safety_score,on_time_percent
Sophea,Kong,+855971234567,C,2025-12-31,North,ACTIVE,92,Excellent,98
Visal,Mok,+855978901234,B,2026-06-30,South,ACTIVE,85,Good,90
Dara,Sarith,+855985551234,C1,2025-09-15,East,INACTIVE,78,Good,85
Bun,Rith,+855992223456,B1,2026-12-31,West,ACTIVE,95,Excellent,99
Thom,Rorn,+855981234567,A,2025-03-31,Central,ON_LEAVE,88,Good,92
```

### vehicles_import.csv
```csv
license_plate,type,truck_size,manufacturer,year,fuel_consumption,max_weight,max_volume,last_inspection_date,next_service_due,last_service_date,current_km,status
HH-1234,TRUCK,LARGE,Hino,2020,0.08,15000,30,2024-12-01,2025-03-01,2024-12-01,125000,ACTIVE
KH-5678,TRUCK,MEDIUM,Isuzu,2021,0.07,8000,20,2024-11-15,2025-02-15,2024-11-15,98500,ACTIVE
PP-9012,VAN,SMALL,Toyota,2022,0.06,3500,8,2024-10-20,2025-01-20,2024-10-20,45200,ACTIVE
SR-3456,TRUCK,LARGE,Hyundai,2019,0.09,12000,28,2024-09-10,2025-03-10,2024-09-10,201500,MAINTENANCE
BB-7890,CAR,SMALL,Toyota,2023,0.05,1500,2.5,2024-12-15,2025-03-15,2024-12-15,12300,ACTIVE
```

### assignments_import.csv
```csv
driver_phone,vehicle_license_plate,assignment_type,status,assigned_at,completed_at,unassigned_at,reason
+855971234567,HH-1234,PERMANENT,ASSIGNED,2025-01-01 09:00:00,,,"Initial permanent assignment"
+855978901234,KH-5678,PERMANENT,ASSIGNED,2025-01-05 10:30:00,,,"Initial permanent assignment"
+855985551234,PP-9012,TEMPORARY,UNASSIGNED,2024-12-20 08:00:00,,2024-12-27 17:00:00,"Temporary route completion"
+855992223456,SR-3456,PERMANENT,ASSIGNED,2025-01-10 07:00:00,,,"Initial permanent assignment"
+855981234567,BB-7890,TEMPORARY,ASSIGNED,2025-01-15 06:00:00,,,"Temporary assignment for special delivery"
```

---

# 7. TROUBLESHOOTING

## Common Issues

### Issue: "Duplicate key value violates unique constraint 'uk_vehicle_license_plate'"
**Solution**: Check that license plate doesn't already exist in database. Verify uniqueness in CSV.

### Issue: "Foreign key constraint failed for driver_id"
**Solution**: Driver phone number not found. Ensure driver was imported first and phone matches exactly.

### Issue: "Foreign key constraint failed for vehicle_id"
**Solution**: Vehicle license plate not found. Ensure vehicle was imported first and plate matches exactly.

### Issue: "Invalid enum value for status"
**Solution**: Use exact enum values: ACTIVE, INACTIVE, ON_LEAVE, TERMINATED (case-sensitive)

### Issue: "Date format error"
**Solution**: Use YYYY-MM-DD format for dates and YYYY-MM-DD HH:MM:SS for timestamps

---

# 8. BACKUP & ROLLBACK

## Backup Before Import

```bash
# Backup drivers table
mysqldump -u root -p svlogistics_tms drivers > backup_drivers.sql

# Backup vehicles table
mysqldump -u root -p svlogistics_tms vehicles > backup_vehicles.sql

# Backup assignments table
mysqldump -u root -p svlogistics_tms assignment_vehicle_to_driver > backup_assignments.sql
```

## Rollback After Import

```bash
# Restore from backup
mysql -u root -p svlogistics_tms < backup_drivers.sql
mysql -u root -p svlogistics_tms < backup_vehicles.sql
mysql -u root -p svlogistics_tms < backup_assignments.sql
```

---

# 9. REFERENCE

## File Structure
```
data/
├── import/
│   ├── drivers_import.csv
│   ├── vehicles_import.csv
│   ├── assignments_import.csv
│   ├── migration_import.sql
│   └── README.md (this file)
```

## Related Documentation
- [Backend API Documentation](BACKEND_ANGULAR_DEBUG_GUIDE.md)
- [Database Schema](tms-backend/src/main/resources/db/schema.sql)
- [Migration Guide](PRODUCTION_DEPLOYMENT_GUIDE.md)

