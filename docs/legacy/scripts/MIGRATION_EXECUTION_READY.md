> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🚀 Migration Execution Guide - First Deployment & Future Migrations

## 📋 Purpose

This guide prepares you for **executing** the data migration, whether it's:
- ✅ **First Deployment**: Initial production data load (from scratch)
- ✅ **Future Migrations**: Incremental updates (new data or changes)

**Current Status:** All tools ready, awaiting execution

---

## 🎯 Pre-Migration Readiness Assessment

### ✅ What You Have (Complete Package)

**CSV Import Templates** (8 files, 80+ records):
- ✅ `customers_import.csv` (10 customers)
- ✅ `customer_addresses_import.csv` (10 addresses with GPS)
- ✅ `drivers_import.csv` (10 drivers)
- ✅ `vehicles_import.csv` (10 vehicles)
- ✅ `permanent_assignments_import.csv` (10 driver-vehicle pairs)
- ✅ `items_import.csv` (10 product types with Khmer)
- ✅ `zones_import.csv` (10 delivery zones)
- ✅ `transport_orders_import.csv` (10 orders)
- ✅ `dispatches_import.csv` (10 dispatch assignments)

**SQL Migration Scripts** (5 files, 1,500+ lines):
- ✅ `migration_customers.sql` - Customers + addresses
- ✅ `migration_import_v2.sql` - Drivers + vehicles + assignments
- ✅ `migration_items_zones.sql` - Items + zones
- ✅ `migration_orders.sql` - Transport orders
- ✅ `migration_dispatches.sql` - Dispatches
- ✅ `migration_complete_v3.sql` - All-in-one comprehensive script

**Export/Backup Tools** (2 scripts):
- ✅ `export_customers.sh` - Export customers to CSV
- ✅ `export_data.sh` - Export all entities

**Documentation** (8 guides, 4,500+ lines):
- ✅ Quick start, deployment guide, troubleshooting, reference docs

---

## 🔍 Pre-Flight Checklist

### Infrastructure Ready?

```bash
# 1. Check MySQL is running
mysql -u root -p -e "SELECT VERSION();"
# Expected: MySQL 8.0.44+

# 2. Check database exists
mysql -u root -p -e "SHOW DATABASES LIKE 'svlogistics_tms';"
# Expected: svlogistics_tms

# 3. Check tables exist
mysql -u root -p svlogistics_tms -e "SHOW TABLES;"
# Expected: 80+ tables including customers, drivers, vehicles, etc.

# 4. Check secure_file_priv (required for LOAD DATA)
mysql -u root -p -e "SHOW VARIABLES LIKE 'secure_file_priv';"
# Expected: /var/lib/mysql-files/ or /tmp/ or empty (NULL)

# 5. Check disk space
df -h /var/lib/mysql
# Recommended: 5GB+ free

# 6. Check backup directory
ls -lah /Users/sotheakh/Documents/develop/sv-tms/backups/
# Should exist, or create: mkdir -p backups
```

**✅ All checks pass?** → Proceed to next section  
**❌ Any failures?** → Fix issues before continuing

---

## 📦 First Deployment Migration

### Scenario 1: Fresh Database (No Existing Data)

**Use Case:** First production deployment, empty database

**Execution Steps:**

#### Step 1: Backup Current State (Safety Net)

```bash
cd /Users/sotheakh/Documents/develop/sv-tms

# Backup empty schema
mysqldump -u root -p svlogistics_tms > backups/pre-migration-schema-$(date +%Y%m%d_%H%M%S).sql

# Record current state
mysql -u root -p svlogistics_tms -e "
SELECT 
  (SELECT COUNT(*) FROM customers) as customers,
  (SELECT COUNT(*) FROM customer_addresses) as addresses,
  (SELECT COUNT(*) FROM drivers) as drivers,
  (SELECT COUNT(*) FROM vehicles) as vehicles,
  (SELECT COUNT(*) FROM items) as items,
  (SELECT COUNT(*) FROM zones) as zones,
  (SELECT COUNT(*) FROM transport_orders) as orders,
  (SELECT COUNT(*) FROM dispatches) as dispatches;
" > backups/pre-migration-counts.txt

cat backups/pre-migration-counts.txt
# Expected: All zeros (empty database)
```

