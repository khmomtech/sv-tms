#!/usr/bin/env python3
"""
Compare drivers between database and Excel file by phone number.
Identifies drivers that exist in one source but not the other.

Usage:
  python scripts/compare_drivers_by_phone.py /path/to/drivers.xlsx

Requirements:
  pip install pandas openpyxl pymysql

Database connection is read from environment variables or defaults to local Docker setup:
  - DB_HOST (default: localhost)
  - DB_PORT (default: 3307)
  - DB_NAME (default: svlogistics_tms_db)
  - DB_USER (default: root)
  - DB_PASSWORD (default: rootpass)
"""
import argparse
import pandas as pd
import pymysql
import os
import sys
from typing import Set, List, Dict


def normalize_phone(phone: str) -> str:
    """
    Normalize phone number by removing all non-digit characters.
    Returns only digits for comparison.
    
    Examples:
      +855 10 123 456 -> 85510123456
      010-123-456 -> 010123456
      (010) 123 456 -> 010123456
    """
    if not phone or pd.isna(phone):
        return ''
    return ''.join(filter(str.isdigit, str(phone)))


def get_db_connection(host: str, port: int, user: str, password: str, database: str):
    """Create MySQL database connection."""
    try:
        conn = pymysql.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        return conn
    except Exception as e:
        print(f'❌ Failed to connect to database: {e}', file=sys.stderr)
        print(f'   Connection details: {user}@{host}:{port}/{database}', file=sys.stderr)
        sys.exit(1)


