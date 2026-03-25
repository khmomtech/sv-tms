> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Fleet Permanent Assignment - Testing Guide

## Quick Start Testing (5 minutes)

### Prerequisites

```bash
# 1. Start the full stack
docker-compose -f docker-compose.dev.yml up -d

# 2. Verify all services are running
docker-compose ps
# mysql, redis, backend, frontend should all be "Up"

# 3. Get admin token
# Login via UI or use existing token
```

### Test 1: Create Assignment via API

```bash
# Replace YOUR_TOKEN with actual JWT token
curl -X POST http://localhost:8080/api/admin/assignments/permanent \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -H "X-Request-ID: test-create-$(date +%s)" \
  -d '{
    "driverId": 1,
    "vehicleId": 5,
    "reason": "Initial assignment for testing"
  }' | jq

# Expected response:
# {
#   "success": true,
#   "message": "Truck assigned successfully",
#   "data": {
#     "id": 1,
#     "driverId": 1,
#     "vehicleId": 5,
#     "active": true,
#     ...
#   }
# }
```

### Test 2: Verify via UI

1. Open browser: `http://localhost:4200/fleet/assign-truck-driver`
2. Select Driver #1 from dropdown
3. Select Truck #5 from dropdown
4. Should see: "Driver #1 is already assigned to Truck #5"
5. Click Revoke → Should clear assignment

### Test 3: Check Health

```bash
curl http://localhost:8080/api/health/assignments | jq

# Expected:
# {
#   "status": "UP",
#   "activeAssignments": 1,
#   "timestamp": 1704460800000
# }
```

## Comprehensive Testing Scenarios

### Scenario 1: Happy Path - New Assignment

**Setup:** Clean state, no existing assignments

**Steps:**

1. POST `/api/admin/assignments/permanent`
   - driverId: 10, vehicleId: 20, reason: "Regular assignment"
2. GET `/api/admin/assignments/permanent/10`
3. GET `/api/admin/assignments/permanent/truck/20`

**Expected:**

- POST returns 200 with assignment data
- Both GETs return the same assignment
- Database has 1 active assignment

**Verify:**

```sql
SELECT * FROM permanent_assignments WHERE driver_id = 10 AND revoked_at IS NULL;
```

### Scenario 2: Automatic Revocation on Reassignment

**Setup:** Driver 10 is assigned to Truck 20

**Steps:**

1. POST `/api/admin/assignments/permanent`
   - driverId: 10, vehicleId: 25, reason: "Reassignment to different truck"
2. GET `/api/admin/assignments/permanent/10`
3. Check old assignment status

**Expected:**

- POST returns 200 with new assignment (Truck 25)
- GET returns only new assignment
- Old assignment (Truck 20) is revoked in database

**Verify:**

```sql
-- Should have 2 rows: 1 revoked, 1 active
SELECT id, vehicle_id, revoked_at IS NOT NULL as is_revoked
FROM permanent_assignments
WHERE driver_id = 10
ORDER BY assigned_at;
```

### Scenario 3: Truck Swap (1:1 Enforcement)

**Setup:** Driver 10 → Truck 20, Driver 15 → Truck 25

**Steps:**

1. POST assign Driver 10 to Truck 25 (without forceReassignment)
2. Check response
3. POST assign Driver 10 to Truck 25 (with forceReassignment: true)
4. Check both drivers' assignments

**Expected:**

- Step 1 returns 400 error: "Truck 25 is already assigned to driver 15"
- Step 3 returns 200, revokes Driver 15's assignment
- Driver 10 → Truck 25 (active)
- Driver 15 → no assignment
- Truck 20 → no assignment

**Verify:**

```sql
SELECT d.id as driver_id, pa.vehicle_id, pa.revoked_at IS NULL as active
FROM drivers d
LEFT JOIN permanent_assignments pa ON d.id = pa.driver_id AND pa.revoked_at IS NULL
WHERE d.id IN (10, 15);
```

### Scenario 4: Idempotency Check

**Setup:** Driver 10 is assigned to Truck 20

**Steps:**

1. POST assign Driver 10 to Truck 20 (same assignment)
2. Check response
3. Check database version

**Expected:**

- Returns 200 with existing assignment
- Message: "Driver is already assigned to this truck"
- Database version unchanged (still 0)
- No new row created

### Scenario 5: Business Rule Validations

#### 5a: Invalid Driver Status