#### Step 2: Copy CSV Files to Import Location

```bash
# Check MySQL secure_file_priv setting
SECURE_DIR=$(mysql -u root -p -N -B -e "SELECT @@secure_file_priv;")
echo "MySQL secure_file_priv: $SECURE_DIR"

# If empty (NULL), use /tmp/
if [ -z "$SECURE_DIR" ] || [ "$SECURE_DIR" == "NULL" ]; then
  IMPORT_DIR="/tmp"
else
  IMPORT_DIR="$SECURE_DIR"
fi

echo "Using import directory: $IMPORT_DIR"

# Copy all CSV files
cp data/import/customers_import.csv "$IMPORT_DIR/"
cp data/import/customer_addresses_import.csv "$IMPORT_DIR/"
cp data/import/drivers_import.csv "$IMPORT_DIR/"
cp data/import/vehicles_import.csv "$IMPORT_DIR/"
cp data/import/permanent_assignments_import.csv "$IMPORT_DIR/"
cp data/import/items_import.csv "$IMPORT_DIR/"
cp data/import/zones_import.csv "$IMPORT_DIR/"
cp data/import/transport_orders_import.csv "$IMPORT_DIR/"
cp data/import/dispatches_import.csv "$IMPORT_DIR/"

# Verify copies
ls -lh "$IMPORT_DIR"/*.csv
```

#### Step 3: Validate CSV Files

```bash
# Check for format issues (common problems)
cd /Users/sotheakh/Documents/develop/sv-tms

# 1. Check for BOM (Byte Order Mark) - causes import errors
file data/import/*.csv | grep -i "BOM"
# Expected: No output (no BOM found)

# 2. Check line endings (must be Unix LF, not Windows CRLF)
file data/import/*.csv | grep -E "(CRLF|CR)"
# Expected: No output (all files are LF)

# 3. Check for duplicate phone numbers (drivers)
awk -F',' 'NR>1 {print $3}' data/import/drivers_import.csv | sort | uniq -d
# Expected: No output (no duplicates)

# 4. Check for duplicate customer codes
awk -F',' 'NR>1 {print $1}' data/import/customers_import.csv | sort | uniq -d
# Expected: No output (no duplicates)

# 5. Check for duplicate license plates
awk -F',' 'NR>1 {print $1}' data/import/vehicles_import.csv | sort | uniq -d
# Expected: No output (no duplicates)

# 6. Validate date formats (ISO 8601: YYYY-MM-DD)
grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}" data/import/drivers_import.csv | head -3
# Expected: All dates in YYYY-MM-DD format
```

**✅ All validations pass?** → Continue  
**❌ Any errors?** → Fix CSV files and re-validate

#### Step 4: Execute Migration Scripts (Sequential Order)

**CRITICAL:** Run scripts in this exact order (FK dependencies):