def fetch_drivers_from_db(conn) -> Dict[str, Dict]:
    """
    Fetch all drivers from database with their phone numbers.
    Returns dict with normalized phone as key and driver data as value.
    """
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT 
                id,
                first_name,
                last_name,
                name,
                phone,
                license_number,
                status,
                is_active,
                created_at
            FROM drivers
            ORDER BY id
        """)
        rows = cursor.fetchall()
    
    drivers = {}
    for row in rows:
        phone_raw = row.get('phone', '')
        phone_normalized = normalize_phone(phone_raw)
        
        if phone_normalized:
            drivers[phone_normalized] = {
                'id': row.get('id'),
                'name': row.get('name') or f"{row.get('first_name', '')} {row.get('last_name', '')}".strip(),
                'phone_raw': phone_raw,
                'phone_normalized': phone_normalized,
                'license_number': row.get('license_number'),
                'status': row.get('status'),
                'is_active': row.get('is_active'),
                'created_at': row.get('created_at'),
                'source': 'database'
            }
    
    return drivers


def read_drivers_from_excel(excel_path: str, phone_col: str, name_col: str = None, sheet: int = 0) -> Dict[str, Dict]:
    """
    Read drivers from Excel file.
    Returns dict with normalized phone as key and driver data as value.
    """
    try:
        df = pd.read_excel(excel_path, sheet_name=sheet, engine='openpyxl')
    except Exception as e:
        print(f'❌ Failed to read Excel file: {e}', file=sys.stderr)
        sys.exit(2)
    
    # Check if phone column exists
    if phone_col not in df.columns:
        print(f"❌ Phone column '{phone_col}' not found in Excel.", file=sys.stderr)
        print(f"   Available columns: {list(df.columns)}", file=sys.stderr)
        sys.exit(2)
    
    # Auto-detect name column if not specified
    if not name_col:
        name_candidates = ['name', 'Name', 'driver_name', 'DriverName', 'full_name']
        for candidate in name_candidates:
            if candidate in df.columns:
                name_col = candidate
                print(f"ℹ️  Auto-detected name column: '{name_col}'")
                break
    
    drivers = {}
    for idx, row in df.iterrows():
        phone_raw = row.get(phone_col, '')
        phone_normalized = normalize_phone(phone_raw)
        
        if phone_normalized:
            name = row.get(name_col, '') if name_col else f'Row {idx + 2}'
            drivers[phone_normalized] = {
                'excel_row': idx + 2,  # Excel row number (header is row 1)
                'name': str(name) if pd.notna(name) else '',
                'phone_raw': str(phone_raw) if pd.notna(phone_raw) else '',
                'phone_normalized': phone_normalized,
                'source': 'excel'
            }
    
    return drivers


def compare_drivers(db_drivers: Dict[str, Dict], excel_drivers: Dict[str, Dict]) -> Dict:
    """
    Compare drivers from database and Excel.
    Returns comparison results with missing drivers from each source.
    """
    db_phones = set(db_drivers.keys())
    excel_phones = set(excel_drivers.keys())
    
    # Drivers in database but not in Excel
    missing_in_excel = db_phones - excel_phones
    
    # Drivers in Excel but not in database
    missing_in_db = excel_phones - db_phones
    
    # Drivers in both sources
    in_both = db_phones & excel_phones
    
    return {
        'missing_in_excel': sorted(missing_in_excel),
        'missing_in_db': sorted(missing_in_db),
        'in_both': sorted(in_both),
        'total_db': len(db_phones),
        'total_excel': len(excel_phones),
    }


def print_comparison_report(comparison: Dict, db_drivers: Dict, excel_drivers: Dict):
    """Print detailed comparison report."""
    
    print("\n" + "="*80)
    print("📊 DRIVER COMPARISON REPORT")
    print("="*80)
    
    print(f"\n📈 Summary:")
    print(f"   Total drivers in DATABASE: {comparison['total_db']}")
    print(f"   Total drivers in EXCEL:    {comparison['total_excel']}")
    print(f"   Drivers in BOTH sources:   {len(comparison['in_both'])}")
    print(f"   Missing in EXCEL:          {len(comparison['missing_in_excel'])}")
    print(f"   Missing in DATABASE:       {len(comparison['missing_in_db'])}")
    
    # Drivers in database but not in Excel
    if comparison['missing_in_excel']:
        print(f"\n❌ {len(comparison['missing_in_excel'])} DRIVERS IN DATABASE BUT NOT IN EXCEL:")
        print("-" * 80)
        print(f"{'ID':<8} {'Name':<30} {'Phone (DB)':<20} {'Status':<12} {'Active'}")
        print("-" * 80)
        for phone_norm in comparison['missing_in_excel']:
            driver = db_drivers[phone_norm]
            print(f"{driver['id']:<8} {driver['name'][:29]:<30} {driver['phone_raw']:<20} {driver['status']:<12} {driver['is_active']}")
    else:
        print("\n✅ All database drivers found in Excel file.")
    
    # Drivers in Excel but not in database
    if comparison['missing_in_db']:
        print(f"\n⚠️  {len(comparison['missing_in_db'])} DRIVERS IN EXCEL BUT NOT IN DATABASE:")
        print("-" * 80)
        print(f"{'Row':<8} {'Name':<30} {'Phone (Excel)':<20} {'Normalized Phone'}")
        print("-" * 80)
        for phone_norm in comparison['missing_in_db']:
            driver = excel_drivers[phone_norm]
            print(f"{driver['excel_row']:<8} {driver['name'][:29]:<30} {driver['phone_raw']:<20} {driver['phone_normalized']}")
    else:
        print("\n✅ All Excel drivers found in database.")
    
    # Drivers in both (sample if many)
    if comparison['in_both']:
        print(f"\n✅ {len(comparison['in_both'])} DRIVERS IN BOTH SOURCES")
        if len(comparison['in_both']) <= 10:
            print("-" * 80)
            for phone_norm in comparison['in_both'][:10]:
                db_driver = db_drivers[phone_norm]
                excel_driver = excel_drivers[phone_norm]
                print(f"   DB: {db_driver['name'][:30]:<30} | Excel: {excel_driver['name'][:30]:<30} | Phone: {phone_norm}")
        else:
            print(f"   (Showing first 10 of {len(comparison['in_both'])})")
            print("-" * 80)
            for phone_norm in list(comparison['in_both'])[:10]:
                db_driver = db_drivers[phone_norm]
                excel_driver = excel_drivers[phone_norm]
                print(f"   DB: {db_driver['name'][:30]:<30} | Excel: {excel_driver['name'][:30]:<30} | Phone: {phone_norm}")
    
    print("\n" + "="*80)


def export_missing_to_csv(comparison: Dict, db_drivers: Dict, excel_drivers: Dict, output_prefix: str):
    """Export missing drivers to CSV files."""
    
    # Export drivers missing in Excel
    if comparison['missing_in_excel']:
        missing_in_excel_file = f"{output_prefix}_missing_in_excel.csv"
        rows = []
        for phone_norm in comparison['missing_in_excel']:
            driver = db_drivers[phone_norm]
            rows.append({
                'id': driver['id'],
                'name': driver['name'],
                'phone': driver['phone_raw'],
                'phone_normalized': driver['phone_normalized'],
                'license_number': driver['license_number'],
                'status': driver['status'],
                'is_active': driver['is_active'],
                'created_at': driver['created_at']
            })
        df = pd.DataFrame(rows)
        df.to_csv(missing_in_excel_file, index=False, encoding='utf-8')
        print(f"💾 Exported missing in Excel: {missing_in_excel_file}")
    
    # Export drivers missing in database
    if comparison['missing_in_db']:
        missing_in_db_file = f"{output_prefix}_missing_in_database.csv"
        rows = []
        for phone_norm in comparison['missing_in_db']:
            driver = excel_drivers[phone_norm]
            rows.append({
                'excel_row': driver['excel_row'],
                'name': driver['name'],
                'phone': driver['phone_raw'],
                'phone_normalized': driver['phone_normalized']
            })
        df = pd.DataFrame(rows)
        df.to_csv(missing_in_db_file, index=False, encoding='utf-8')
        print(f"💾 Exported missing in database: {missing_in_db_file}")


def main():
    parser = argparse.ArgumentParser(
        description='Compare drivers between database and Excel by phone number',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Compare using default database connection (localhost:3307)
  python scripts/compare_drivers_by_phone.py drivers.xlsx

  # Specify phone column and name column
  python scripts/compare_drivers_by_phone.py drivers.xlsx --phone-col "Phone Number" --name-col "Driver Name"

  # Export missing drivers to CSV
  python scripts/compare_drivers_by_phone.py drivers.xlsx --export comparison_results

  # Custom database connection
  DB_HOST=10.0.2.2 DB_PORT=3306 python scripts/compare_drivers_by_phone.py drivers.xlsx
        """
    )
    
    parser.add_argument('excel', help='Path to Excel file containing driver data')
    parser.add_argument('--phone-col', default='phone', help='Phone column name in Excel (default: phone)')
    parser.add_argument('--name-col', default=None, help='Name column in Excel (auto-detected if not specified)')
    parser.add_argument('--sheet', default=0, help='Excel sheet index or name (default: 0)')
    
    # Database connection
    parser.add_argument('--db-host', default=os.getenv('DB_HOST', 'localhost'), help='Database host')
    parser.add_argument('--db-port', type=int, default=int(os.getenv('DB_PORT', '3307')), help='Database port')
    parser.add_argument('--db-name', default=os.getenv('DB_NAME', 'svlogistics_tms_db'), help='Database name')
    parser.add_argument('--db-user', default=os.getenv('DB_USER', 'root'), help='Database user')
    parser.add_argument('--db-password', default=os.getenv('DB_PASSWORD', 'rootpass'), help='Database password')
    
    # Export options
    parser.add_argument('--export', metavar='PREFIX', help='Export missing drivers to CSV files with given prefix')
    
    args = parser.parse_args()
    
    print("🔍 Starting driver comparison...")
    print(f"   Excel file: {args.excel}")
    print(f"   Database: {args.db_user}@{args.db_host}:{args.db_port}/{args.db_name}")
    
    # Connect to database
    conn = get_db_connection(
        host=args.db_host,
        port=args.db_port,
        user=args.db_user,
        password=args.db_password,
        database=args.db_name
    )
    
    # Fetch drivers from database
    print("\n📥 Fetching drivers from database...")
    db_drivers = fetch_drivers_from_db(conn)
    print(f"   Found {len(db_drivers)} drivers in database")
    
    # Read drivers from Excel
    print(f"\n📄 Reading drivers from Excel...")
    excel_drivers = read_drivers_from_excel(
        excel_path=args.excel,
        phone_col=args.phone_col,
        name_col=args.name_col,
        sheet=args.sheet
    )
    print(f"   Found {len(excel_drivers)} drivers in Excel")
    
    # Compare drivers
    print(f"\n🔄 Comparing drivers by phone number...")
    comparison = compare_drivers(db_drivers, excel_drivers)
    
    # Print report
    print_comparison_report(comparison, db_drivers, excel_drivers)
    
    # Export to CSV if requested
    if args.export:
        print(f"\n💾 Exporting results...")
        export_missing_to_csv(comparison, db_drivers, excel_drivers, args.export)
    
    # Close database connection
    conn.close()
    
    # Exit with appropriate code
    if comparison['missing_in_excel'] or comparison['missing_in_db']:
        print(f"\n⚠️  Found {len(comparison['missing_in_excel']) + len(comparison['missing_in_db'])} missing drivers")
        sys.exit(0)  # Success but with differences found
    else:
        print("\n✅ All drivers match between database and Excel!")
        sys.exit(0)


if __name__ == '__main__':
    main()
