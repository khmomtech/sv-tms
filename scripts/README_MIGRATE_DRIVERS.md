## Migrate Drivers from Excel

This script reads an Excel file and generates an SQL file that:
- TRUNCATEs the `drivers` and `users` tables (RESTART IDENTITY CASCADE)
- Inserts a `users` row and a `drivers` row for each Excel row with a phone number

Default password for all generated accounts: `123456` (bcrypt-hashed by the script).

Important: This is destructive. BACKUP your database before applying the generated SQL.

Requirements
- Python 3.8+
- pip packages: `pandas`, `openpyxl`, `bcrypt`

Install deps:

```bash
python3 -m pip install pandas openpyxl bcrypt
```

Generate SQL from your Excel (example using your path):

```bash
python3 scripts/migrate_drivers.py "/Users/sotheakh/Documents/SV Document/Book1.xlsx" --out migrate_drivers.sql
```

If your Excel uses different column names, supply them (defaults shown):

```bash
python3 scripts/migrate_drivers.py Book1.xlsx --name-col FullName --phone-col PhoneNumber --username-col User
```

Apply the generated SQL to your database (examples):

# For MySQL
```bash
# replace USER, HOST, DBNAME as appropriate
mysql -u USER -p -h HOST DBNAME < migrate_drivers.sql
```

# For PostgreSQL
```bash
# replace USER, HOST, DBNAME as appropriate
psql -h HOST -U USER -d DBNAME -f migrate_drivers.sql
```

Notes & customization
- The script assumes table/column names `users(id, username, phone, password, created_at)` and
  `drivers(id, user_id, name, phone, created_at)`. Edit the script if your schema differs.
- Passwords are hashed with `bcrypt` and inserted as the hash string. Ensure your auth system
  accepts bcrypt-hashed values in the `password` column.
- The script writes UUID strings for `id` and `user_id`. Adjust if your DB uses numeric IDs.

If you want, I can adapt the script to your exact DB schema (table & column names), or run the
script locally and produce `migrate_drivers.sql` for you. Tell me how you want to proceed.