```bash
cd /Users/sotheakh/Documents/develop/sv-tms

# Script 1: Customers (no dependencies)
echo "=== Running migration_customers.sql ==="
mysql -u root -p svlogistics_tms < data/import/migration_customers.sql
# Expected: 10 customers, 10 addresses imported

# Verify Script 1
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as customer_count FROM customers;"
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as address_count FROM customer_addresses;"
# Expected: 10 customers, 10 addresses

# Script 2: Drivers + Vehicles + Assignments (depends on customers for vehicle owner FK)
echo "=== Running migration_import_v2.sql ==="
mysql -u root -p svlogistics_tms < data/import/migration_import_v2.sql
# Expected: 10 drivers, 10 vehicles, 10 assignments imported

# Verify Script 2
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as driver_count FROM drivers;"
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as vehicle_count FROM vehicles;"
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as assignment_count FROM permanent_assignments;"
# Expected: 10 drivers, 10 vehicles, 10 assignments

# Script 3: Items + Zones (no dependencies)
echo "=== Running migration_items_zones.sql ==="
mysql -u root -p svlogistics_tms < data/import/migration_items_zones.sql
# Expected: 10 items, 10 zones imported

# Verify Script 3
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as item_count FROM items;"
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as zone_count FROM zones;"
# Expected: 10 items, 10 zones

# Script 4: Orders (depends on customers)
echo "=== Running migration_orders.sql ==="
mysql -u root -p svlogistics_tms < data/import/migration_orders.sql
# Expected: 10 orders imported

# Verify Script 4
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as order_count FROM transport_orders;"
# Expected: 10 orders

# Script 5: Dispatches (depends on orders, drivers, vehicles)
echo "=== Running migration_dispatches.sql ==="
mysql -u root -p svlogistics_tms < data/import/migration_dispatches.sql
# Expected: 10 dispatches imported

# Verify Script 5
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as dispatch_count FROM dispatches;"
# Expected: 10 dispatches
```

**After each script:** Check console output for errors or warnings

#### Step 5: Post-Migration Validation

```bash
# Comprehensive integrity check
mysql -u root -p svlogistics_tms << 'EOF'
-- ===========================
-- Post-Migration Validation
-- ===========================

SELECT '=== Record Counts ===' as '';
SELECT 
  (SELECT COUNT(*) FROM customers) as customers,
  (SELECT COUNT(*) FROM customer_addresses) as addresses,
  (SELECT COUNT(*) FROM drivers) as drivers,
  (SELECT COUNT(*) FROM vehicles) as vehicles,
  (SELECT COUNT(*) FROM permanent_assignments) as assignments,
  (SELECT COUNT(*) FROM items) as items,
  (SELECT COUNT(*) FROM zones) as zones,
  (SELECT COUNT(*) FROM transport_orders) as orders,
  (SELECT COUNT(*) FROM dispatches) as dispatches;

SELECT '=== FK Integrity Checks ===' as '';

-- Orders without customers (should be 0)
SELECT 'Orphaned Orders:' as check_type, COUNT(*) as count 
FROM transport_orders o 
LEFT JOIN customers c ON o.customer_id = c.id 
WHERE c.id IS NULL;

-- Dispatches without orders (should be 0)
SELECT 'Orphaned Dispatches (no order):' as check_type, COUNT(*) as count 
FROM dispatches d 
LEFT JOIN transport_orders o ON d.order_id = o.id 
WHERE o.id IS NULL;

-- Dispatches without drivers (should be 0)
SELECT 'Orphaned Dispatches (no driver):' as check_type, COUNT(*) as count 
FROM dispatches d 
LEFT JOIN drivers dr ON d.driver_id = dr.id 
WHERE dr.id IS NULL;

-- Dispatches without vehicles (should be 0)
SELECT 'Orphaned Dispatches (no vehicle):' as check_type, COUNT(*) as count 
FROM dispatches d 
LEFT JOIN vehicles v ON d.vehicle_id = v.id 
WHERE v.id IS NULL;

-- Assignments without drivers (should be 0)
SELECT 'Orphaned Assignments (no driver):' as check_type, COUNT(*) as count 
FROM permanent_assignments pa 
LEFT JOIN drivers d ON pa.driver_id = d.id 
WHERE d.id IS NULL;

-- Assignments without vehicles (should be 0)
SELECT 'Orphaned Assignments (no vehicle):' as check_type, COUNT(*) as count 
FROM permanent_assignments pa 
LEFT JOIN vehicles v ON pa.vehicle_id = v.id 
WHERE v.id IS NULL;

SELECT '=== Sample Data Verification ===' as '';

-- Sample customers
SELECT 'Sample Customers:' as '', customer_code, customer_name, email, phone 
FROM customers LIMIT 3;

-- Sample drivers
SELECT 'Sample Drivers:' as '', CONCAT(first_name, ' ', last_name) as name, phone, license_class, zone 
FROM drivers LIMIT 3;

-- Sample orders
SELECT 'Sample Orders:' as '', order_code, customer_id, status, priority 
FROM transport_orders LIMIT 3;

-- Sample dispatches
SELECT 'Sample Dispatches:' as '', dispatch_code, driver_id, vehicle_id, order_id, status 
FROM dispatches LIMIT 3;

EOF
```

