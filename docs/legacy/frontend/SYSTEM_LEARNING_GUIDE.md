> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# System Architecture & Data Model Learning Guide

## 🏗️ SV-TMS System Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SV Transport Management System             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Angular    │  │   Flutter    │  │   Flutter    │       │
│  │   Admin      │  │   Driver     │  │   Customer   │       │
│  │   Frontend   │  │   Mobile App │  │   Mobile App │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                 │               │
│         └─────────────────┼─────────────────┘               │
│                          │ HTTP/WebSocket                   │
│         ┌────────────────▼────────────────┐                 │
│         │   Spring Boot 3.5 Backend API   │                 │
│         │   (Java 21, MySQL 8, Redis 7)  │                 │
│         └────────────────┬────────────────┘                 │
│                          │                                  │
│         ┌────────────────┼────────────────┐                 │
│         │                │                │                 │
│      ┌──▼──┐       ┌────▼────┐      ┌────▼────┐            │
│      │MySQL│       │  Redis  │      │Firebase │            │
│      │  8.0│       │    7    │      │ Admin   │            │
│      └─────┘       └─────────┘      └─────────┘            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

1. **Backend (tms-backend/)**
   - REST API endpoints (/api/admin/*, /api/driver/*, /api/customer/*)
   - Entity models (Driver, Vehicle, AssignmentVehicleToDriver)
   - Business logic and services
   - Database access layer (JPA repositories)

2. **Frontend (tms-frontend/)**
   - Angular 19 single-page application
   - Admin UI for fleet management
   - Dispatcher dashboard
   - Material Design components

3. **Mobile Apps**
   - Driver App (Flutter) - driver tasks, assignments, delivery
   - Customer App (Flutter) - order tracking, notifications

4. **Data Layer**
   - MySQL 8.0 - primary database
   - Redis 7 - caching, sessions
   - Firebase Admin - push notifications

---

## 🗄️ Database Core Tables

### 1. Drivers Table

```sql
CREATE TABLE drivers (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  name VARCHAR(160),                 -- Computed: first_name + " " + last_name
  phone VARCHAR(20) NOT NULL UNIQUE,
  license_class VARCHAR(10),         -- A1, A, B1, B, C, C1, D, E (Cambodia)
  id_card_expiry DATE,
  zone VARCHAR(50),                  -- Geographic zone
  status ENUM('ACTIVE','INACTIVE','ON_LEAVE','TERMINATED') DEFAULT 'ACTIVE',
  is_active BOOLEAN DEFAULT true,
  performance_score INT DEFAULT 92,  -- 0-100
  on_time_percent INT DEFAULT 98,    -- 0-100
  safety_score VARCHAR(50) DEFAULT 'Excellent', -- Excellent, Good, Fair, Poor
  leaderboard_rank INT DEFAULT 0,
  rating DOUBLE,                     -- 1-5 stars
  device_token VARCHAR(500),         -- FCM push notification token
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Indexes for performance
  INDEX idx_driver_phone (phone),
  INDEX idx_driver_status (status),
  INDEX idx_driver_zone (zone)
);
```

**Key Relationships:**
- One Driver can have Many Assignments
- One Driver can have One License (DriverLicense)
- One Driver can have Many Location History records

---

### 2. Vehicles Table

```sql
CREATE TABLE vehicles (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  license_plate VARCHAR(20) NOT NULL UNIQUE,
  type ENUM('TRUCK','CAR','MOTORCYCLE','VAN') NOT NULL,
  truck_size ENUM('SMALL','MEDIUM','LARGE'),  -- SMALL (1-3T), MEDIUM (3-5T), LARGE (5T+)
  manufacturer VARCHAR(80) NOT NULL,          -- Brand: Hino, Isuzu, Hyundai, Toyota
  year INT,                                    -- 1900-2100
  fuel_consumption DECIMAL(8,2),               -- Liters/km
  max_weight DECIMAL(10,2),                    -- kg or tons
  max_volume DECIMAL(10,2),                    -- cubic meters
  last_inspection_date DATE,
  next_service_due DATE,
  last_service_date DATE,
  current_km INT,                              -- Current odometer
  status ENUM('ACTIVE','MAINTENANCE','RETIRED','INACTIVE') DEFAULT 'ACTIVE',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Indexes for performance
  INDEX idx_vehicle_license_plate (license_plate),
  INDEX idx_vehicle_status (status),
  INDEX idx_vehicle_type (type),
  UNIQUE KEY uk_vehicle_license_plate (license_plate)
);
```

**Key Relationships:**
- One Vehicle can have Many Assignments
- One Vehicle can have Many Route assignments (VehicleRoute)
- One Vehicle can have Many Maintenance Tasks

---

### 3. AssignmentVehicleToDriver Table (Core Relationship)

```sql
CREATE TABLE assignment_vehicle_to_driver (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  driver_id BIGINT NOT NULL,                 -- Foreign key to drivers
  vehicle_id BIGINT NOT NULL,                -- Foreign key to vehicles
  assigned_at TIMESTAMP NOT NULL,            -- When assignment started
  completed_at TIMESTAMP,                    -- When completed naturally
  unassigned_at TIMESTAMP,                   -- When forcefully unassigned
  status ENUM('ASSIGNED','COMPLETED','UNASSIGNED') NOT NULL,
  assignment_type ENUM('PERMANENT','TEMPORARY') NOT NULL,
  reason VARCHAR(255),                       -- Audit trail
  version BIGINT DEFAULT 0,                  -- Optimistic locking
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Foreign keys
  CONSTRAINT fk_driver FOREIGN KEY (driver_id) REFERENCES drivers(id),
  CONSTRAINT fk_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
  
  -- Indexes for performance
  INDEX idx_driver_id (driver_id),
  INDEX idx_vehicle_id (vehicle_id),
  INDEX idx_status (status),
  INDEX idx_assigned_dates (assigned_at, unassigned_at)
);
```

**Key Business Rules:**
- One Driver can be assigned to Multiple Vehicles over time
- One Vehicle can be assigned to Multiple Drivers over time
- At any given time, a Vehicle can have only ONE active (ASSIGNED) Driver
- At any given time, a Driver can have only ONE active (ASSIGNED) Vehicle
- Assignment Type:
  - **PERMANENT**: Long-term assignment (continuous service)
  - **TEMPORARY**: Short-term assignment (specific route or task)
- Assignment Status:
  - **ASSIGNED**: Currently active
  - **COMPLETED**: Finished naturally (completed_at is set)
  - **UNASSIGNED**: Forcefully ended (unassigned_at is set)

---

## 📋 Data Relationships Diagram

```
┌──────────────────┐
│    DRIVER        │ (Entity 1)
├──────────────────┤
│ id               │
│ firstName        │
│ lastName         │
│ phone (UNIQUE)   │
│ licenseClass     │
│ status           │
│ performanceScore │
│ created_at       │
└────────┬─────────┘
         │ 1
         │
         │ (1:Many)
         │
         │ Many
    ┌────▼─────────────────────────────┐
    │ ASSIGNMENT_VEHICLE_TO_DRIVER     │ (Junction Table)
    ├─────────────────────────────────┤
    │ id                               │
    │ driver_id (FK → Driver.id)       │
    │ vehicle_id (FK → Vehicle.id)     │
    │ assigned_at                      │
    │ completed_at                     │
    │ unassigned_at                    │
    │ status                           │
    │ assignment_type                  │
    │ reason                           │
    └────┬─────────────────────────────┘
         │ Many
         │
         │ (Many:1)
         │
         │ 1
    ┌────▼─────────────┐
    │    VEHICLE       │ (Entity 2)
    ├──────────────────┤
    │ id               │
    │ licensePlate     │
    │ type             │
    │ truckSize        │
    │ manufacturer     │
    │ year             │
    │ status           │
    │ currentKm        │
    │ created_at       │
    └──────────────────┘
```

---

## 🔍 Data Import Flow

### Phase 1: Driver Import
```
CSV: drivers_import.csv
  ↓
Validation (phone unique, status enum, etc)
  ↓
INSERT INTO drivers (first_name, last_name, phone, ...)
  ↓
✅ Drivers available for assignments
```

### Phase 2: Vehicle Import
```
CSV: vehicles_import.csv
  ↓
Validation (license_plate unique, type enum, etc)
  ↓
INSERT INTO vehicles (license_plate, type, manufacturer, ...)
  ↓
✅ Vehicles available for assignments
```

### Phase 3: Assignment Import
```
CSV: assignments_import.csv
  ↓
Lookup Driver by phone
Lookup Vehicle by license_plate
  ↓
Validation (references exist, no active conflicts)
  ↓
INSERT INTO assignment_vehicle_to_driver (driver_id, vehicle_id, ...)
  ↓
✅ Driver-Vehicle relationships established
```

---

## 💾 Sample Data Scenario

### 10 Drivers (Various Zones)

| ID | Name | Phone | Zone | Status | Performance |
|---|---|---|---|---|---|
| 1 | Sophea Kong | +855971234567 | North | ACTIVE | 92 |
| 2 | Visal Mok | +855978901234 | South | ACTIVE | 85 |
| 3 | Dara Sarith | +855985551234 | East | INACTIVE | 78 |
| ... | ... | ... | ... | ... | ... |
| 10 | Khem Kol | +855984321098 | Central | ACTIVE | 84 |

### 10 Vehicles (Various Types)

| ID | Plate | Type | Truck Size | Manufacturer | Status |
|---|---|---|---|---|---|
| 1 | HH-1234 | TRUCK | LARGE | Hino | ACTIVE |
| 2 | KH-5678 | TRUCK | MEDIUM | Isuzu | ACTIVE |
| 3 | PP-9012 | VAN | SMALL | Toyota | ACTIVE |
| ... | ... | ... | ... | ... | ... |
| 10 | DB-6789 | TRUCK | LARGE | Hino | ACTIVE |

### 10 Assignments (Links)

| ID | Driver ID | Vehicle ID | Type | Status | Assigned At |
|---|---|---|---|---|---|
| 1 | 1 | 1 | PERMANENT | ASSIGNED | 2025-01-01 |
| 2 | 2 | 2 | PERMANENT | ASSIGNED | 2025-01-05 |
| 3 | 3 | 3 | TEMPORARY | UNASSIGNED | 2024-12-20 |
| ... | ... | ... | ... | ... | ... |
| 10 | 10 | 10 | PERMANENT | ASSIGNED | 2025-01-04 |

---

## 🔑 Key Concepts

### Driver Status Lifecycle
```
ACTIVE (Normal Operation)
  ↓
ON_LEAVE (Temporary leave)
  ↓
ACTIVE (Resume)
  ↓
TERMINATED (End employment)

or

INACTIVE (Suspended)
```

### Vehicle Status Lifecycle
```
ACTIVE (In Service)
  ↓
MAINTENANCE (Scheduled maintenance)
  ↓
ACTIVE (Resume service)
  ↓
RETIRED (End of life)

or

INACTIVE (Decommissioned)
```

### Assignment Status Lifecycle
```
ASSIGNED (Current assignment)
  ↓
COMPLETED (Assignment done, completed_at set)
or
UNASSIGNED (Forcefully ended, unassigned_at set)
```

---

## 📊 Querying Patterns

### Get Active Assignments (Current Status)
```sql
SELECT 
  d.id, d.first_name, d.last_name,
  v.license_plate, v.type,
  a.assigned_at
FROM assignment_vehicle_to_driver a
JOIN drivers d ON a.driver_id = d.id
JOIN vehicles v ON a.vehicle_id = v.id
WHERE a.status = 'ASSIGNED'
  AND d.status = 'ACTIVE'
  AND v.status = 'ACTIVE';
```

### Get Driver's Assignment History
```sql
SELECT 
  v.license_plate, v.type,
  a.assignment_type,
  a.assigned_at, a.completed_at, a.unassigned_at,
  a.status
FROM assignment_vehicle_to_driver a
JOIN vehicles v ON a.vehicle_id = v.id
WHERE a.driver_id = ?
ORDER BY a.assigned_at DESC;
```

### Get Vehicle's Assignment History
```sql
SELECT 
  d.first_name, d.last_name,
  a.assignment_type,
  a.assigned_at, a.completed_at, a.unassigned_at,
  a.status
FROM assignment_vehicle_to_driver a
JOIN drivers d ON a.driver_id = d.id
WHERE a.vehicle_id = ?
ORDER BY a.assigned_at DESC;
```

### Find Unassigned Drivers
```sql
SELECT DISTINCT d.*
FROM drivers d
LEFT JOIN assignment_vehicle_to_driver a 
  ON d.id = a.driver_id 
  AND a.status = 'ASSIGNED'
WHERE a.id IS NULL
  AND d.status = 'ACTIVE';
```

### Find Unassigned Vehicles
```sql
SELECT DISTINCT v.*
FROM vehicles v
LEFT JOIN assignment_vehicle_to_driver a 
  ON v.id = a.vehicle_id 
  AND a.status = 'ASSIGNED'
WHERE a.id IS NULL
  AND v.status = 'ACTIVE';
```

---

## 🚀 Backend API Endpoints

### Driver Endpoints
```
GET    /api/admin/drivers              - List all drivers
GET    /api/admin/drivers/{id}         - Get driver details
POST   /api/admin/drivers              - Create driver
PUT    /api/admin/drivers/{id}         - Update driver
DELETE /api/admin/drivers/{id}         - Delete driver
GET    /api/admin/drivers/phone/{phone} - Get by phone
```

### Vehicle Endpoints
```
GET    /api/admin/vehicles              - List all vehicles
GET    /api/admin/vehicles/{id}         - Get vehicle details
POST   /api/admin/vehicles              - Create vehicle
PUT    /api/admin/vehicles/{id}         - Update vehicle
DELETE /api/admin/vehicles/{id}         - Delete vehicle
GET    /api/admin/vehicles/plate/{plate} - Get by license plate
```

### Assignment Endpoints
```
GET    /api/admin/assignments           - List assignments
GET    /api/admin/assignments/{id}      - Get assignment details
POST   /api/admin/assignments           - Create assignment
PUT    /api/admin/assignments/{id}      - Update assignment
DELETE /api/admin/assignments/{id}      - Delete assignment
GET    /api/admin/drivers/{id}/assignments      - Get driver's assignments
GET    /api/admin/vehicles/{id}/assignments     - Get vehicle's assignments
```

---

## 🎯 Business Rules Summary

1. **Driver Requirements**
   - Phone number must be unique
   - First name and last name are required
   - License class must be valid Cambodia category
   - Can only have one active assignment at a time

2. **Vehicle Requirements**
   - License plate must be unique
   - Type must be TRUCK, CAR, MOTORCYCLE, or VAN
   - Manufacturer is required
   - Can only have one active driver at a time

3. **Assignment Rules**
   - Must reference existing driver and vehicle
   - Can be PERMANENT or TEMPORARY
   - Can be ASSIGNED, COMPLETED, or UNASSIGNED
   - assigned_at timestamp is mandatory
   - completed_at only set if status is COMPLETED
   - unassigned_at only set if status is UNASSIGNED
   - No overlapping active assignments for same driver/vehicle pair

---

## 🔐 Authorization

The system enforces API boundaries:

- **Admin UI** → `/api/admin/*` (full fleet management)
- **Driver App** → `/api/driver/*` (only driver's own data)
- **Customer App** → `/api/customer/{customerId}/*` (only customer's orders)

---

## 📚 Related Documentation

- [Data Import Template Guide](../DATA_IMPORT_TEMPLATE_GUIDE.md)
- [Backend API Documentation](../BACKEND_ANGULAR_DEBUG_GUIDE.md)
- [Database Schema](../../tms-backend/src/main/resources/db/schema.sql)
- [Entity Models](../../tms-backend/src/main/java/com/svtrucking/logistics/model/)

---

**Created**: January 22, 2025
**Version**: 1.0
**Purpose**: System understanding for pre-deploy data migration