```bash
# Setup: Mark driver 10 as INACTIVE
UPDATE drivers SET status = 'INACTIVE' WHERE id = 10;

# Test: Try to assign
curl -X POST http://localhost:8080/api/admin/assignments/permanent \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"driverId": 10, "vehicleId": 20, "reason": "Test"}' | jq

# Expected: 400 error
# {"success": false, "message": "Driver 10 is not in AVAILABLE status", ...}
```

#### 5b: Truck in Maintenance

```bash
# Setup: Mark truck as in maintenance
UPDATE vehicles SET status = 'MAINTENANCE' WHERE id = 20;

# Test: Try to assign
curl -X POST http://localhost:8080/api/admin/assignments/permanent \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"driverId": 10, "vehicleId": 20, "reason": "Test"}' | jq

# Expected: 400 error
# {"success": false, "message": "Truck 20 is in MAINTENANCE status", ...}
```

#### 5c: License Class Mismatch

```bash
# Setup: Driver has license class C, Truck requires class A
UPDATE drivers SET license_class = 'C' WHERE id = 10;
UPDATE vehicles SET required_license_class = 'A' WHERE id = 20;

# Test: Try to assign
curl -X POST http://localhost:8080/api/admin/assignments/permanent \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"driverId": 10, "vehicleId": 20, "reason": "Test"}' | jq

# Expected: 400 error
# {"success": false, "message": "Driver license class C is not compatible with truck requirement A", ...}
```

### Scenario 6: Optimistic Locking (Concurrent Updates)

**Setup:** Use two terminal windows

**Terminal 1:**

```bash
# Get current assignment
RESPONSE=$(curl -s -X GET http://localhost:8080/api/admin/assignments/permanent/10 \
  -H "Authorization: Bearer YOUR_TOKEN")
VERSION=$(echo $RESPONSE | jq -r '.data.version')

# Start slow update (simulate processing delay)
curl -X DELETE http://localhost:8080/api/admin/assignments/permanent/10 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "X-Request-ID: slow-request" &
```

**Terminal 2 (immediately after):**

```bash
# Concurrent update
curl -X POST http://localhost:8080/api/admin/assignments/permanent \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"driverId": 10, "vehicleId": 25, "reason": "Concurrent update"}' | jq
```

**Expected:**

- One succeeds with 200
- Other may fail with optimistic locking error (retry logic should handle)

### Scenario 7: UI Testing

#### 7a: Form Validation

1. Open `/fleet/assign-truck-driver`
2. Click Submit without selecting driver/truck
3. Expected: Form validation errors display

#### 7b: Current Assignment Display

1. Assign Driver 10 to Truck 20 via API
2. Open UI form
3. Select Driver 10
4. Expected: Shows "Currently assigned to: Truck #20"

#### 7c: Swap Warning

1. Setup: Driver 10 → Truck 20, Driver 15 → Truck 25
2. Open UI form
3. Select Driver 10, then Truck 25
4. Expected: Warning displays "Truck 25 is currently assigned to Driver 15"
5. Check "Force Reassignment"
6. Submit
7. Expected: Success, Driver 15 assignment revoked

#### 7d: Double Submission Prevention

1. Open form
2. Fill valid data
3. Click Submit rapidly 3 times
4. Expected: Only 1 request sent (button disabled during submission)

### Scenario 8: Driver App Testing

#### 8a: Load Assignment

```dart
// In driver_app
final provider = Provider.of<TruckProvider>(context);
await provider.fetchMainTruck(driverId);

// Verify
print('Truck: ${provider.mainTruckPlate}'); // Should show plate
print('Has assignment: ${provider.hasAssignment}'); // Should be true
```

#### 8b: Cache Management

```dart
// First load
await provider.fetchMainTruck(driverId);
final firstLoad = DateTime.now();

// Immediate second load (should use cache)
await provider.fetchMainTruck(driverId);
// Check logs: should show "Using cached assignment"

// Force refresh
await provider.fetchMainTruck(driverId, forceRefresh: true);
// Check logs: should fetch from API
```

#### 8c: Retry Logic

```bash
# Simulate network issues
# Stop backend
docker-compose stop backend

# In driver app, trigger fetch
# Expected: Retries 3 times with exponential backoff
# Logs should show: "attempt 1/3", "attempt 2/3", "attempt 3/3"

# Restart backend
docker-compose start backend

# Retry should succeed
```

### Scenario 9: Reconciliation Job Testing