**Expected Results:**
- ✅ All counts: 10 each (customers, addresses, drivers, vehicles, assignments, items, zones, orders, dispatches)
- ✅ All orphaned record checks: 0 (no FK violations)
- ✅ Sample data displays correctly

**❌ If any orphaned records found:**
```bash
# Investigate which records are orphaned
mysql -u root -p svlogistics_tms -e "
SELECT o.order_code, o.customer_id, c.id as actual_customer_id 
FROM transport_orders o 
LEFT JOIN customers c ON o.customer_id = c.id 
WHERE c.id IS NULL;
"

# Fix: Either update FK or delete orphaned records
# (See troubleshooting section below)
```

#### Step 6: Backup Successful Migration

```bash
cd /Users/sotheakh/Documents/develop/sv-tms

# Full backup after successful migration
mysqldump -u root -p svlogistics_tms > backups/post-migration-success-$(date +%Y%m%d_%H%M%S).sql

# Export as CSV for reference
bash data/import/export_data.sh

# Record final state
mysql -u root -p svlogistics_tms -e "
SELECT 
  (SELECT COUNT(*) FROM customers) as customers,
  (SELECT COUNT(*) FROM customer_addresses) as addresses,
  (SELECT COUNT(*) FROM drivers) as drivers,
  (SELECT COUNT(*) FROM vehicles) as vehicles,
  (SELECT COUNT(*) FROM items) as items,
  (SELECT COUNT(*) FROM zones) as zones,
  (SELECT COUNT(*) FROM transport_orders) as orders,
  (SELECT COUNT(*) FROM dispatches) as dispatches;
" > backups/post-migration-counts-$(date +%Y%m%d_%H%M%S).txt
```

---

## 🔄 Future Incremental Migrations

### Scenario 2: Adding New Data (Database Already Has Records)

**Use Case:** Production is live, need to add new customers/drivers/orders

**Strategy:** Incremental import (avoid duplicates)

#### Option A: Manual Addition via Admin UI

**Best for:** Small amounts (1-10 records)

1. Open Admin UI: `http://localhost:4200`
2. Navigate to entity (Customers, Drivers, etc.)
3. Click **+ New**
4. Fill form and submit
5. Repeat as needed

**Pros:** No CSV needed, immediate validation  
**Cons:** Slow for bulk (>10 records)

#### Option B: CSV Import with Duplicate Detection

**Best for:** Bulk additions (10+ records)

**Step 1: Prepare New CSV**

```bash
cd /Users/sotheakh/Documents/develop/sv-tms

# Example: Add 5 new customers
cat > data/import/customers_new_batch_2.csv << 'EOF'
customer_code,customer_name,type,email,phone,address,status,credit_limit,payment_terms,currency
NEW_CUST_001,New Company Ltd,COMPANY,newco@example.com,+855-99-888-7777,999 New St Phnom Penh,ACTIVE,50000.00,NET_30,USD
NEW_CUST_002,Fresh Trader,INDIVIDUAL,fresh@example.com,+855-99-777-6666,888 Fresh Ave,ACTIVE,25000.00,NET_15,USD
NEW_CUST_003,Big Shipper Inc,COMPANY,bigship@example.com,+855-99-666-5555,777 Big Blvd,ACTIVE,100000.00,NET_60,USD
NEW_CUST_004,Quick Delivery,COMPANY,quick@example.com,+855-99-555-4444,666 Quick Rd,ACTIVE,30000.00,DUE_ON_RECEIPT,USD
NEW_CUST_005,Test Customer Five,INDIVIDUAL,test5@example.com,+855-99-444-3333,555 Test Lane,ACTIVE,15000.00,NET_30,USD
EOF
```

