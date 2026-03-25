> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Driver Migration - Truncate & Import Guide

## ✅ What Was Created

**Script:** `scripts/migrate_drivers_complete.py`  
**SQL File:** `driver_migration_truncate_and_import.sql` (49 KB, 475 lines)  
**Status:** Ready to execute

## 📊 Migration Summary

- **Drivers to import:** 65
- **Users to create:** 65 (one per driver)
- **Vehicle assignments:** 0 (none specified in Excel)
- **Default password:** `123456` (bcrypt hashed)

## 🔥 What This Does

### 1. TRUNCATES (Deletes) Old Data

```sql
TRUNCATE TABLE assignment_vehicle_to_driver;
DELETE FROM drivers;
DELETE FROM users WHERE id IN (SELECT user_id FROM drivers WHERE user_id IS NOT NULL);
```

### 2. Inserts New Data

For each driver:

- Creates a **user** account (username = phone, password = 123456)
- Creates a **driver** record linked to the user
- Sets default values: status=IDLE, is_active=true, rating=5.0

## 🚀 Execute the Migration

### Option 1: Via MySQL Command (Recommended)

```bash
mysql -h localhost -P 3307 -u root -prootpass svlogistics_tms_db < driver_migration_truncate_and_import.sql
```

### Option 2: Via Docker (If MySQL in container)

```bash
docker exec -i svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db < driver_migration_truncate_and_import.sql
```

### Option 3: Step-by-step (Safer)

```bash
# 1. Backup first!
./backup_docker_mysql.sh

# 2. Review the SQL
cat driver_migration_truncate_and_import.sql | less

# 3. Execute
docker exec -i svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db < driver_migration_truncate_and_import.sql
```

## ✅ Verify the Migration

```bash
# Count drivers and users
docker exec svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db -e "
SELECT 'Drivers:' as table_name, COUNT(*) as count FROM drivers
UNION ALL
SELECT 'Users:', COUNT(*) FROM users
UNION ALL
SELECT 'Vehicle Assignments:', COUNT(*) FROM assignment_vehicle_to_driver;
"

# Check a few drivers
docker exec svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db -e "
SELECT d.id, d.name, d.phone, d.zone, u.username
FROM drivers d
LEFT JOIN users u ON d.user_id = u.id
LIMIT 10;
"
```

## ⚠️ IMPORTANT WARNINGS

### ⚠️ This Will DELETE All Existing Drivers!

- All current driver records will be removed
- All user accounts for drivers will be deleted
- All vehicle assignments will be cleared

### ⚠️ Make a Backup First!

```bash
# Backup the database
./backup_docker_mysql.sh

# Or manual backup
docker exec svtms-mysql-local mysqldump -u root -prootpass svlogistics_tms_db > backup_before_migration.sql
```

## 🔧 Customize the Migration

### Generate from Different Excel File

```bash
# Use your driver_accounts.xlsx file when available
python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx --out migration.sql
```

### With Custom Columns

```bash
python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx \
  --phone-col "Phone Number" \
  --name-col "Driver Name" \
  --zone-col "Zone" \
  --out migration.sql
```

### Preview Before Generating SQL

```bash
python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx --dry-run
```

### Append Instead of Truncate

```bash
python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx \
  --skip-truncate \
  --out append_drivers.sql
```

### Custom Default Password

```bash
python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx \
  --default-password "SecurePass123" \
  --out migration.sql
```

## 📋 Excel File Format

Your Excel file should have these columns:

### Required Columns

- **phone** - Phone number (must be valid, 8+ digits)
- **name** - Full name (or use first_name + last_name)

### Optional Columns

- **username** - Login username (defaults to phone)
- **first_name** - First name (if not using name column)
- **last_name** - Last name (if not using name column)
- **license_class** - License type (A, B, C, etc.)
- **zone** - Operating zone
- **vehicle_type** - Vehicle type
- **vehicle_id** - Vehicle ID for assignment
- **is_partner** - Is partner driver (true/false/1/0)
- **partner_company** - Partner company name

### Example Excel Layout

```
| name        | phone      | license_class | zone       | vehicle_id |
|-------------|------------|---------------|------------|------------|
| KOUNG PEN   | 167964508  | A             | Phnom Penh |            |
| HEM DARRA   | 168593750  | A             | Phnom Penh | 5          |
```

## 🔄 Complete Workflow

### 1. Export Current Drivers (Backup)

```bash
python3 scripts/export_drivers_to_excel.py --output backup_before_migration.xlsx
```

### 2. Prepare Your driver_accounts.xlsx

- Update Excel with new driver data
- Ensure phone column has valid numbers
- Ensure names are correct

### 3. Preview the Migration

```bash
python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx --dry-run
```

### 4. Generate SQL

```bash
python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx --out migration.sql
```

### 5. Backup Database

```bash
./backup_docker_mysql.sh
```

### 6. Execute Migration

```bash
docker exec -i svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db < migration.sql
```

### 7. Verify

```bash
docker exec svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db -e "SELECT COUNT(*) FROM drivers;"
```

## 🛠️ Troubleshooting

### Error: "Table 'assignment_vehicle_to_driver' doesn't exist"

The table might have a different name. Check with:

```bash
docker exec svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db -e "SHOW TABLES LIKE '%assignment%';"
```

### Error: Duplicate phone numbers

Excel has duplicate phone numbers. Clean your data:

```bash
python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx --dry-run
# Check for duplicates in the preview
```

### Error: Invalid phone numbers

Phone numbers must have at least 8 digits:

```bash
# The script will skip invalid phones and show warnings
```

### Rollback Migration

If something goes wrong, restore from backup:

```bash
mysql -h localhost -P 3307 -u root -prootpass svlogistics_tms_db < backup_before_migration.sql
```

## 📞 Default Login Credentials

After migration, all drivers can login with:

- **Username:** Their phone number
- **Password:** `123456`
- **Email:** `{phone}@driver.local`

Example:

- Username: `167964508`
- Password: `123456`

## 🔐 Security Note

The default password `123456` is weak. After migration:

1. Force drivers to change password on first login
2. Or use a stronger default password:
   ```bash
   python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx \
     --default-password "TMS@2026!" \
     --out migration.sql
   ```

## 📝 Generated SQL Structure

Each driver creates:

```sql
-- 1. User account
INSERT INTO users (...) VALUES (...);
SET @user_id = LAST_INSERT_ID();

-- 2. Driver record
INSERT INTO drivers (user_id, ...) VALUES (@user_id, ...);
SET @driver_id = LAST_INSERT_ID();

-- 3. Vehicle assignment (if vehicle_id provided)
INSERT INTO assignment_vehicle_to_driver (...) VALUES (@driver_id, ...);
UPDATE drivers SET assigned_vehicle_id = ... WHERE id = @driver_id;
```

## ✅ Success Indicators

After successful migration, you should see:

- ✅ 65 drivers in database
- ✅ 65 users created
- ✅ All drivers can login with phone + password
- ✅ Frontend shows updated driver list
- ✅ Driver mobile apps can authenticate

## 🎯 Current Status

**Ready to execute:**

```bash
docker exec -i svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db < driver_migration_truncate_and_import.sql
```

**File location:**
`/Users/sotheakh/Documents/develop/sv-tms/driver_migration_truncate_and_import.sql`

⚠️ **Make sure you have a backup before executing!**
