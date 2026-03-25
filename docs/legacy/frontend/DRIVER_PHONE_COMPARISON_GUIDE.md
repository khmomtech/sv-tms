> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Driver Phone Number Comparison Tool

## Quick Start

Compare drivers between your database and Excel file to find missing entries:

```bash
# Basic usage (uses default localhost:3307 database)
python scripts/compare_drivers_by_phone.py /path/to/drivers.xlsx

# With custom phone column name
python scripts/compare_drivers_by_phone.py drivers.xlsx --phone-col "Phone Number"

# Export missing drivers to CSV files
python scripts/compare_drivers_by_phone.py drivers.xlsx --export results
```

## Installation

```bash
# Install required Python packages
pip install pandas openpyxl pymysql
```

## What It Does

The script:

1. ✅ Connects to your MySQL database (svlogistics_tms_db)
2. ✅ Reads all drivers from the `drivers` table
3. ✅ Reads all drivers from your Excel file
4. ✅ **Normalizes phone numbers** (removes spaces, dashes, parentheses, etc.)
5. ✅ Compares phone numbers to find:
   - Drivers in DATABASE but NOT in EXCEL
   - Drivers in EXCEL but NOT in DATABASE
   - Drivers in BOTH sources

## Phone Number Normalization

The script intelligently normalizes phone numbers before comparison:

| Original Format   | Normalized    |
| ----------------- | ------------- |
| `+855 10 123 456` | `85510123456` |
| `010-123-456`     | `010123456`   |
| `(010) 123 456`   | `010123456`   |
| `+855-10-123-456` | `85510123456` |

This ensures matches even if formatting differs between sources.

## Database Connection

### Default (Docker localhost)

```bash
Host: localhost
Port: 3307
Database: svlogistics_tms_db
User: root
Password: rootpass
```

### Custom Connection

```bash
# Using environment variables
DB_HOST=10.0.2.2 DB_PORT=3306 python scripts/compare_drivers_by_phone.py drivers.xlsx

# Or using command-line arguments
python scripts/compare_drivers_by_phone.py drivers.xlsx \
  --db-host 10.0.2.2 \
  --db-port 3306 \
  --db-user admin \
  --db-password secret
```

## Excel File Format

Your Excel file should have at least a phone number column. The script can auto-detect name columns.

### Minimum Required Columns

```
| phone        |
|--------------|
| 010123456    |
| +855 10 234  |
```

### Recommended Columns

```
| name         | phone        | license_number |
|--------------|--------------|----------------|
| John Doe     | 010123456    | ABC123        |
| Jane Smith   | +855 10 234  | XYZ789        |
```

### Custom Column Names

```bash
# If your Excel has different column names
python scripts/compare_drivers_by_phone.py drivers.xlsx \
  --phone-col "Phone Number" \
  --name-col "Driver Name"
```

## Output Report

The script generates a detailed console report:

```
================================================================================
📊 DRIVER COMPARISON REPORT
================================================================================

📈 Summary:
   Total drivers in DATABASE: 25
   Total drivers in EXCEL:    23
   Drivers in BOTH sources:   20
   Missing in EXCEL:          5
   Missing in DATABASE:       3

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
8        Another One                    +855 10 777 666      85510777666
...

✅ 20 DRIVERS IN BOTH SOURCES
   DB: John Doe                       | Excel: John Doe                       | Phone: 010123456
   DB: Jane Smith                     | Excel: Jane Smith                     | Phone: 85510234567
```

## Export to CSV

Export missing drivers to CSV files for further analysis:

```bash
python scripts/compare_drivers_by_phone.py drivers.xlsx --export results
```

This creates:

- `results_missing_in_excel.csv` - Drivers in database but not in Excel
- `results_missing_in_database.csv` - Drivers in Excel but not in database

### Missing in Excel CSV Format