**Step 2: Detect Duplicates BEFORE Import**

```bash
# Check if customer codes already exist
mysql -u root -p svlogistics_tms << 'EOF'
-- List customer codes from CSV that already exist
SELECT 'Duplicate customer_code:' as issue, customer_code 
FROM customers 
WHERE customer_code IN ('NEW_CUST_001','NEW_CUST_002','NEW_CUST_003','NEW_CUST_004','NEW_CUST_005');

-- List phone numbers from CSV that already exist
-- (Add actual phone numbers from your CSV)
EOF

# Expected: No results (all codes are new)
```

**Step 3: Import New Batch**

```bash
# Copy new CSV to import location
cp data/import/customers_new_batch_2.csv /tmp/

# Create incremental migration script
cat > data/import/migration_customers_batch_2.sql << 'EOF'
-- ===========================
-- Incremental Customer Import
-- Batch 2 (NEW_CUST_001 to 005)
-- ===========================

USE svlogistics_tms;

-- Backup current count
SELECT 'Before import:' as status, COUNT(*) as customer_count FROM customers;

-- Import new customers (IGNORE duplicates)
LOAD DATA LOCAL INFILE '/tmp/customers_new_batch_2.csv'
IGNORE INTO TABLE customers
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_code, customer_name, type, email, phone, address, status, credit_limit, payment_terms, currency)
SET 
  created_at = NOW(),
  updated_at = NOW(),
  created_by = 'SYSTEM',
  updated_by = 'SYSTEM';

-- Verify import
SELECT 'After import:' as status, COUNT(*) as customer_count FROM customers;

-- Show newly imported customers
SELECT customer_code, customer_name, email, phone, created_at 
FROM customers 
WHERE customer_code IN ('NEW_CUST_001','NEW_CUST_002','NEW_CUST_003','NEW_CUST_004','NEW_CUST_005');
EOF

# Execute import
mysql -u root -p svlogistics_tms < data/import/migration_customers_batch_2.sql
```

**Step 4: Verify Incremental Import**

```bash
# Check total count increased by expected amount
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) as total_customers FROM customers;"
# Expected: Previous count + 5

# Verify new records exist
mysql -u root -p svlogistics_tms -e "
SELECT customer_code, customer_name, created_at 
FROM customers 
WHERE customer_code LIKE 'NEW_CUST_%' 
ORDER BY created_at DESC;
"
# Expected: 5 new customers with recent created_at
```

---

## 🔧 Troubleshooting Common Issues

### Issue 1: "ERROR 1290: secure_file_priv restriction"

**Symptom:**
```
ERROR 1290 (HY000): The MySQL server is running with the --secure-file-priv option 
so it cannot execute this statement
```

**Fix:**
```bash
# Option A: Move CSV to allowed directory
SECURE_DIR=$(mysql -u root -p -N -B -e "SELECT @@secure_file_priv;")
cp data/import/*.csv "$SECURE_DIR/"

# Option B: Disable secure_file_priv (development only)
# Edit /etc/my.cnf or /etc/mysql/my.cnf
[mysqld]
secure_file_priv = ""

# Restart MySQL
sudo systemctl restart mysql
```

---

### Issue 2: "Duplicate entry" errors

**Symptom:**
```
ERROR 1062 (23000): Duplicate entry '+855-97-123-4567' for key 'drivers.phone'
```

**Fix:**
```bash
# Find existing duplicate
mysql -u root -p svlogistics_tms -e "
SELECT id, first_name, last_name, phone 
FROM drivers 
WHERE phone = '+855-97-123-4567';
"

# Option A: Update CSV to use unique phone
# Edit data/import/drivers_import.csv, change phone number

# Option B: Delete existing record (if test data)
mysql -u root -p svlogistics_tms -e "
DELETE FROM drivers WHERE phone = '+855-97-123-4567';
"

# Option C: Use IGNORE keyword in LOAD DATA (skip duplicates)
# Already implemented in migration scripts
```

