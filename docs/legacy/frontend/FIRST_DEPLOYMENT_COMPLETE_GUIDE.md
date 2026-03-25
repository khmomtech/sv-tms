> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🚀 COMPLETE FIRST DEPLOYMENT & DATA MIGRATION GUIDE

## 📋 Master Checklist for First Deployment

### Phase 1: Pre-Deployment (Infrastructure) - Days 1-2

- [ ] **Database Setup**
  - [ ] MySQL 8 installed and running
  - [ ] Create database: `svlogistics_tms`
  - [ ] Import schema: `mysql svlogistics_tms < backup.sql`
  - [ ] Verify tables: `mysql svlogistics_tms -e "SHOW TABLES;" | wc -l`
  - [ ] Set up backups: Daily dumps to `/backup/`

- [ ] **Redis Setup**
  - [ ] Redis 7 installed and running on port 6379
  - [ ] Test connection: `redis-cli ping` → "PONG"
  - [ ] Configure persistence: `save 900 1`

- [ ] **Backend Services**
  - [ ] Java 21 installed: `java -version`
  - [ ] Maven 3.9+ installed: `mvn -version`
  - [ ] Spring Boot 3.5.7 configured
  - [ ] .env configured with DB credentials
  - [ ] Backend builds successfully: `./mvnw clean package`
  - [ ] Backend starts: `./mvnw spring-boot:run`
  - [ ] Health check passes: `curl http://localhost:8080/health`

- [ ] **Frontend Setup**
  - [ ] Node.js 18+ installed: `node -v`
  - [ ] Angular 19 dependencies: `npm ci --legacy-peer-deps`
  - [ ] Angular dev server runs: `npm start`
  - [ ] Access http://localhost:4200 (no errors)

- [ ] **Mobile Apps**
  - [ ] Flutter 3.5+ installed: `flutter --version`
  - [ ] Android emulator or device ready
  - [ ] iOS simulator or device ready (if needed)
  - [ ] build.gradle flavors configured (dev, uat, prod)

---

### Phase 2: Core Data Import (Entities) - Days 2-3

#### Step 1: Copy Import Templates

```bash
cd data/import
ls -la *.csv  # Verify all templates present
```

**Required files:**
- ✅ drivers_import.csv
- ✅ vehicles_import.csv
- ✅ customers_import.csv
- ✅ customer_addresses_import.csv
- ✅ items_import.csv
- ✅ zones_import.csv
- ✅ transport_orders_import.csv
- ✅ dispatches_import.csv

#### Step 2: Validate CSV Templates

```bash
# Check for duplicates
cut -d',' -f1 drivers_import.csv | tail -n +2 | sort | uniq -c | grep -v "^ *1 "
cut -d',' -f1 vehicles_import.csv | tail -n +2 | sort | uniq -c | grep -v "^ *1 "
cut -d',' -f1 customers_import.csv | tail -n +2 | sort | uniq -c | grep -v "^ *1 "

# Check enum values
cut -d',' -f8 drivers_import.csv | tail -n +2 | sort | uniq
cut -d',' -f12 vehicles_import.csv | tail -n +2 | sort | uniq
cut -d',' -f3 customers_import.csv | tail -n +2 | sort | uniq
```

**Expected output:**
- Drivers status: `IDLE|ONLINE|OFFLINE|BUSY`
- Vehicles status: `AVAILABLE|IN_USE|MAINTENANCE`
- Customers type: `COMPANY|INDIVIDUAL`

#### Step 3: Backup Database

```bash
# Full backup before any imports
mysqldump -u root -p svlogistics_tms > backups/pre_import_$(date +%Y%m%d_%H%M%S).sql

# Verify backup
ls -lh backups/pre_import_*
```

#### Step 4: Import Data (Sequential Order Important)