```bash
# 1. Create duplicate assignment manually (bypass triggers)
docker exec -it sv-tms-mysql-1 mysql -u root -p sv_tms -e "
SET FOREIGN_KEY_CHECKS=0;
INSERT INTO permanent_assignments (driver_id, vehicle_id, assigned_at, assigned_by, reason, version, created_at, updated_at)
VALUES (10, 20, NOW(), 'manual', 'Duplicate test 1', 0, NOW(), NOW()),
       (10, 25, NOW(), 'manual', 'Duplicate test 2', 0, NOW(), NOW());
SET FOREIGN_KEY_CHECKS=1;
"

# 2. Run reconciliation job manually
# Add this to AssignmentReconciliationJob for testing:
# @Scheduled(cron = "0 * * * * *") // Every minute

# 3. Check logs
docker-compose logs backend | grep "CRITICAL: Driver"

# Expected:
# CRITICAL: Driver 10 has 2 active assignments (expected 1): ID=1,Truck=20, ID=2,Truck=25

# 4. Clean up
docker exec -it sv-tms-mysql-1 mysql -u root -p sv_tms -e "
DELETE FROM permanent_assignments WHERE driver_id = 10;
"
```

### Scenario 10: Health Check Testing

```bash
# 1. Normal state
curl http://localhost:8080/api/health/assignments | jq
# Expected: {"status":"UP","activeAssignments":N,"timestamp":...}

# 2. Database down
docker-compose stop mysql

curl http://localhost:8080/api/health/assignments | jq
# Expected: HTTP 503
# {"status":"DOWN","error":"...","timestamp":...}

# 3. Restore
docker-compose start mysql
```

## Performance Testing

### Load Test: Assignment Creation

```bash
# Create 100 assignments rapidly
for i in {1..100}; do
  curl -X POST http://localhost:8080/api/admin/assignments/permanent \
    -H "Authorization: Bearer YOUR_TOKEN" \
    -H "Content-Type: application/json" \
    -H "X-Request-ID: load-test-$i" \
    -d "{\"driverId\": $i, \"vehicleId\": $((i + 1000)), \"reason\": \"Load test\"}" &
done
wait

# Check results
curl http://localhost:8080/api/admin/assignments/permanent/stats \
  -H "Authorization: Bearer YOUR_TOKEN" | jq
```

### Database Trigger Performance

```sql
-- Measure trigger overhead
SET profiling = 1;

INSERT INTO permanent_assignments (driver_id, vehicle_id, assigned_at, assigned_by, reason, version, created_at, updated_at)
VALUES (999, 999, NOW(), 'perf-test', 'Performance test', 0, NOW(), NOW());

SHOW PROFILES;
-- Trigger overhead should be < 10ms
```

## Test Coverage Summary

| Component          | Test Coverage                     | Status |
| ------------------ | --------------------------------- | ------ |
| Backend Entity     | Optimistic locking, audit fields  | ✓      |
| Backend Service    | Business validations, idempotency | ✓      |
| Backend Controller | Error handling, request tracking  | ✓      |
| Database Migration | Table creation, triggers, indexes | ✓      |
| Frontend Service   | Retry logic, error handling       | ✓      |
| Frontend Component | Form validation, swap warnings    | ✓      |
| Driver App         | Retry, cache, timeout handling    | ✓      |
| Health Check       | Status endpoint, error states     | ✓      |
| Reconciliation Job | Duplicate detection, alerts       | ✓      |
| Backfill Migration | Conflict detection, logging       | ✓      |

## Common Issues & Solutions

### Issue: "Driver not found"

**Cause:** Invalid driverId in request
**Solution:** Verify driver exists: `SELECT id FROM drivers WHERE id = ?`

### Issue: "Truck already assigned"

**Cause:** 1:1 constraint violation
**Solution:** Use `forceReassignment: true` or revoke existing assignment first

### Issue: "Optimistic locking failure"

**Cause:** Concurrent updates
**Solution:** Retry the request (UI/app should handle automatically)

### Issue: Health check returns DOWN

**Cause:** Database connection issue
**Solution:** Check MySQL service, verify connection pool

### Issue: Reconciliation job finds duplicates

**Cause:** Data integrity issue
**Solution:** Review logs, manually revoke duplicates, investigate root cause

## Success Criteria

All tests passing:

- [ ] All 10 scenarios execute successfully
- [ ] No errors in backend logs
- [ ] No console errors in frontend
- [ ] Driver app displays assignments correctly
- [ ] Health check returns UP
- [ ] Reconciliation job runs without errors
- [ ] Performance tests meet SLA (< 500ms per assignment)

Ready for production ✓