---

### Issue 3: FK constraint violation (orphaned records)

**Symptom:**
```
ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
```

**Fix:**
```bash
# Example: Orders with non-existent customer_id
# Find the problem
mysql -u root -p svlogistics_tms -e "
SELECT o.order_code, o.customer_id, c.id as actual_id 
FROM transport_orders o 
LEFT JOIN customers c ON o.customer_id = c.id 
WHERE c.id IS NULL;
"

# Fix Option A: Import missing parent first
# Ensure customers are imported before orders

# Fix Option B: Update FK in CSV to valid ID
# Edit data/import/transport_orders_import.csv
# Change customer_code to match existing customer

# Fix Option C: Delete orphaned child records
mysql -u root -p svlogistics_tms -e "
DELETE o FROM transport_orders o 
LEFT JOIN customers c ON o.customer_id = c.id 
WHERE c.id IS NULL;
"
```

---

### Issue 4: Date format errors

**Symptom:**
```
Incorrect date value: '31-12-2026' for column 'license_expiry'
```

**Fix:**
```bash
# MySQL expects: YYYY-MM-DD
# Not: DD-MM-YYYY or MM/DD/YYYY

# Fix in CSV file
sed -i 's/\([0-9]\{2\}\)-\([0-9]\{2\}\)-\([0-9]\{4\}\)/\3-\2-\1/g' data/import/drivers_import.csv

# Or use Excel/LibreOffice to reformat dates to YYYY-MM-DD
```

---

## 🔙 Rollback Procedures

### Rollback Entire Migration (Fresh Start)

```bash
cd /Users/sotheakh/Documents/develop/sv-tms

# 1. Stop backend/frontend (no active connections)
docker compose -f docker-compose.dev.yml down

# 2. Find backup file
ls -lt backups/ | head -10

# 3. Restore from pre-migration backup
mysql -u root -p svlogistics_tms < backups/pre-migration-schema-YYYYMMDD_HHMMSS.sql

# 4. Verify rollback
mysql -u root -p svlogistics_tms -e "
SELECT 
  (SELECT COUNT(*) FROM customers) as customers,
  (SELECT COUNT(*) FROM drivers) as drivers,
  (SELECT COUNT(*) FROM vehicles) as vehicles;
"
# Expected: Previous counts (before migration)

# 5. Restart services
docker compose -f docker-compose.dev.yml up -d
```

---

### Rollback Specific Entity (Partial)

```bash
# Example: Rollback only customers (keep drivers/vehicles)

# 1. Backup current state first
mysqldump -u root -p svlogistics_tms customers customer_addresses > backups/before-customer-rollback.sql

# 2. Delete imported customers
mysql -u root -p svlogistics_tms << 'EOF'
-- Delete customers imported from CSV (by customer_code pattern)
DELETE FROM customers WHERE customer_code LIKE 'CUST%';

-- Or delete by date (if you know import date)
DELETE FROM customers WHERE DATE(created_at) = '2026-01-22';
EOF

# 3. Verify
mysql -u root -p svlogistics_tms -e "SELECT COUNT(*) FROM customers;"
# Expected: Reduced count
```

---

## 📊 Migration Status Tracking

### Create Migration Log Table

```sql
USE svlogistics_tms;

CREATE TABLE IF NOT EXISTS migration_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  migration_name VARCHAR(255) NOT NULL,
  migration_type ENUM('FIRST_DEPLOYMENT', 'INCREMENTAL', 'ROLLBACK') NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  records_before INT DEFAULT 0,
  records_after INT DEFAULT 0,
  records_imported INT DEFAULT 0,
  status ENUM('STARTED', 'COMPLETED', 'FAILED', 'ROLLED_BACK') NOT NULL,
  error_message TEXT,
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  executed_by VARCHAR(100) NOT NULL,
  notes TEXT,
  INDEX idx_migration_name (migration_name),
  INDEX idx_status (status),
  INDEX idx_started_at (started_at)
);
```