```bash
# 1. Import Customers & Addresses (no dependencies)
mysql -u root -p svlogistics_tms < migration_customers.sql 2>&1 | tee import_customers.log

# Verify
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as customers FROM customers WHERE deleted_at IS NULL;"
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as addresses FROM addresses;"

# 2. Import Drivers, Vehicles, Assignments (no FK dependencies)
mysql -u root -p svlogistics_tms < migration_import_v2.sql 2>&1 | tee import_drivers_vehicles.log

# Verify
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as drivers FROM drivers;"
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as vehicles FROM vehicles;"
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as assignments FROM assignment_vehicle_to_driver;"

# 3. Import Items & Zones (no dependencies)
mysql -u root -p svlogistics_tms < migration_items_zones.sql 2>&1 | tee import_items_zones.log

# Verify
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as items FROM items WHERE status = 1;"
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as zones FROM zones WHERE status = 1;"

# 4. Import Transport Orders (requires customers)
mysql -u root -p svlogistics_tms < migration_orders.sql 2>&1 | tee import_orders.log

# Verify
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as orders FROM transport_orders WHERE deleted_at IS NULL;"

# 5. Import Dispatches (requires orders, drivers, vehicles)
mysql -u root -p svlogistics_tms < migration_dispatches.sql 2>&1 | tee import_dispatches.log

# Verify
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as dispatches FROM dispatches;"
```

#### Step 5: Verify All Imports

```bash
# Run comprehensive integrity check
mysql -u root -p svlogistics_tms < data/import/migration_complete_v3.sql 2>&1 | tee import_verification.log

# Key checks
mysql -u root -p svlogistics_tms -e "
SELECT 
  (SELECT COUNT(*) FROM customers WHERE deleted_at IS NULL) as customers,
  (SELECT COUNT(*) FROM drivers) as drivers,
  (SELECT COUNT(*) FROM vehicles) as vehicles,
  (SELECT COUNT(*) FROM items WHERE status = 1) as items,
  (SELECT COUNT(*) FROM zones WHERE status = 1) as zones,
  (SELECT COUNT(*) FROM transport_orders WHERE deleted_at IS NULL) as orders,
  (SELECT COUNT(*) FROM dispatches) as dispatches;
"
```

---

### Phase 3: User Accounts Setup - Day 3

#### Step 1: Create Admin Account

Via backend API or MySQL directly:

```bash
# Option A: Via Admin UI (after frontend is running)
# 1. Open http://localhost:4200
# 2. Login page appears
# 3. Create admin account (or use seed data)

# Option B: Direct to database
mysql -u root -p svlogistics_tms << EOF
INSERT INTO users (username, password, email, enabled, account_non_locked, account_non_expired, credentials_non_expired, created_at)
VALUES ('admin', SHA2('Admin@2024', 256), 'admin@svtrucking.com', 1, 1, 1, 1, NOW());

INSERT INTO roles (name, description) VALUES ('ADMIN', 'Administrator role');
INSERT INTO user_roles (user_id, role_id) VALUES (1, (SELECT id FROM roles WHERE name = 'ADMIN'));
EOF
```

#### Step 2: Create Sample Customer Accounts

```bash
# Via Admin UI:
# 1. Customers page → Select a customer
# 2. Click "Create Account"
# 3. Username: abc_company, Email: abc@company.com, Password: Test@2024
# 4. Save

# OR via API
curl -X POST http://localhost:8080/api/admin/customers/{customer_id}/account \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -d '{
    "username": "testcustomer",
    "email": "test@customer.com",
    "password": "Test@2024"
  }'
```

#### Step 3: Create Driver Accounts

```bash
# Via Admin UI:
# 1. Drivers page → Driver Accounts tab
# 2. Click "Create Account"
# 3. Username: driver_name, Password: Driver@2024
# 4. Assign roles: DRIVER
# 5. Save
```

---

### Phase 4: System Testing - Day 3-4

#### Test 1: Backend API Endpoints

```bash
# Health check
curl -X GET http://localhost:8080/health

# List customers
curl -X GET http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer <ADMIN_TOKEN>"

# List drivers
curl -X GET http://localhost:8080/api/admin/drivers \
  -H "Authorization: Bearer <ADMIN_TOKEN>"

# List vehicles
curl -X GET http://localhost:8080/api/admin/vehicles \
  -H "Authorization: Bearer <ADMIN_TOKEN>"

# List orders
curl -X GET http://localhost:8080/api/transport-orders \
  -H "Authorization: Bearer <ADMIN_TOKEN>"

# List dispatches
curl -X GET http://localhost:8080/api/dispatches \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
```

