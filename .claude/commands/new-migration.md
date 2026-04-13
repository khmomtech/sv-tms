---
name: new-migration
description: Scaffold a new Flyway SQL migration file for tms-core-api
---

Create a new Flyway migration file for the change described in: $ARGUMENTS

Steps:
1. Check the latest migration version number in `tms-core-api/src/main/resources/db/migration/` by listing the files sorted by name.
2. Today's date is used for the version: format `V{YYYYMMDD}` (today: use the current date).
3. Create the file at `tms-core-api/src/main/resources/db/migration/V{date}__{snake_case_description}.sql`.
4. Write the SQL for the requested change. Use `IF NOT EXISTS` / `IF EXISTS` guards where appropriate.
5. If the change is destructive (DROP, ALTER with data loss), also create `U{date}__{description}_rollback.sql` with the undo SQL.
6. Output the filename(s) created and a summary of what the migration does.

Rules:
- Never edit an existing migration file.
- Use `V{YYYYMMDD}__{description}.sql` naming exactly.
- Target database: `svlogistics_tms_db` (MySQL 8 syntax).