### Log Each Migration

```sql
-- Example: Log customer import
INSERT INTO migration_log (
  migration_name, 
  migration_type, 
  entity_type, 
  records_before, 
  records_after, 
  records_imported, 
  status, 
  executed_by, 
  notes
) VALUES (
  'migration_customers_batch_1',
  'FIRST_DEPLOYMENT',
  'customers',
  0,
  10,
  10,
  'COMPLETED',
  'admin',
  'Initial customer import from customers_import.csv'
);

-- View migration history
SELECT * FROM migration_log ORDER BY started_at DESC LIMIT 10;
```

---

## ✅ Post-Migration Testing

After successful migration, test each component:

### Backend API Testing

```bash
# 1. Start backend
cd tms-backend
./mvnw spring-boot:run

# 2. Test customer endpoint
curl http://localhost:8080/api/admin/customers \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
# Expected: List of 10 customers

# 3. Test driver endpoint
curl http://localhost:8080/api/admin/drivers \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
# Expected: List of 10 drivers

# 4. Test orders endpoint
curl http://localhost:8080/api/admin/transport-orders \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
# Expected: List of 10 orders
```

### Admin UI Testing

```bash
# 1. Start frontend
cd tms-frontend
npm start

# 2. Open browser: http://localhost:4200
# 3. Login with admin credentials
# 4. Navigate to each section:
#    - Customers → Should see 10 customers
#    - Fleet → Drivers → Should see 10 drivers
#    - Fleet → Vehicles → Should see 10 vehicles
#    - Operations → Orders → Should see 10 orders
#    - Operations → Dispatches → Should see 10 dispatches
```

### Driver App Testing

```bash
# 1. Create driver login account (see DRIVER_APP_LOGIN_AND_SETUP_GUIDE.md)
# 2. Launch driver app
cd tms_driver_app
flutter run --flavor dev

# 3. Login with test driver credentials
# 4. Verify dashboard loads
# 5. Check assigned deliveries appear
```

### Customer App Testing

```bash
# 1. Create customer login account (see CUSTOMER_APP_LOGIN_AND_ITEMS_GUIDE.md)
# 2. Launch customer app
cd tms_customer_app
flutter run

# 3. Login with test customer credentials
# 4. Verify orders appear
# 5. Check tracking works
```

---

## 📈 Migration Performance Metrics

Track migration performance:

```sql
-- Check import speed
SELECT 
  entity_type,
  records_imported,
  TIMESTAMPDIFF(SECOND, started_at, completed_at) as duration_seconds,
  ROUND(records_imported / TIMESTAMPDIFF(SECOND, started_at, completed_at), 2) as records_per_second
FROM migration_log
WHERE status = 'COMPLETED'
ORDER BY started_at DESC;
```

**Expected Performance:**
- Customers: ~100-500 records/sec
- Drivers: ~100-500 records/sec
- Orders: ~50-200 records/sec (FK lookups)
- Dispatches: ~50-200 records/sec (multiple FK lookups)

**Slow imports?** Check:
- Database indexes exist
- `innodb_buffer_pool_size` is adequate (recommended: 1-2GB)
- Network latency (if remote DB)

---

## 🎓 Migration Best Practices

### DO:
✅ **Always backup before migration** (pre-migration snapshot)  
✅ **Validate CSV files first** (duplicates, format, dates)  
✅ **Run scripts in correct order** (respect FK dependencies)  
✅ **Verify after each script** (check counts, sample data)  
✅ **Log all migrations** (use migration_log table)  
✅ **Test on staging first** (never test on production)  
✅ **Use transactions** (already in scripts with BEGIN/COMMIT)  
✅ **Keep export scripts** (for future backups)

