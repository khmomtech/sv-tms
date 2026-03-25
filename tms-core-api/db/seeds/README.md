Seed: create_test_driver
------------------------

This folder contains helper SQL and scripts to create a test driver account and an approved device for local development.

Files:
- `seed_test_driver.sql` — idempotent SQL that inserts a `drivers` row with license `TEST-LIC-001` if missing.

Quick usage (macOS / zsh):

1. Ensure the dev stack is running: `docker compose -f docker-compose.dev.yml up --build`
2. Make the helper script executable:
   `chmod +x ./scripts/create_test_driver.sh`
3. Run the script:
   `./scripts/create_test_driver.sh`

What the script does:
- Inserts a `drivers` row if missing (license `TEST-LIC-001`).
- Uses the admin account (`admin` / `admin123`) to call `POST /api/auth/registerdriver?driverId=<id>` and create a user `testdriver` with role `DRIVER`.
- Inserts an approved `device_registered` row for `device_id = test-device-001` linked to the driver.
- Attempts a driver login against `POST /api/auth/driver/login` to verify flow.

Notes:
- The script assumes default docker-compose service names and credentials in `docker-compose.dev.yml` (MySQL root password `rootpass`, DB `svlogistics_tms_db`). Adjust the variables at the top of `scripts/create_test_driver.sh` if your environment differs.
- Registration requires ADMIN privileges. The script logs in as `admin` and uses that token when calling the `registerdriver` endpoint.
- If you prefer to run the steps manually, apply `seed_test_driver.sql` to the DB and then call the register endpoint as an admin.
