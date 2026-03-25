> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Quick Start: Driver Phone Comparison

## Install Dependencies (One-time Setup)

```bash
# Option 1: Using pip
pip3 install pandas openpyxl pymysql

# Option 2: Using virtual environment (recommended)
cd /Users/sotheakh/Documents/develop/sv-tms
source .venv/bin/activate
pip install pandas openpyxl pymysql
```

## Usage Examples

### 1. Basic Comparison

```bash
# Make sure your database is running
docker ps | grep svtms-mysql

# Run comparison with your Excel file
python3 scripts/compare_drivers_by_phone.py /path/to/your/drivers.xlsx
```

### 2. If Excel Uses Different Column Names

```bash
# Example: Your Excel has "Phone Number" instead of "phone"
python3 scripts/compare_drivers_by_phone.py drivers.xlsx \
  --phone-col "Phone Number" \
  --name-col "Driver Name"
```

### 3. Export Missing Drivers to CSV

```bash
python3 scripts/compare_drivers_by_phone.py drivers.xlsx --export results

# This creates two files:
# - results_missing_in_excel.csv (drivers in DB but not in Excel)
# - results_missing_in_database.csv (drivers in Excel but not in DB)
```

### 4. Custom Database Connection

```bash
# If your database is on different host/port
python3 scripts/compare_drivers_by_phone.py drivers.xlsx \
  --db-host 10.0.2.2 \
  --db-port 3306
```

## What You'll See

```
🔍 Starting driver comparison...
   Excel file: drivers.xlsx
   Database: root@localhost:3307/svlogistics_tms_db

📥 Fetching drivers from database...
   Found 25 drivers in database

📄 Reading drivers from Excel...
   Found 23 drivers in Excel

🔄 Comparing drivers by phone number...

================================================================================
📊 DRIVER COMPARISON REPORT
================================================================================

📈 Summary:
   Total drivers in DATABASE: 25
   Total drivers in EXCEL:    23
   Drivers in BOTH sources:   20
   Missing in EXCEL:          5  ← Drivers exist in DB but not in your Excel
   Missing in DATABASE:       3  ← Drivers in Excel but not imported to DB

❌ 5 DRIVERS IN DATABASE BUT NOT IN EXCEL:
--------------------------------------------------------------------------------
ID       Name                           Phone (DB)           Status       Active
--------------------------------------------------------------------------------
12       John Doe                       010123456            ACTIVE       True
15       Jane Smith                     +855 10 234 567      ACTIVE       True
...

⚠️  3 DRIVERS IN EXCEL BUT NOT IN DATABASE:
--------------------------------------------------------------------------------
Row      Name                           Phone (Excel)        Normalized Phone
--------------------------------------------------------------------------------
5        New Driver                     010999888            010999888
8        Another Driver                 +855 10 777 666      85510777666
...
```

## Common Excel Column Names

The script looks for these phone column names (case-sensitive):

- `phone` (default)
- `Phone Number`
- `contact`
- `mobile`

If yours is different, use `--phone-col "Your Column Name"`

## Troubleshooting

### "ModuleNotFoundError: No module named 'pymysql'"

```bash
pip3 install pymysql pandas openpyxl
```

### "Phone column 'phone' not found"

Check your Excel file and specify the correct column:

```bash
# First, see what columns are available (the error message shows them)
# Then run with correct column name
python3 scripts/compare_drivers_by_phone.py drivers.xlsx --phone-col "Contact Number"
```

### "Failed to connect to database"

```bash
# Check if Docker MySQL is running
docker ps | grep svtms-mysql

# If not running, start it
docker compose -f docker-compose.dev.yml up -d svtms-mysql
```

## Next Steps

After finding missing drivers:

### If drivers are missing in Excel:

1. Export them: `--export missing_drivers`
2. Add them to your Excel backup file

### If drivers are missing in database:

1. Export them: `--export import_candidates`
2. Use `scripts/migrate_drivers.py` to import them
3. Or manually add via the web UI

## Example Workflow

```bash
# 1. Check what's different
python3 scripts/compare_drivers_by_phone.py backup_drivers.xlsx

# 2. Export the differences
python3 scripts/compare_drivers_by_phone.py backup_drivers.xlsx --export comparison

# 3. Review the CSV files
cat comparison_missing_in_database.csv
cat comparison_missing_in_excel.csv

# 4. Import missing drivers (if needed)
python3 scripts/migrate_drivers.py comparison_missing_in_database.csv --out import.sql
mysql -h localhost -P 3307 -u root -prootpass svlogistics_tms_db < import.sql
```