#### Test 2: Admin UI Dashboard

1. Open http://localhost:4200
2. Login with admin account
3. Verify pages load:
   - ✅ Dashboard shows metrics
   - ✅ Customers page shows all customers
   - ✅ Drivers page shows all drivers
   - ✅ Vehicles page shows all vehicles
   - ✅ Orders page shows all orders
   - ✅ Real-time data updates

#### Test 3: Customer App Login

```bash
# Terminal 1: Start backend
cd tms-backend && ./mvnw spring-boot:run

# Terminal 2: Start customer app (Android emulator)
cd tms_customer_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --flavor dev

# Test flow:
# 1. App opens → Login page
# 2. Enter: username=testcustomer, password=Test@2024
# 3. Login → Orders page appears
# 4. Tap order → See order details and items
# 5. Real-time updates (if order status changes)
```

#### Test 4: Driver App Testing

```bash
# Terminal 1: Start backend
cd tms-backend && ./mvnw spring-boot:run

# Terminal 2: Start driver app (Android emulator)
cd tms_driver_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --flavor dev

# Test flow:
# 1. App opens → Login page
# 2. Enter: username=<driver_username>, password=Driver@2024
# 3. Login → Assignments page
# 4. See assigned dispatch
# 5. Accept → Start delivery
# 6. Track location & update status
```

#### Test 5: WebSocket Real-Time Updates

```bash
# In browser console (http://localhost:4200)
// Check WebSocket connection
console.log('WebSocket status:', document.title);

// Subscribe to notifications
// (automatic in app, verify in Network tab)
```

---

### Phase 5: Production Deployment - Day 4

#### Pre-Production Checklist

- [ ] All imports completed with 0 errors
- [ ] All APIs returning correct data
- [ ] Admin UI loads without errors
- [ ] Customer app can login and see orders
- [ ] Driver app can login and accept assignments
- [ ] WebSocket real-time updates working
- [ ] Database backups automated
- [ ] SSL/TLS certificates configured
- [ ] CORS whitelist configured
- [ ] Rate limiting configured
- [ ] Logging levels set appropriately

#### Deployment Steps

```bash
# 1. Production database setup (separate from dev)
mysql -u prod_user -p -e "CREATE DATABASE svlogistics_tms_prod;"
mysql -u prod_user -p svlogistics_tms_prod < schema_backup.sql

# 2. Import production data
cd data/import
# Update import CSVs with production data (not test data)
mysql -u prod_user -p svlogistics_tms_prod < migration_complete_v3.sql

# 3. Backend deployment
cd tms-backend
./mvnw clean package -DskipTests -P prod
# Deploy JAR to server

# 4. Frontend deployment
cd tms-frontend
npm ci --legacy-peer-deps
npm run build  # Creates dist/
# Deploy dist/ to CDN or web server

# 5. Mobile apps
cd tms_customer_app
flutter build apk --flavor prod --release  # APK for Google Play
flutter build ios --release  # IPA for App Store

# 6. Verify production
curl -X GET https://api.svtrucking.com/health
# Should return healthy status
```

---

## 📊 Complete Data Migration Matrix

| Entity | Importance | Dependencies | Import Script | CSV File | Records | Status |
|--------|-----------|--------------|---------------|----------|---------|--------|
| **Customers** | CRITICAL | None | migration_customers.sql | customers_import.csv | 10 | ✅ Ready |
| **Addresses** | CRITICAL | customers | migration_customers.sql | customer_addresses_import.csv | 10 | ✅ Ready |
| **Drivers** | CRITICAL | None | migration_import_v2.sql | drivers_import.csv | 10 | ✅ Ready |
| **Vehicles** | CRITICAL | None | migration_import_v2.sql | vehicles_import.csv | 10 | ✅ Ready |
| **Assignments** | CRITICAL | drivers, vehicles | migration_import_v2.sql | assignments_import.csv | 10 | ✅ Ready |
| **Items** | HIGH | None | migration_complete_v3.sql | items_import.csv | 10 | ✅ Ready |
| **Zones** | HIGH | None | migration_complete_v3.sql | zones_import.csv | 10 | ✅ Ready |
| **Orders** | HIGH | customers | migration_complete_v3.sql | transport_orders_import.csv | 10 | ✅ Ready |
| **Dispatches** | HIGH | orders, drivers, vehicles | migration_complete_v3.sql | dispatches_import.csv | 10 | ✅ Ready |
| **Users** | HIGH | None | Manual/SQL | N/A | 3+ | 🟡 Setup |
| **Roles/Permissions** | HIGH | None | Seed data | N/A | 5 | 🟡 Setup |