```csv
id,name,phone,phone_normalized,license_number,status,is_active,created_at
12,John Doe,010123456,010123456,ABC123,ACTIVE,True,2024-01-15 10:30:00
```

### Missing in Database CSV Format

```csv
excel_row,name,phone,phone_normalized
5,New Driver,010999888,010999888
```

## Common Use Cases

### 1. Find Drivers Missing in Excel Backup

```bash
python scripts/compare_drivers_by_phone.py backup_drivers.xlsx --export missing
# Check: missing_missing_in_excel.csv for drivers that need to be added to Excel
```

### 2. Find New Drivers to Import from Excel

```bash
python scripts/compare_drivers_by_phone.py new_drivers.xlsx --export import_candidates
# Check: import_candidates_missing_in_database.csv for drivers to import
```

### 3. Verify Migration Completeness

```bash
# After migrating from old system
python scripts/compare_drivers_by_phone.py old_system_export.xlsx
# Should show 0 missing in database if migration was complete
```

### 4. Excel with Different Column Names

```bash
python scripts/compare_drivers_by_phone.py "Driver List 2024.xlsx" \
  --phone-col "Contact Number" \
  --name-col "Full Name" \
  --sheet "Sheet2"
```

## Troubleshooting

### Error: Phone column not found

```
❌ Phone column 'phone' not found in Excel.
   Available columns: ['Name', 'Contact', 'License']
```

**Solution:** Specify the correct column name:

```bash
python scripts/compare_drivers_by_phone.py drivers.xlsx --phone-col "Contact"
```

### Error: Failed to connect to database

```
❌ Failed to connect to database: (2003, "Can't connect to MySQL server")
   Connection details: root@localhost:3307/svlogistics_tms_db
```

**Solution:** Check database is running:

```bash
# Check Docker container
docker ps | grep svtms-mysql

# Test connection
mysql -h localhost -P 3307 -u root -prootpass svlogistics_tms_db -e "SELECT COUNT(*) FROM drivers;"
```

### No drivers found in Excel

```
📄 Reading drivers from Excel...
   Found 0 drivers in Excel
```

**Solution:** Check Excel file has data and correct sheet:

```bash
# Try different sheet
python scripts/compare_drivers_by_phone.py drivers.xlsx --sheet 1

# Or by sheet name
python scripts/compare_drivers_by_phone.py drivers.xlsx --sheet "Drivers"
```

## Advanced Usage

### Compare Multiple Excel Files

```bash
# Compare with current backup
python scripts/compare_drivers_by_phone.py backups/2024-02-01.xlsx --export feb_2024

# Compare with previous backup
python scripts/compare_drivers_by_phone.py backups/2024-01-01.xlsx --export jan_2024

# Analyze difference between the two CSV outputs
```

### Remote Database

```bash
# Production server
python scripts/compare_drivers_by_phone.py drivers.xlsx \
  --db-host prod-db.example.com \
  --db-port 3306 \
  --db-user readonly_user \
  --db-password <password>
```

### Automated Daily Check

```bash
#!/bin/bash
# daily_driver_check.sh

DATE=$(date +%Y%m%d)
python scripts/compare_drivers_by_phone.py \
  "/backups/drivers_${DATE}.xlsx" \
  --export "reports/comparison_${DATE}"

# Send email if differences found
if [ $? -ne 0 ]; then
  echo "Driver differences detected" | mail -s "Driver Check Alert" admin@example.com
fi
```

## Related Scripts

- `scripts/migrate_drivers.py` - Generate SQL to import drivers from Excel
- `backup_docker_mysql.sh` - Create database backup
- Test scripts in `tms-backend` for API validation

## Support

If you encounter issues:

1. Check Excel file format matches expectations
2. Verify database connection with `mysql` command
3. Check phone column contains valid data (not all empty)
4. Ensure at least one row of data exists in Excel (excluding header)

## Exit Codes

- `0` - Success (with or without differences found)
- `1` - Database connection failed
- `2` - Excel file read error or column not found
