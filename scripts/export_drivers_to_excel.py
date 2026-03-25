#!/usr/bin/env python3
"""
Export drivers from database to Excel file.
Creates a backup Excel file with all driver information.

Usage:
  python3 scripts/export_drivers_to_excel.py
  python3 scripts/export_drivers_to_excel.py --output drivers_backup.xlsx

Requirements:
  pip install pandas openpyxl pymysql
"""
import argparse
import pandas as pd
import pymysql
import os
import sys
from datetime import datetime


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


def fetch_drivers_from_db(conn):
    """Fetch all drivers from database."""
    with conn.cursor() as cursor:
        cursor.execute("""
            SELECT 
                d.id,
                d.first_name,
                d.last_name,
                d.name,
                d.phone,
                d.license_class,
                d.status,
                d.is_active,
                d.rating,
                d.id_card_expiry,
                d.performance_score,
                d.leaderboard_rank,
                d.on_time_percent,
                d.safety_score,
                d.zone,
                d.vehicle_type,
                d.is_partner,
                d.employee_id,
                d.assigned_vehicle_id,
                d.device_token,
                u.username,
                u.email,
                pc.company_name as partner_company_name
            FROM drivers d
            LEFT JOIN users u ON d.user_id = u.id
            LEFT JOIN partner_companies pc ON d.partner_company_id = pc.id
            ORDER BY d.id
        """)
        rows = cursor.fetchall()
    
    # Convert to list of dicts
    drivers = []
    for row in rows:
        driver = {
            'id': row.get('id'),
            'name': row.get('name') or f"{row.get('first_name', '')} {row.get('last_name', '')}".strip(),
            'first_name': row.get('first_name'),
            'last_name': row.get('last_name'),
            'phone': row.get('phone'),
            'username': row.get('username'),
            'email': row.get('email'),
            'license_class': row.get('license_class'),
            'id_card_expiry': row.get('id_card_expiry'),
            'status': row.get('status'),
            'is_active': row.get('is_active'),
            'rating': row.get('rating'),
            'performance_score': row.get('performance_score'),
            'leaderboard_rank': row.get('leaderboard_rank'),
            'on_time_percent': row.get('on_time_percent'),
            'safety_score': row.get('safety_score'),
            'zone': row.get('zone'),
            'vehicle_type': row.get('vehicle_type'),
            'is_partner': row.get('is_partner'),
            'partner_company': row.get('partner_company_name'),
            'employee_id': row.get('employee_id'),
            'assigned_vehicle_id': row.get('assigned_vehicle_id'),
            'device_token': row.get('device_token')
        }
        drivers.append(driver)
    
    return drivers


def export_to_excel(drivers, output_file, include_all_fields=False):
    """Export drivers to Excel file."""
    
    if include_all_fields:
        # All fields for complete backup
        df = pd.DataFrame(drivers)
    else:
        # Essential fields only (cleaner for comparison/import)
        essential_data = []
        for driver in drivers:
            essential_data.append({
                'id': driver['id'],
                'name': driver['name'],
                'phone': driver['phone'],
                'license_class': driver['license_class'],
                'status': driver['status'],
                'is_active': driver['is_active'],
                'rating': driver['rating'],
                'zone': driver['zone'],
                'vehicle_type': driver['vehicle_type'],
                'partner_company': driver['partner_company']
            })
        df = pd.DataFrame(essential_data)
    
    # Create Excel writer with formatting
    with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
        df.to_excel(writer, sheet_name='Drivers', index=False)
        
        # Get the worksheet
        worksheet = writer.sheets['Drivers']
        
        # Auto-adjust column widths
        for idx, col in enumerate(df.columns):
            max_length = max(
                df[col].astype(str).apply(len).max(),
                len(str(col))
            ) + 2
            worksheet.column_dimensions[chr(65 + idx)].width = min(max_length, 50)
        
        # Freeze header row
        worksheet.freeze_panes = 'A2'
        
        # Style header row
        from openpyxl.styles import Font, PatternFill, Alignment
        header_fill = PatternFill(start_color='366092', end_color='366092', fill_type='solid')
        header_font = Font(bold=True, color='FFFFFF')
        
        for cell in worksheet[1]:
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = Alignment(horizontal='center', vertical='center')
    
    return df


def main():
    parser = argparse.ArgumentParser(
        description='Export drivers from database to Excel file',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Export with default filename (drivers_YYYYMMDD_HHMMSS.xlsx)
  python3 scripts/export_drivers_to_excel.py

  # Export to specific file
  python3 scripts/export_drivers_to_excel.py --output my_drivers.xlsx

  # Export all fields (complete backup)
  python3 scripts/export_drivers_to_excel.py --all-fields

  # Custom database connection
  python3 scripts/export_drivers_to_excel.py --db-host 10.0.2.2 --db-port 3306
        """
    )
    
    # Output options
    parser.add_argument('--output', '-o', 
                       default=None,
                       help='Output Excel file (default: drivers_YYYYMMDD_HHMMSS.xlsx)')
    parser.add_argument('--all-fields', action='store_true',
                       help='Export all database fields (default: essential fields only)')
    
    # Database connection
    parser.add_argument('--db-host', default=os.getenv('DB_HOST', 'localhost'))
    parser.add_argument('--db-port', type=int, default=int(os.getenv('DB_PORT', '3307')))
    parser.add_argument('--db-name', default=os.getenv('DB_NAME', 'svlogistics_tms_db'))
    parser.add_argument('--db-user', default=os.getenv('DB_USER', 'root'))
    parser.add_argument('--db-password', default=os.getenv('DB_PASSWORD', 'rootpass'))
    
    args = parser.parse_args()
    
    # Generate default filename if not provided
    if not args.output:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        args.output = f'drivers_{timestamp}.xlsx'
    
    print('📊 Exporting drivers from database to Excel...')
    print(f'   Database: {args.db_user}@{args.db_host}:{args.db_port}/{args.db_name}')
    print(f'   Output: {args.output}')
    print(f'   Mode: {"All fields" if args.all_fields else "Essential fields only"}')
    
    # Connect to database
    print('\n🔌 Connecting to database...')
    conn = get_db_connection(
        host=args.db_host,
        port=args.db_port,
        user=args.db_user,
        password=args.db_password,
        database=args.db_name
    )
    
    # Fetch drivers
    print('📥 Fetching drivers...')
    drivers = fetch_drivers_from_db(conn)
    print(f'   Found {len(drivers)} drivers')
    
    if not drivers:
        print('⚠️  No drivers found in database!')
        sys.exit(0)
    
    # Export to Excel
    print(f'\n💾 Creating Excel file...')
    df = export_to_excel(drivers, args.output, args.all_fields)
    
    # Close database connection
    conn.close()
    
    # Summary
    print('\n' + '='*60)
    print('✅ Export completed successfully!')
    print('='*60)
    print(f'   File: {args.output}')
    print(f'   Total drivers: {len(drivers)}')
    print(f'   Columns: {len(df.columns)}')
    print(f'   File size: {os.path.getsize(args.output) / 1024:.1f} KB')
    
    print('\n📋 Column list:')
    for idx, col in enumerate(df.columns, 1):
        print(f'   {idx:2d}. {col}')
    
    print('\n💡 Next steps:')
    print(f'   • Open file: open {args.output}')
    print(f'   • Compare with old backup: python3 scripts/compare_drivers_by_phone.py {args.output}')
    print(f'   • Import to database: python3 scripts/migrate_drivers.py {args.output}')


if __name__ == '__main__':
    main()