---

## 📁 File Organization

```
sv-tms/
├── data/import/
│   ├── customers_import.csv                    ✅ 10 rows
│   ├── customer_addresses_import.csv           ✅ 10 rows
│   ├── drivers_import.csv                      ✅ 10 rows
│   ├── vehicles_import.csv                     ✅ 10 rows
│   ├── items_import.csv                        ✅ 10 rows
│   ├── zones_import.csv                        ✅ 10 rows
│   ├── transport_orders_import.csv             ✅ 10 rows
│   ├── dispatches_import.csv                   ✅ 10 rows
│   │
│   ├── migration_customers.sql                 ✅ Customers + Addresses
│   ├── migration_import_v2.sql                 ✅ Drivers + Vehicles + Assignments
│   ├── migration_complete_v3.sql               ✅ All entities (Items through Dispatches)
│   │
│   ├── export_customers.sh                     ✅ Export script
│   ├── export_data.sh                          ✅ Export script
│   │
│   ├── COMPLETE_IMPORT_GUIDE.md                📖 Guide (this file)
│   ├── CUSTOMER_IMPORT_GUIDE.md                📖 Customer specifics
│   ├── SCHEMA_MAPPINGS_V2.md                   📖 Field mappings
│   └── PRE_MIGRATION_CHECKLIST_V2.md           ✅ Validation checklist
│
├── backups/
│   ├── pre_import_20260122_140000.sql         💾 Pre-import backup
│   └── pre_import_20260122_150000.sql         💾 Incremental backup
│
└── logs/
    ├── import_customers.log                    📝 Import logs
    ├── import_drivers_vehicles.log             📝 Import logs
    ├── import_items_zones.log                  📝 Import logs
    ├── import_orders.log                       📝 Import logs
    ├── import_dispatches.log                   📝 Import logs
    └── import_verification.log                 📝 Final verification
```

---

## 🔄 Import Workflow Summary

```
START
  ↓
[1] Prepare Infrastructure
  - MySQL, Redis, Java, Node.js
  ↓
[2] Validate CSV Templates
  - Check duplicates
  - Verify enums
  - Check FK references
  ↓
[3] Backup Database
  - Full dump before changes
  ↓
[4] Import Sequential
  1. Customers → Addresses
  2. Drivers → Vehicles → Assignments
  3. Items → Zones
  4. Orders (needs customers)
  5. Dispatches (needs orders+drivers+vehicles)
  ↓
[5] Verify Integrity
  - Run integrity checks
  - Validate all FK relationships
  - Check record counts
  ↓
[6] Setup User Accounts
  - Create admin
  - Create customer accounts
  - Create driver accounts
  ↓
[7] Test All Flows
  - API endpoints
  - Admin UI dashboard
  - Customer app login
  - Driver app assignments
  - WebSocket updates
  ↓
[8] Production Deploy
  - Use production database
  - Import production data
  - Deploy backend/frontend
  - Build mobile apps
  ↓
SUCCESS ✅
```

---

## ⚡ Quick Commands

### Export Current Data (Backup/Validation)

```bash
cd data/import

# Export drivers, vehicles, assignments
./export_data.sh

# Export customers and addresses
./export_customers.sh

# Results appear in:
# - exports_TIMESTAMP/
# - customer_exports_TIMESTAMP/
```

### Import All Data

```bash
cd data/import

# One-line import all (careful - use after backup!)
mysql -u root -p svlogistics_tms < migration_customers.sql && \
mysql -u root -p svlogistics_tms < migration_import_v2.sql && \
mysql -u root -p svlogistics_tms < migration_complete_v3.sql
```

