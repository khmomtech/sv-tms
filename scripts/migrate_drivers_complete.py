#!/usr/bin/env python3
"""
Complete driver migration script that:
1. Truncates old drivers, users (for drivers), and vehicle assignments
2. Imports new driver data from Excel
3. Creates users for each driver
4. Optionally assigns vehicles to drivers

Usage:
  python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx --out migration.sql
  
  # Execute the generated SQL
  mysql -h localhost -P 3307 -u root -prootpass svlogistics_tms_db < migration.sql

Excel file should have columns:
  - phone (REQUIRED)
  - name or first_name + last_name (REQUIRED)
  - username (optional, defaults to phone)
  - license_class (optional)
  - zone (optional)
  - vehicle_type (optional)
  - vehicle_id (optional, for vehicle assignment)
  - is_partner (optional, 0/1)
  - partner_company (optional)
"""
import argparse
import pandas as pd
import uuid
import bcrypt
from datetime import datetime
import sys
import re
import os
import pymysql


def esc(s) -> str:
    """Escape single quotes for SQL."""
    if s is None or pd.isna(s):
        return ''
    return str(s).replace("'", "''")


def make_uuid() -> str:
    """Generate UUID for ID fields."""
    return str(uuid.uuid4())


def hash_password(pw: str) -> str:
    """Hash password using bcrypt."""
    return bcrypt.hashpw(pw.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')


def get_db_connection(host: str, port: int, user: str, password: str, database: str):
    """Create MySQL database connection."""
    return pymysql.connect(
        host=host,
        port=port,
        user=user,
        password=password,
        database=database,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )


def fetch_vehicle_ids(conn) -> list:
    """Fetch all vehicle IDs ordered by ID."""
    with conn.cursor() as cursor:
        cursor.execute("SELECT id FROM vehicles ORDER BY id")
        rows = cursor.fetchall()
    return [row['id'] for row in rows]


def normalize_phone(phone: str) -> str:
    """Normalize phone number (remove non-digits)."""
    if not phone or pd.isna(phone):
        return ''
    return ''.join(filter(str.isdigit, str(phone)))


def validate_phone(phone: str) -> bool:
    """Validate phone number has at least 8 digits."""
    normalized = normalize_phone(phone)
    return len(normalized) >= 8


def parse_boolean(value) -> bool:
    """Parse various boolean representations."""
    if pd.isna(value):
        return False
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        return value.lower() in ['true', 'yes', '1', 'y']
    return False


def main():
    parser = argparse.ArgumentParser(
        description='Complete driver migration with users and vehicle assignments',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate migration SQL
  python3 scripts/migrate_drivers_complete.py driver_accounts.xlsx --out migration.sql
  
  # With custom column names
  python3 scripts/migrate_drivers_complete.py drivers.xlsx \
    --phone-col "Phone Number" \
    --name-col "Driver Name" \
    --out migration.sql
  
  # Execute the migration
  mysql -h localhost -P 3307 -u root -prootpass svlogistics_tms_db < migration.sql
  
  # Or via Docker
  docker exec -i svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db < migration.sql
        """
    )
    
    parser.add_argument('excel', help='Path to Excel file with driver data')
    parser.add_argument('--out', default='driver_migration.sql', help='Output SQL file')
    parser.add_argument('--sheet', default=0, help='Sheet index or name (default: 0)')
    
    # Column mapping
    parser.add_argument('--phone-col', default='phone', help='Phone column name')
    parser.add_argument('--name-col', default='name', help='Name column (or first_name/last_name)')
    parser.add_argument('--first-name-col', default='first_name', help='First name column')
    parser.add_argument('--last-name-col', default='last_name', help='Last name column')
    parser.add_argument('--username-col', default='username', help='Username column (optional)')
    parser.add_argument('--license-col', default='license_class', help='License class column')
    parser.add_argument('--zone-col', default='zone', help='Zone column')
    parser.add_argument('--vehicle-type-col', default='vehicle_type', help='Vehicle type column')
    parser.add_argument('--vehicle-id-col', default='vehicle_id', help='Vehicle ID column for assignment')
    parser.add_argument('--is-partner-col', default='is_partner', help='Is partner column')
    parser.add_argument('--partner-company-col', default='partner_company', help='Partner company column')
    
    # Options
    parser.add_argument('--default-password', default='123456', help='Default password for all drivers')
    parser.add_argument('--skip-truncate', action='store_true', help='Skip truncate (append mode)')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be migrated without generating SQL')
    parser.add_argument('--auto-assign-vehicles', action='store_true', help='Auto-assign vehicles for drivers missing vehicle_id')
    parser.add_argument('--default-zone', default='', help='Default zone if missing')
    parser.add_argument('--default-license-class', default='', help='Default license class if missing')
    parser.add_argument('--default-vehicle-type', default='UNKNOWN', help='Default vehicle type if missing (must be valid enum)')

    # Database connection (used for auto vehicle assignment)
    parser.add_argument('--db-host', default=os.getenv('DB_HOST', 'localhost'))
    parser.add_argument('--db-port', type=int, default=int(os.getenv('DB_PORT', '3307')))
    parser.add_argument('--db-name', default=os.getenv('DB_NAME', 'svlogistics_tms_db'))
    parser.add_argument('--db-user', default=os.getenv('DB_USER', 'root'))
    parser.add_argument('--db-password', default=os.getenv('DB_PASSWORD', 'rootpass'))
    
    args = parser.parse_args()
    
    # Read Excel file
    print(f'📄 Reading Excel file: {args.excel}')
    try:
        df = pd.read_excel(args.excel, sheet_name=args.sheet, engine='openpyxl')
        print(f'   Found {len(df)} rows')
        print(f'   Columns: {list(df.columns)}')
    except Exception as e:
        print(f'❌ Failed to read Excel: {e}', file=sys.stderr)
        sys.exit(2)
    
    # Validate required columns
    if args.phone_col not in df.columns:
        print(f"❌ Phone column '{args.phone_col}' not found", file=sys.stderr)
        print(f"   Available: {list(df.columns)}", file=sys.stderr)
        sys.exit(2)
    
    # Determine name columns
    has_name_col = args.name_col in df.columns
    has_first_last = args.first_name_col in df.columns and args.last_name_col in df.columns
    
    if not has_name_col and not has_first_last:
        print(f"❌ Need either '{args.name_col}' or '{args.first_name_col}' + '{args.last_name_col}' columns", file=sys.stderr)
        sys.exit(2)
    
    # Process drivers
    print(f'\n🔄 Processing drivers...')
    now = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    
    drivers_data = []
    skipped = 0
    
    for idx, row in df.iterrows():
        phone = row.get(args.phone_col)
        
        # Validate phone
        if not validate_phone(phone):
            print(f'⚠️  Row {idx + 2}: Skipping invalid/empty phone: {phone}')
            skipped += 1
            continue
        
        phone_normalized = normalize_phone(phone)
        
        # Get name
        if has_name_col:
            name = esc(row.get(args.name_col, ''))
            first_name = name.split()[0] if name else ''
            last_name = ' '.join(name.split()[1:]) if len(name.split()) > 1 else ''
        else:
            first_name = esc(row.get(args.first_name_col, ''))
            last_name = esc(row.get(args.last_name_col, ''))
            name = f"{first_name} {last_name}".strip()
        
        if not name:
            print(f'⚠️  Row {idx + 2}: Skipping empty name')
            skipped += 1
            continue
        
        # Get other fields
        username = esc(row.get(args.username_col, phone_normalized))
        license_class = esc(row.get(args.license_col, '')) or esc(args.default_license_class)
        zone = esc(row.get(args.zone_col, '')) or esc(args.default_zone)
        vehicle_type = esc(row.get(args.vehicle_type_col, '')) or esc(args.default_vehicle_type)
        vehicle_id = row.get(args.vehicle_id_col)
        is_partner = parse_boolean(row.get(args.is_partner_col, False))
        partner_company = esc(row.get(args.partner_company_col, ''))
        
        driver = {
            'phone': esc(phone),
            'phone_normalized': phone_normalized,
            'name': name,
            'first_name': first_name,
            'last_name': last_name,
            'username': username if username else phone_normalized,
            'license_class': license_class,
            'zone': zone,
            'vehicle_type': vehicle_type,
            'vehicle_id': vehicle_id if not pd.isna(vehicle_id) else None,
            'is_partner': is_partner,
            'partner_company': partner_company,
            'excel_row': idx + 2
        }
        
        drivers_data.append(driver)

    # Auto-assign vehicles if requested
    if args.auto_assign_vehicles:
        print('\n🚚 Auto-assigning vehicles for drivers missing vehicle_id...')
        try:
            conn = get_db_connection(
                host=args.db_host,
                port=args.db_port,
                user=args.db_user,
                password=args.db_password,
                database=args.db_name
            )
            vehicle_ids = fetch_vehicle_ids(conn)
            conn.close()
        except Exception as e:
            print(f'❌ Failed to fetch vehicles: {e}', file=sys.stderr)
            sys.exit(1)

        missing_vehicle_drivers = [d for d in drivers_data if not d['vehicle_id']]
        if len(vehicle_ids) < len(missing_vehicle_drivers):
            print(f'❌ Not enough vehicles ({len(vehicle_ids)}) for drivers without vehicle_id ({len(missing_vehicle_drivers)})', file=sys.stderr)
            sys.exit(1)

        for driver, vehicle_id in zip(missing_vehicle_drivers, vehicle_ids):
            driver['vehicle_id'] = vehicle_id
        print(f'✅ Assigned vehicles to {len(missing_vehicle_drivers)} drivers')
    
    print(f'✅ Valid drivers: {len(drivers_data)}')
    print(f'⚠️  Skipped: {skipped}')
    
    if not drivers_data:
        print('❌ No valid drivers to migrate!')
        sys.exit(1)
    
    # Dry run mode
    if args.dry_run:
        print('\n📊 DRY RUN - Preview of drivers to migrate:')
        print('='*80)
        print(f"{'Row':<6} {'Name':<25} {'Phone':<15} {'Username':<15} {'Zone':<10}")
        print('-'*80)
        for driver in drivers_data[:20]:  # Show first 20
            print(f"{driver['excel_row']:<6} {driver['name'][:24]:<25} {driver['phone'][:14]:<15} {driver['username'][:14]:<15} {driver['zone'][:9]:<10}")
        if len(drivers_data) > 20:
            print(f"... and {len(drivers_data) - 20} more")
        print('\n💡 Remove --dry-run to generate SQL migration file')
        sys.exit(0)
    
    # Generate SQL
    print(f'\n💾 Generating SQL migration...')
    sql_lines = []
    
    # Header
    sql_lines.append('-- =====================================================')
    sql_lines.append('-- Driver Migration Script')
    sql_lines.append(f'-- Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
    sql_lines.append(f'-- Source: {args.excel}')
    sql_lines.append(f'-- Drivers: {len(drivers_data)}')
    sql_lines.append('-- =====================================================')
    sql_lines.append('')
    
    # Disable foreign key checks
    sql_lines.append('SET FOREIGN_KEY_CHECKS = 0;')
    sql_lines.append('')
    
    # Truncate tables (unless skip-truncate)
    if not args.skip_truncate:
        sql_lines.append('-- Truncate existing data')
        sql_lines.append('-- Store driver user IDs and phone-based usernames before deletion')
        sql_lines.append('CREATE TEMPORARY TABLE IF NOT EXISTS temp_driver_user_ids AS SELECT DISTINCT user_id FROM drivers WHERE user_id IS NOT NULL;')
        sql_lines.append('')
        sql_lines.append('-- Delete vehicle assignments')
        sql_lines.append('TRUNCATE TABLE vehicle_drivers;')
        sql_lines.append('')
        sql_lines.append('-- Delete drivers')
        sql_lines.append('DELETE FROM drivers;')
        sql_lines.append('')
        sql_lines.append('-- Delete users that were linked to drivers')
        sql_lines.append('DELETE FROM users WHERE id IN (SELECT user_id FROM temp_driver_user_ids);')
        sql_lines.append('')
        sql_lines.append('-- Also delete any users with phone-like usernames (all digits, 8-15 chars)')
        sql_lines.append("DELETE FROM users WHERE username REGEXP '^[0-9]{8,15}$';")
        sql_lines.append('')
        sql_lines.append('-- Clean up temp table')
        sql_lines.append('DROP TEMPORARY TABLE IF EXISTS temp_driver_user_ids;')
        sql_lines.append('')
    
    # Insert drivers and users
    sql_lines.append('-- Insert users and drivers')
    sql_lines.append('')
    
    pw_hash = esc(hash_password(args.default_password))
    
    for driver in drivers_data:
        # Generate user INSERT
        sql_lines.append(f"-- Driver: {driver['name']} ({driver['phone']})")
        sql_lines.append(
            f"INSERT INTO users (username, password, email, enabled, "
            f"account_non_expired, account_non_locked, credentials_non_expired) "
            f"VALUES ("
            f"'{driver['username']}', "
            f"'{pw_hash}', "
            f"'{driver['username']}@driver.local', "
            f"b'1', b'1', b'1', b'1'"
            f");"
        )
        sql_lines.append('SET @user_id = LAST_INSERT_ID();')
        sql_lines.append('')
        
        # Generate driver INSERT
        is_partner_bit = "b'1'" if driver['is_partner'] else "b'0'"
        vehicle_type_sql = f"'{driver['vehicle_type']}'" if driver['vehicle_type'] else "NULL"
        license_class_sql = f"'{driver['license_class']}'" if driver['license_class'] else "NULL"
        zone_sql = f"'{driver['zone']}'" if driver['zone'] else "NULL"
        sql_lines.append(
            f"INSERT INTO drivers ("
            f"user_id, name, first_name, last_name, phone, "
            f"license_class, zone, vehicle_type, is_partner, "
            f"is_active, status, rating, performance_score, "
            f"leaderboard_rank, on_time_percent, safety_score"
            f") VALUES ("
            f"@user_id, "
            f"'{driver['name']}', "
            f"'{driver['first_name']}', "
            f"'{driver['last_name']}', "
            f"'{driver['phone']}', "
            f"{license_class_sql}, "
            f"{zone_sql}, "
            f"{vehicle_type_sql}, "
            f"{is_partner_bit}, "
            f"b'1', 'IDLE', 5.0, 92, 0, 98, 'Excellent'"
            f");"
        )
        sql_lines.append('SET @driver_id = LAST_INSERT_ID();')
        sql_lines.append('')
        
        # Vehicle assignment if specified
        if driver['vehicle_id']:
            sql_lines.append(
                f"-- Assign vehicle {driver['vehicle_id']} to driver"
            )
            sql_lines.append(
                f"INSERT INTO vehicle_drivers ("
                f"driver_id, vehicle_id, assigned_at, assigned_by, created_at, updated_at"
                f") VALUES ("
                f"@driver_id, {int(driver['vehicle_id'])}, '{now}', 'system', '{now}', '{now}'"
                f");"
            )
            sql_lines.append(
                f"UPDATE drivers SET assigned_vehicle_id = {int(driver['vehicle_id'])} "
                f"WHERE id = @driver_id;"
            )
            sql_lines.append('')
    
    # Re-enable foreign key checks
    sql_lines.append('SET FOREIGN_KEY_CHECKS = 1;')
    sql_lines.append('')
    
    # Summary
    sql_lines.append('-- =====================================================')
    sql_lines.append(f'-- Migration complete: {len(drivers_data)} drivers')
    sql_lines.append('-- =====================================================')
    
    # Write to file
    with open(args.out, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sql_lines))
    
    print(f'✅ SQL migration generated: {args.out}')
    print(f'   Lines: {len(sql_lines)}')
    sql_content = '\n'.join(sql_lines)
    print(f'   Size: {len(sql_content)} bytes')
    
    print('\n📋 Summary:')
    print(f'   • Drivers to migrate: {len(drivers_data)}')
    print(f'   • Users to create: {len(drivers_data)}')
    vehicle_assignments = sum(1 for d in drivers_data if d['vehicle_id'])
    print(f'   • Vehicle assignments: {vehicle_assignments}')
    print(f'   • Default password: {args.default_password}')
    
    print('\n🚀 Next steps:')
    print('\n1. Review the SQL file:')
    print(f'   cat {args.out}')
    print('\n2. Execute the migration:')
    print(f'   mysql -h localhost -P 3307 -u root -prootpass svlogistics_tms_db < {args.out}')
    print('\n   Or via Docker:')
    print(f'   docker exec -i svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db < {args.out}')
    print('\n3. Verify the migration:')
    print('   docker exec svtms-mysql-local mysql -u root -prootpass svlogistics_tms_db -e "SELECT COUNT(*) FROM drivers; SELECT COUNT(*) FROM users;"')
    
    print('\n⚠️  WARNING: This will DELETE all existing drivers and their users!')
    print('   Make sure you have a backup before executing the SQL.')


if __name__ == '__main__':
    main()
