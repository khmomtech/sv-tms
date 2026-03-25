> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 📦 COMPLETE DATA MIGRATION PACKAGE - QUICK REFERENCE

## ✅ What's Included

### Import Templates (9 CSV files)
1. **customers_import.csv** - 10 test customers
2. **customer_addresses_import.csv** - 10 delivery addresses  
3. **drivers_import.csv** - 10 drivers
4. **vehicles_import.csv** - 10 vehicles
5. **items_import.csv** - 10 item types (NEW)
6. **zones_import.csv** - 10 delivery zones (NEW)
7. **transport_orders_import.csv** - 10 sample orders (NEW)
8. **dispatches_import.csv** - 10 dispatch assignments (NEW)

### Migration Scripts (5 SQL files)
1. **migration_customers.sql** - Customers + Addresses
2. **migration_import_v2.sql** - Drivers + Vehicles + Assignments
3. **migration_items_zones.sql** - Items + Zones (NEW)
4. **migration_orders.sql** - Transport Orders (NEW)
5. **migration_dispatches.sql** - Dispatches (NEW)
6. **migration_complete_v3.sql** - All entities at once (NEW)

### Export Scripts (2 Bash files)
1. **export_customers.sh** - Export customer data
2. **export_data.sh** - Export drivers/vehicles data

### Documentation (4 Markdown files)
1. **FIRST_DEPLOYMENT_COMPLETE_GUIDE.md** - Full deployment guide (NEW)
2. **COMPLETE_IMPORT_GUIDE.md** - Import overview
3. **SCHEMA_MAPPINGS_V2.md** - Field mappings
4. **CUSTOMER_IMPORT_GUIDE.md** - Customer specifics

---

## 🚀 Quick Start (5 Steps)

### Step 1: Prepare Environment
```bash
# Ensure MySQL, Redis, Java, Node.js are running
docker compose -f docker-compose.dev.yml up -d
```

### Step 2: Backup Database
```bash
cd data/import
mysqldump -u root -p svlogistics_tms > backups/pre_import_$(date +%Y%m%d).sql
```

### Step 3: Copy CSV Files to /tmp
```bash
cp *.csv /tmp/
ls -la /tmp/*_import.csv
```

### Step 4: Run Import Scripts (In Order)
```bash
# 1. Customers & Addresses (no dependencies)
mysql -u root -p svlogistics_tms < migration_customers.sql

# 2. Drivers, Vehicles, Assignments
mysql -u root -p svlogistics_tms < migration_import_v2.sql

# 3. Items & Zones
mysql -u root -p svlogistics_tms < migration_items_zones.sql

# 4. Orders (needs customers)
mysql -u root -p svlogistics_tms < migration_orders.sql

# 5. Dispatches (needs orders, drivers, vehicles)
mysql -u root -p svlogistics_tms < migration_dispatches.sql
```

### Step 5: Verify All Data
```bash
mysql -u root -p svlogistics_tms << EOF
SELECT 
  (SELECT COUNT(*) FROM customers WHERE deleted_at IS NULL) customers,
  (SELECT COUNT(*) FROM drivers) drivers,
  (SELECT COUNT(*) FROM vehicles) vehicles,
  (SELECT COUNT(*) FROM items WHERE status = 1) items,
  (SELECT COUNT(*) FROM zones WHERE status = 1) zones,
  (SELECT COUNT(*) FROM transport_orders WHERE deleted_at IS NULL) orders,
  (SELECT COUNT(*) FROM dispatches) dispatches;
EOF
```

---

## 📊 Data Model Overview

```
CUSTOMERS (10 records)
  ├─ Addresses (10 addresses, multiple per customer)
  └─ Transport Orders (10 orders)
      └─ Dispatch Assignments (10 dispatches)

DRIVERS (10 records)
  └─ Vehicle Assignments (10 assignments)

VEHICLES (10 records)
  └─ Dispatch Assignments

ITEMS (10 item types)

ZONES (10 zones in Cambodia)

DISPATCHES (10 active deliveries)
  ├─ Driver
  ├─ Vehicle
  └─ Transport Order
```

---

## 🔑 Key Enums & Values

### Driver Status
- `IDLE` - Available for assignment
- `ONLINE` - Working today
- `OFFLINE` - Off duty
- `BUSY` - Currently on dispatch

### Vehicle Status
- `AVAILABLE` - Ready for use
- `IN_USE` - Currently assigned
- `MAINTENANCE` - Under maintenance
- `OUT_OF_SERVICE` - Disabled

### Customer Type
- `COMPANY` - Business customer
- `INDIVIDUAL` - Personal customer

### Order Priority
- `URGENT` - Rush delivery (< 24 hrs)
- `HIGH` - Priority (1-2 days)
- `NORMAL` - Standard (2-5 days)
- `LOW` - Budget option (5+ days)

### Dispatch Status
- `ASSIGNED` - Awaiting pickup
- `PICKED_UP` - In transit
- `IN_TRANSIT` - On delivery route
- `DELIVERED` - Completed
- `CANCELLED` - Cancelled

### Item Types
- ELECTRONICS, FURNITURE, DOCUMENT, FOOD
- MACHINERY, TEXTILE, GLASS, CHEMICAL
- AUTOMOTIVE, RETAIL_GOODS, OTHER

---

## 🗂️ Import Order (Critical!)

**MUST follow this sequence:**

```
1️⃣  CUSTOMERS (no dependencies)
     ↓
2️⃣  ADDRESSES (needs CUSTOMERS)
     ↓
3️⃣  DRIVERS (no dependencies)
     ↓
4️⃣  VEHICLES (no dependencies)
     ↓
5️⃣  ASSIGNMENTS (needs DRIVERS + VEHICLES)
     ↓
6️⃣  ITEMS (no dependencies)
     ↓
7️⃣  ZONES (no dependencies)
     ↓
8️⃣  ORDERS (needs CUSTOMERS)
     ↓
9️⃣  DISPATCHES (needs ORDERS + DRIVERS + VEHICLES)
     ↓
   ✅ COMPLETE
```