### Verify Imports

```bash
# Quick count check
mysql -u root -p svlogistics_tms << EOF
SELECT 
  (SELECT COUNT(*) FROM customers WHERE deleted_at IS NULL) as customers,
  (SELECT COUNT(*) FROM drivers) as drivers,
  (SELECT COUNT(*) FROM vehicles) as vehicles,
  (SELECT COUNT(*) FROM items WHERE status = 1) as items,
  (SELECT COUNT(*) FROM zones WHERE status = 1) as zones,
  (SELECT COUNT(*) FROM transport_orders WHERE deleted_at IS NULL) as orders,
  (SELECT COUNT(*) FROM dispatches) as dispatches;
EOF

# Detailed report
mysql -u root -p svlogistics_tms < migration_complete_v3.sql
```

### Rollback (If Something Goes Wrong)

```bash
# 1. Stop backend
# 2. Restore from backup
mysql -u root -p svlogistics_tms < backups/pre_import_20260122_140000.sql

# 3. Restart backend
# 4. Investigate issue
# 5. Try import again
```

---

## 📞 Support & Troubleshooting

### Common Issues

**Issue: "Access denied" during import**
```bash
# Solution: MySQL secure_file_priv
SHOW VARIABLES LIKE 'secure_file_priv';
# Should show: /tmp/ or NULL (unrestricted)
# If restricted, copy CSVs to that path
```

**Issue: "Foreign key constraint fails"**
```bash
# Solution: Import in correct order
# CSVs must reference existing data:
# 1. Orders references customers
# 2. Dispatches reference orders, drivers, vehicles
# 3. Follow import sequence strictly
```

**Issue: "Duplicate entry for unique key"**
```bash
# Solution: CSV has duplicate values
# Remove duplicates:
cut -d',' -f1 import.csv | sort | uniq -d
# Edit CSV to remove or rename duplicates
```

---

## ✅ Pre-Deployment Validation

Run this script before going live:

```bash
#!/bin/bash

echo "🔍 Pre-Deployment Validation"

# 1. Database health
echo -n "Database: "
mysql -u root -p svlogistics_tms -e "SELECT 'OK';" 2>/dev/null && echo "✓" || echo "✗"

# 2. Record counts
echo "Record Counts:"
mysql -u root -p svlogistics_tms << EOF
SELECT CONCAT('  Customers: ', COUNT(*)) FROM customers WHERE deleted_at IS NULL;
SELECT CONCAT('  Drivers: ', COUNT(*)) FROM drivers;
SELECT CONCAT('  Vehicles: ', COUNT(*)) FROM vehicles;
SELECT CONCAT('  Orders: ', COUNT(*)) FROM transport_orders WHERE deleted_at IS NULL;
SELECT CONCAT('  Dispatches: ', COUNT(*)) FROM dispatches;
EOF

# 3. Backend
echo -n "Backend API: "
curl -s http://localhost:8080/health | grep -q "UP" && echo "✓" || echo "✗"

# 4. Frontend
echo -n "Admin UI: "
curl -s http://localhost:4200 | grep -q "html" && echo "✓" || echo "✗"

echo "✅ Pre-deployment validation complete"
```

---

## 📚 Related Documentation

- [COMPLETE_IMPORT_GUIDE.md](./COMPLETE_IMPORT_GUIDE.md) - Master import guide
- [SCHEMA_MAPPINGS_V2.md](./SCHEMA_MAPPINGS_V2.md) - Field mappings
- [PRE_MIGRATION_CHECKLIST_V2.md](./PRE_MIGRATION_CHECKLIST_V2.md) - Detailed checklist
- [CUSTOMER_APP_LOGIN_AND_ITEMS_GUIDE.md](../CUSTOMER_APP_LOGIN_AND_ITEMS_GUIDE.md) - Customer app setup

---

**Status**: ✅ **COMPLETE & PRODUCTION-READY**  
**Last Updated**: 2026-01-22  
**Version**: v3 (Complete All Entities)  
**Next Deployment**: Ready to execute