### DON'T:
❌ **Skip backups** (no safety net)  
❌ **Run scripts out of order** (FK violations)  
❌ **Import without validation** (garbage in, garbage out)  
❌ **Ignore error messages** (fix issues immediately)  
❌ **Mix environments** (dev data in prod)  
❌ **Delete backups too soon** (keep 30+ days)  
❌ **Run migrations during peak hours** (use maintenance window)

---

## 🚦 Go/No-Go Decision Checklist

**Before executing migration, answer YES to all:**

- [ ] **Infrastructure**
  - [ ] MySQL 8+ running and accessible
  - [ ] Database `svlogistics_tms` exists
  - [ ] All tables exist (80+)
  - [ ] Disk space >5GB free
  - [ ] Backup directory exists

- [ ] **Data Preparation**
  - [ ] All CSV files validated (no duplicates)
  - [ ] CSV files copied to import location
  - [ ] Date formats verified (YYYY-MM-DD)
  - [ ] No BOM or CRLF issues

- [ ] **Safety**
  - [ ] Pre-migration backup completed
  - [ ] Current record counts documented
  - [ ] Rollback procedure tested
  - [ ] No active users on system

- [ ] **Testing**
  - [ ] Migration tested on dev/staging
  - [ ] Post-migration verification queries ready
  - [ ] Admin UI accessible
  - [ ] Backend API running

- [ ] **Execution**
  - [ ] Migration window scheduled (off-peak)
  - [ ] Team notified of maintenance
  - [ ] Monitoring in place
  - [ ] Rollback plan documented

**All YES?** → ✅ **GO for migration**  
**Any NO?** → ❌ **NO-GO - fix issues first**

---

## 📞 Support & Resources

**Documentation:**
- Quick start: [DATA_MIGRATION_QUICK_REFERENCE.md](data/import/DATA_MIGRATION_QUICK_REFERENCE.md)
- Full guide: [FIRST_DEPLOYMENT_COMPLETE_GUIDE.md](data/import/FIRST_DEPLOYMENT_COMPLETE_GUIDE.md)
- Troubleshooting: [COMPLETE_IMPORT_GUIDE.md](data/import/COMPLETE_IMPORT_GUIDE.md)
- Status report: [DEPLOYMENT_STATUS_REPORT.md](data/import/DEPLOYMENT_STATUS_REPORT.md)

**Quick Commands:**
```bash
# Check migration status
mysql -u root -p svlogistics_tms -e "SELECT * FROM migration_log ORDER BY started_at DESC LIMIT 5;"

# Check all record counts
mysql -u root -p svlogistics_tms -e "
SELECT 
  (SELECT COUNT(*) FROM customers) as customers,
  (SELECT COUNT(*) FROM drivers) as drivers,
  (SELECT COUNT(*) FROM vehicles) as vehicles,
  (SELECT COUNT(*) FROM items) as items,
  (SELECT COUNT(*) FROM zones) as zones,
  (SELECT COUNT(*) FROM transport_orders) as orders,
  (SELECT COUNT(*) FROM dispatches) as dispatches;
"

# List all backups
ls -lth backups/ | head -10

# Check disk space
df -h /var/lib/mysql
```

---

## 🎯 Quick Decision Tree

```
┌─────────────────────────────┐
│ Do you have existing data?  │
└──────────┬─────────┬────────┘
           │         │
          YES       NO
           │         │
           ▼         ▼
┌──────────────┐  ┌──────────────────┐
│ Incremental  │  │ First Deployment │
│ Migration    │  │                  │
│ (Option B)   │  │ Follow:          │
│              │  │ Scenario 1       │
│ Follow:      │  │ Steps 1-6        │
│ Scenario 2   │  │                  │
│              │  │ Use:             │
│ Use:         │  │ migration_*sql   │
│ CSV batches  │  │ All-in-one       │
│ with IGNORE  │  │                  │
└──────────────┘  └──────────────────┘
```

---

**Generated:** 2026-01-22  
**Version:** 1.0  
**Status:** ✅ Production Ready

**You are ready to migrate!** 🚀