**Why?** Each entity may have foreign keys (FK) to other entities. Importing in wrong order causes "foreign key constraint" errors.

---

## 📋 Entity Details

### Customers (10 records)
- Mix of COMPANY (7) and INDIVIDUAL (2) types
- Credit limits: $50K-$200K
- Payment terms: NET_30, NET_60, DUE_ON_RECEIPT
- Currency: USD
- Statuses: ACTIVE

### Addresses (10 records)
- Multiple per customer (some have 2+)
- GPS coordinates included
- Cities: Phnom Penh, Sihanoukville, Kampong Cham

### Drivers (10 records)
- Cambodian names and phone numbers (+855)
- License classes: A, B, C, D
- Status: IDLE, ONLINE, OFFLINE
- Assigned zones

### Vehicles (10 records)
- Cambodian license plates (3F-XXXX format)
- Types: Truck, Van, Car
- Sizes: BIG_TRUCK, MEDIUM_TRUCK, SMALL_VAN
- Status: AVAILABLE, IN_USE

### Items (10 types)
- Electronics, Furniture, Documents, Food, etc.
- All active (status=1)
- With Khmer translations

### Zones (10 zones)
- All Cambodian locations
- Cities: Phnom Penh, Sihanoukville, Kampong Cham, etc.
- Regions: North, South, East, West, Central

### Orders (10 orders)
- Customer references
- Priorities: URGENT, HIGH, NORMAL, LOW
- Statuses: PENDING
- Pickup/Delivery dates set for Jan 23-27, 2026

### Dispatches (10 assignments)
- Link orders to drivers + vehicles
- Status: ASSIGNED (ready to pickup)
- All have valid driver+vehicle+order

---

## 🔍 Validation Queries

```sql
-- Check customers are imported
SELECT COUNT(*) as total, 
  COUNT(DISTINCT type) as types,
  SUM(CASE WHEN status = 'ACTIVE' THEN 1 ELSE 0 END) as active
FROM customers WHERE deleted_at IS NULL;

-- Check orders with customers
SELECT COUNT(*) FROM transport_orders WHERE customer_id IS NOT NULL;

-- Check dispatches with all FKs
SELECT COUNT(*) FROM dispatches 
WHERE transport_order_id IS NOT NULL 
  AND driver_id IS NOT NULL 
  AND vehicle_id IS NOT NULL;

-- Check driver assignments
SELECT COUNT(*) FROM assignment_vehicle_to_driver 
WHERE status = 'PERMANENT';

-- Distribution by zone
SELECT zone_code, COUNT(*) FROM transport_orders 
GROUP BY zone_code;
```

---

## 🧪 Testing After Import

### 1. API Test
```bash
curl -X GET http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer <token>"
```

### 2. Admin UI Test
- Open http://localhost:4200
- Check Dashboard shows all counts
- Navigate to Customers, Drivers, Vehicles, Orders pages
- Verify data displays correctly

### 3. Customer App Test
```bash
cd tms_customer_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --flavor dev
# Login with: testcustomer / Test@2024
# See orders and items
```

### 4. Real-Time Test
- Update order status in backend
- Watch customer app update instantly
- Check WebSocket in browser DevTools

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---------|----------|
| "Duplicate entry" | Remove duplicate rows from CSV |
| "Foreign key constraint" | Import entities in correct order |
| "File not found" | Copy CSVs to /tmp first |
| "Access denied" | Check MySQL FILE privileges |
| "0 rows imported" | Check CSV format (delimiter, encoding) |

---

## 📚 Full Documentation Files

| File | Purpose | Size |
|------|---------|------|
| FIRST_DEPLOYMENT_COMPLETE_GUIDE.md | Full deployment checklist | 800 lines |
| COMPLETE_IMPORT_GUIDE.md | Import overview | 600 lines |
| SCHEMA_MAPPINGS_V2.md | Field mappings | 400 lines |
| PRE_MIGRATION_CHECKLIST_V2.md | Validation steps | 400 lines |
| CUSTOMER_IMPORT_GUIDE.md | Customer details | 300 lines |
| CUSTOMER_APP_LOGIN_AND_ITEMS_GUIDE.md | Customer app setup | 400 lines |

---

## ✅ Pre-Deployment Checklist

- [ ] All CSV files in `/tmp/` 
- [ ] Database backed up
- [ ] MySQL, Redis running
- [ ] Backend starts successfully
- [ ] Admin UI loads at :4200
- [ ] Import scripts run with 0 errors
- [ ] All record counts verified
- [ ] No FK constraint violations
- [ ] Customer app can login
- [ ] Real-time updates working
- [ ] Ready for production

---

## 🎯 Success Criteria

✅ All import scripts execute without errors  
✅ Record counts match expected values  
✅ All FK relationships valid  
✅ Backend API returns correct data  
✅ Admin UI displays all entities  
✅ Customer app login works  
✅ Driver app login works  
✅ Real-time updates via WebSocket  
✅ Database backups automated  

---

**Status**: ✅ **COMPLETE & READY**  
**Entities**: 9 (Customers, Addresses, Drivers, Vehicles, Assignments, Items, Zones, Orders, Dispatches)  
**Records**: 70+ test data records  
**Scripts**: 5 SQL migration scripts  
**Next Step**: Execute [FIRST_DEPLOYMENT_COMPLETE_GUIDE.md](./FIRST_DEPLOYMENT_COMPLETE_GUIDE.md)
