# Phase 2 Dispatch Approval: Quick Deployment Guide

**Date:** March 2, 2026  
**Target Audience:** Development & DevOps Teams  
**Objective:** Deploy Phase 2 dispatch approval workflow to pilot warehouse (1 location, 5-10 drivers)  
**Estimated Duration:** 2-4 hours (end-to-end)

---

## Current State

✅ **What's Done:**

- 4 backend Java files modified (SecurityConfig, DispatchStatus, DispatchService, LoadingWorkflowServiceImpl)
- 5 documentation files synchronized with canonical API contract
- Comprehensive regression test suite created (25+ tests)
- All changes compiled and ready in worktree: `copilot-worktree-2026-03-01T17-58-11`

❌ **What's Not Done:**

- Code not merged to main branch
- Backend not rebuilt with new changes
- Tests not executed against live backend
- Pilot warehouse not selected
- Deployment destination not prepared

---

## Step-by-Step Deployment

### Phase 1: Code Integration (30 min)

#### 1.1 Merge Worktree to Main

```bash
# From workspace root
cd /Users/sotheakh/Documents/develop/sv-tms

# Ensure main branch is clean
git checkout main
git status
# Should show: "working tree clean"

# Merge worktree changes
git merge copilot-worktree-2026-03-01T17-58-11
# Expected output: "Fast-forward" or "Merge made by..."

# Verify merge
git log --oneline -5
# Should show merge commit with message about dispatch workflow
```

#### 1.2 Rebuild Backend

```bash
# Navigate to backend
cd tms-backend

# Clean rebuild (generates all annotation processor outputs)
./mvnw clean package -DskipTests

# Expected output:
# ...
# [INFO] Building jar: target/tms-backend-3.5.7.jar
# [INFO] BUILD SUCCESS
```

**If build fails:**

```bash
# Check for Java 21 availability
java -version
# Output should show: "java 21.0.x"

# If Java version wrong, set explicitly
export JAVA_HOME=/path/to/java21
./mvnw clean package -DskipTests

# If still failing, check dependencies
./mvnw dependency:resolve
./mvnw dependency:tree | grep -i dispatch
```

#### 1.3 Verify Compilation

```bash
# Test that modified files compile correctly
./mvnw test -Dtest=DispatchStatusTest
./mvnw test -Dtest=DispatchValidationTest

# Expected output:
# [INFO] Tests run: X, Failures: 0, Errors: 0
```

---

### Phase 2: Local Testing (45 min)

#### 2.1 Start Local Backend

```bash
# Option A: Using Spring Boot Maven plugin
cd tms-backend
./mvnw spring-boot:run

# Expected output:
# ...
# Started Application in X.XXX seconds

# Option B: Using Docker (if Docker Compose configured)
docker compose -f docker-compose.dev.yml up --build
# Shows all services starting (MySQL, Redis, backend, frontend)
```

**Wait for Backend Ready:**

```bash
# In another terminal, verify backend health
for i in {1..30}; do
  curl -s http://localhost:8080/actuator/health && break
  sleep 1
done

# Expected response: {"status":"UP"}
```

#### 2.2 Verify API Endpoints

Test each key endpoint to confirm changes:

```bash
# 1. Check Security: Driver should be BLOCKED from /api/admin
DRIVER_TOKEN="eyJhbGc..." # Get from logs or test

curl -X GET http://localhost:8080/api/admin/dispatches \
  -H "Authorization: Bearer $DRIVER_TOKEN"
# Expected: 403 Forbidden ✅

# 2. Check Status Enum: Should accept only canonical values
curl -X POST http://localhost:8080/api/driver/dispatches/test-id/accept \
  -H "Authorization: Bearer $DRIVER_TOKEN"
# Expected: 200 with status="DRIVER_CONFIRMED" ✅

# 3. Check Transition Validation: Invalid transition should fail
curl -X PATCH http://localhost:8080/api/driver/dispatches/test-id \
  -H "Authorization: Bearer $DRIVER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"UNLOADED"}' \
  # Expected: 422 Invalid Transition ✅
```

#### 2.3 Run Regression Test Suite

```bash
# From workspace root
cd /Users/sotheakh/Documents/develop/sv-tms

# Install test dependencies if not already done
npm install --legacy-peer-deps

# Run full regression suite
npm test -- DISPATCH_LIFECYCLE_REGRESSION

# Expected output:
# PASS docs/testing/DISPATCH_LIFECYCLE_REGRESSION.test.ts
# ✓ Happy path: 13 step lifecycle (X ms)
# ✓ Negative tests: Invalid transitions (X ms)
# ✓ Security tests: Authorization boundaries (X ms)
# ✓ Performance tests: Concurrency & SLA (X ms)
#
# Test Suites: 1 passed, 1 total
# Tests:       25 passed, 25 total
# Success: 100% ✅
```

**If tests fail:**

```bash
# Check detailed error output
npm test -- DISPATCH_LIFECYCLE_REGRESSION --verbose

# Common causes:
# 1. Backend not running → Start backend first
# 2. Wrong API URL → Set API_BASE_URL=http://localhost:8080
# 3. Database state issue → Clear test data (MySQL).

# If persistent, check backend logs:
tail -f tms-backend/logs/application.log | grep -i dispatch
```

---

### Phase 3: Staging Preparation (1 hour)

#### 3.1 Select Pilot Warehouse

```bash
# Decision: Which warehouse location for pilot?
# Options:
# - Warehouse A (5 drivers, existing test drivers)
# - Warehouse B (8 drivers, lower volume)
# - Warehouse C (3 drivers, new setup)

# Recommendation: Warehouse A (established ops, easiest fallback)

export PILOT_WAREHOUSE="warehouse_a"
export PILOT_DRIVER_COUNT=5
```

#### 3.2 Prepare Staging Database

```bash
# 1. Create staging database snapshot (for rollback)
cd deploy/

# Backup current database
./backup-db.sh
# Output: Created backup_$(date).sql

# 2. Load test data for pilot warehouse
mysql -h staging-db -u root -p$DB_PASS svlogistics_tms_db << EOF
INSERT INTO warehouses (id, name, code)
  VALUES (UUID(), 'Pilot - $PILOT_WAREHOUSE', 'PILOT_$PILOT_WAREHOUSE');

INSERT INTO users (id, username, role)
  VALUES
  (UUID(), 'pilot_driver_001', 'ROLE_DRIVER'),
  (UUID(), 'pilot_driver_002', 'ROLE_DRIVER'),
  (UUID(), 'pilot_driver_003', 'ROLE_DRIVER'),
  (UUID(), 'pilot_driver_004', 'ROLE_DRIVER'),
  (UUID(), 'pilot_driver_005', 'ROLE_DRIVER');
EOF

# 3. Verify data loaded
mysql -h staging-db -u root -p$DB_PASS svlogistics_tms_db \
  -e "SELECT COUNT(*) as pilots FROM users WHERE username LIKE 'pilot_%';"
# Expected output: 5
```

#### 3.3 Configure Staging Deployment

```bash
# 1. Update application properties
cat > tms-backend/src/main/resources/application-staging.properties << EOF
server.port=8080
spring.datasource.url=jdbc:mysql://staging-db:3306/svlogistics_tms_db
spring.datasource.username=root
spring.datasource.password=${DB_PASS}
spring.redis.host=staging-redis
spring.redis.port=6379
spring.jpa.hibernate.ddl-auto=validate
logging.level.com.svtrucking=DEBUG
EOF

# 2. Build with staging profile
./mvnw clean package -DskipTests -Dspring.profiles.active=staging
```

#### 3.4 Deploy to Staging

```bash
# Deploy backend
cd deploy/
./deploy_backend.sh staging
# Expected output:
# ...
# Deployed to staging successfully
# Service URL: http://staging:8080

# Verify health
curl http://staging:8080/actuator/health
# Expected: {"status":"UP"}
```

---

### Phase 4: Pre-Pilot Validation (30 min)

#### 4.1 Run Full Regression Suite on Staging

```bash
# Point tests to staging backend
API_BASE_URL=http://staging:8080 npm test -- DISPATCH_LIFECYCLE_REGRESSION

# Expected: 100% success (25+ tests)
```

#### 4.2 Manual E2E Smoke Test

```bash
# Create admin user for testing
mysql -h staging-db -u root -p$DB_PASS svlogistics_tms_db << EOF
INSERT INTO users (id, username, role)
  VALUES (UUID(), 'pilot_admin', 'ROLE_ADMIN');
EOF

# Obtain JWT tokens (via login endpoint)
curl -X POST http://staging:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"pilot_driver_001","password":"password"}' \
  > driver_token.json

curl -X POST http://staging:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"pilot_admin","password":"password"}' \
  > admin_token.json

# Extract tokens
DRIVER_TOKEN=$(jq -r '.token' driver_token.json)
ADMIN_TOKEN=$(jq -r '.token' admin_token.json)

# Test flow: Create dispatch → Driver accept → Confirm status
DISPATCH_ID=$(curl -X POST http://staging:8080/api/admin/dispatches \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "orderId":"test_order_001",
    "driverId":"pilot_driver_001",
    "driveName":"Driver Test",
    "remarks":"Pilot flow test"
  }' | jq -r '.id')

echo "Created dispatch: $DISPATCH_ID"

# Driver accepts
curl -X POST http://staging:8080/api/driver/dispatches/$DISPATCH_ID/accept \
  -H "Authorization: Bearer $DRIVER_TOKEN" \
  -H "Content-Type: application/json" \
  | jq '.status'
# Expected: "DRIVER_CONFIRMED"

# Verify security: Driver blocked from admin
curl -X GET http://staging:8080/api/admin/dispatches \
  -H "Authorization: Bearer $DRIVER_TOKEN"
# Expected: 403 Forbidden ✅

echo "✅ All smoke tests passed"
```

#### 4.3 Review Backend Logs

```bash
# Check for errors
ssh staging-server "tail -100 /var/log/tms-backend.log" | grep -i error
# Should show: 0 errors or only pre-existing issues

# Check for warnings related to dispatch
ssh staging-server "tail -100 /var/log/tms-backend.log" | grep -i dispatch | grep -i warn
# Should show: 0 relevant warnings
```

---

### Phase 5: Production Pilot Deployment (1-2 hours)

#### 5.1 Prepare Production Pilot Environment

```bash
# 1. Identify pilot warehouse servers
export PILOT_PROD_SERVER="pilot-warehouse-a.sv-tms.lan"
export PILOT_PROD_DB="prod-pilot-db"

# 2. Create production backup (CRITICAL)
ssh $PILOT_PROD_SERVER << EOF
  sudo /opt/sv-tms/deploy/backup-prod-db.sh
  # Output: backup_prod_2026-03-02_14-30.sql
EOF

# 3. Deploy backend JAR
scp tms-backend/target/tms-backend-3.5.7.jar $PILOT_PROD_SERVER:/opt/sv-tms/backend/

# 4. Restart service (with confirmation)
read -p "DEPLOY RUNNING BACKEND? (ctrl+c to cancel, enter to proceed)" < /dev/tty
ssh $PILOT_PROD_SERVER "sudo systemctl restart tms-backend"

# 5. Wait for service startup
sleep 10
curl -s http://$PILOT_PROD_SERVER:8080/actuator/health | jq '.status'
# Expected: "UP"
```

#### 5.2 Notify Pilot Team

```bash
# Send message to pilot warehouse team
cat << EOF | mail -s "Phase 2 Dispatch Approval: Pilot Active" pilot-team@sv-tms.com

PILOT DEPLOYMENT ACTIVE
======================

Effective: $(date)
Warehouse: $PILOT_WAREHOUSE
Drivers: 5-10
Duration: 24-48 hours

KEY CHANGES:
1. New driver approval flow: /accept endpoint instead of /confirm
2. Enhanced security: Drivers blocked from admin operations
3. Better safety gates: Pre-entry checks prevent loading if failed
4. Stronger validation: Out-of-order state transitions rejected

MONITORING:
- Backend: http://$PILOT_PROD_SERVER:8080/actuator/health
- Issues: Slack #tms-incidents, Email: engineering@sv-tms.com

NEXT STEPS:
1. Complete test flows with test drivers
2. Report any errors to #tms-incidents
3. Monitor delivery success rates

Questions? Contact engineering team.
EOF
```

---

### Phase 6: Pilot Monitoring (24+ hours)

#### 6.1 Set Up Metrics Collection

```bash
# 1. Enable debug logging temporarily
ssh $PILOT_PROD_SERVER << EOF
  curl -X POST http://localhost:8080/actuator/loggers/com.svtrucking.logistics \
    -H "Content-Type: application/json" \
    -d '{"configuredLevel":"DEBUG"}'
EOF

# 2. Create dashboard query (Application Insights / CloudWatch)

# Metric 1: Dispatch Success Rate
SELECT
  COUNT(CASE WHEN status = 'CLOSED' THEN 1 END) * 100.0 / COUNT(*) as success_rate
FROM dispatches
WHERE created_at >= NOW() - INTERVAL 24 HOUR
  AND warehouse_id = '$PILOT_WAREHOUSE';

# Metric 2: Invalid Transition Rejection Rate
SELECT
  COUNT(*) as invalid_transitions,
  COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dispatch_status_changes) as pct
FROM dispatch_status_change_errors
WHERE created_at >= NOW() - INTERVAL 24 HOUR;

# Metric 3: Security Boundary Violations
SELECT COUNT(*) as unauthorized_attempts
FROM audit_log
WHERE event = 'UNAUTHORIZED_ACCESS'
  AND endpoint LIKE '/api/admin/%'
  AND role = 'ROLE_DRIVER'
  AND timestamp >= NOW() - INTERVAL 24 HOUR;
```

#### 6.2 Daily Health Check

```bash
# Run daily (e.g., 10 AM, 2 PM, 6 PM)

# 1. Verify backend health
HEALTH=$(curl -s http://$PILOT_PROD_SERVER:8080/actuator/health | jq '.status')
if [ "$HEALTH" != "UP" ]; then
  echo "❌ ALERT: Backend is DOWN" | mail -s "CRITICAL: Backend Down" engineering@sv-tms.com
  exit 1
fi

# 2. Check error rate
ERROR_COUNT=$(mysql -h $PILOT_PROD_DB -u root -p$DB_PASS svlogistics_tms_db -e \
  "SELECT COUNT(*) FROM logs WHERE level='ERROR' AND created_at >= NOW() - INTERVAL 4 HOUR;" | tail -1)

if [ $ERROR_COUNT -gt 10 ]; then
  echo "⚠️  WARNING: $ERROR_COUNT errors in last 4 hours" | mail -s "TMS Backend: High Error Rate" engineering@sv-tms.com
fi

# 3. Verify dispatch completion rate
SUCCESS_RATE=$(mysql -h $PILOT_PROD_DB -u root -p$DB_PASS svlogistics_tms_db -e \
  "SELECT COUNT(CASE WHEN status='CLOSED' THEN 1 END)*100.0/COUNT(*) \
   FROM dispatches WHERE created_at >= NOW() - INTERVAL 24 HOUR;" | tail -1)

echo "📊 Dispatch Success Rate: ${SUCCESS_RATE}% (Target: 98%+)"

# 4. Check database growth
DB_SIZE=$(mysql -h $PILOT_PROD_DB -u root -p$DB_PASS -e \
  "SELECT ROUND(SUM(data_length + index_length)/1024/1024,2) as size_mb \
   FROM information_schema.tables WHERE table_schema='svlogistics_tms_db';" | tail -1)

echo "💾 Database Size: ${DB_SIZE}MB"

# 5. Verify no unusual security events
SECURITY_ALERTS=$(mysql -h $PILOT_PROD_DB -u root -p$DB_PASS svlogistics_tms_db -e \
  "SELECT COUNT(*) FROM audit_log WHERE event='UNAUTHORIZED_ACCESS' AND timestamp >= NOW() - INTERVAL 4 HOUR;" | tail -1)

if [ $SECURITY_ALERTS -gt 0 ]; then
  echo "🚨 SECURITY: $SECURITY_ALERTS unauthorized access attempts" | mail -s "TMS: Security Alert" security@sv-tms.com
fi

# 6. Log health check
echo "[$(date)] Pilot Health Check: Backend=$HEALTH, Errors=$ERROR_COUNT, Success=${SUCCESS_RATE}%, Security=$SECURITY_ALERTS" \
  >> pilot_health_log.txt
```

#### 6.3 Rollback Procedure (If Issues)

```bash
# ONLY IF CRITICAL ISSUE DETECTED

echo "⚠️  INITIATING ROLLBACK"

# 1. Stop backend
ssh $PILOT_PROD_SERVER "sudo systemctl stop tms-backend"

# 2. Restore database from backup
ssh $PILOT_PROD_SERVER << EOF
  BACKUP_FILE=$(ls -t /backups/backup_prod_*.sql | head -1)
  mysql -h localhost -u root -p$DB_PASS svlogistics_tms_db < $BACKUP_FILE
  echo "✅ Database restored from $BACKUP_FILE"
EOF

# 3. Restart with previous code
ssh $PILOT_PROD_SERVER << EOF
  # Assume rolling deployment stores previous JAR in /opt/sv-tms/backend/prev/
  sudo cp /opt/sv-tms/backend/prev/tms-backend-*.jar /opt/sv-tms/backend/
  sudo systemctl start tms-backend
EOF

# 4. Verify rollback complete
curl -s http://$PILOT_PROD_SERVER:8080/actuator/health | jq '.status'
# Expected: "UP"

# 5. Notify team
echo "✅ ROLLBACK COMPLETE. Old version restored." | \
  mail -s "TMS Pilot: Rollback Successful" engineering@sv-tms.com

# 6. Post-mortem
echo "Create issue for root cause analysis (GitHub/JIRA)"
```

---

### Phase 7: Pilot Sign-Off (1-2 days)

#### 7.1 Collect Metrics Summary

```bash
# Query SLO compliance
mysql -h $PILOT_PROD_DB -u root -p$DB_PASS svlogistics_tms_db << EOF

-- Dispatch Completion SLO
SELECT
  COUNT(CASE WHEN status='CLOSED' THEN 1 END) * 100.0 / COUNT(*) as completion_rate
FROM dispatches
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 48 HOUR)
HAVING completion_rate >= 98.0; -- Target: 98%+

-- Invalid Transition Rejection Rate
SELECT
  COUNT(*) * 100.0 / (SELECT COUNT(*) FROM dispatch_status_changes WHERE updated_at >= DATE_SUB(NOW(), INTERVAL 48 HOUR)) as rejection_rate
FROM dispatch_status_change_errors
WHERE updated_at >= DATE_SUB(NOW(), INTERVAL 48 HOUR)
HAVING rejection_rate <= 0.5; -- Target: <0.5%

-- Security Boundary Violations
SELECT COUNT(*) as violations
FROM audit_log
WHERE event='UNAUTHORIZED_ACCESS'
  AND endpoint LIKE '/api/admin/%'
  AND role='ROLE_DRIVER'
  AND timestamp >= DATE_SUB(NOW(), INTERVAL 48 HOUR);
-- Target: 0

-- Approval Gate SLA (p95 < 2000ms)
SELECT
  PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY duration_ms) as p95_latency_ms
FROM dispatch_status_changes
WHERE status='CLOSED'
  AND updated_at >= DATE_SUB(NOW(), INTERVAL 48 HOUR);
-- Target: <2000ms

EOF
```

#### 7.2 Generate Sign-Off Report

```bash
cat > pilot_sign_off_2026-03-02.md << 'EOF'
# Pilot Deployment Sign-Off: Phase 2 Dispatch Approval

**Date:** March 2-3, 2026
**Warehouse:** $PILOT_WAREHOUSE
**Drivers:** 5
**Duration:** 48+ hours

## SLO Results

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Dispatch Completion Rate | 98%+ | XX.X% | ✅/❌ |
| Invalid Transition Rejection % | <0.5% | X.X% | ✅/❌ |
| Security Boundary Violations | 0 | X | ✅/❌ |
| Approval Gate SLA (p95) | <2000ms | XXXms | ✅/❌ |
| Safety Gate Pass Rate | 95%+ | XX.X% | ✅/❌ |

## Issues Found

1. [Issue #001: Description]
   - Severity: [Critical/High/Medium/Low]
   - Resolution: [Fixed/Deferred/Workaround]

2. [Issue #002: Description]
   - ...

## Recommendation

**PROCEED TO CANARY ROLLOUT** (if all SLOs met)
**HOLD FOR INVESTIGATION** (if any SLO not met)
**ROLLBACK** (if critical issues found)

**Signed:** Engineering Lead
**Date:** $(date)

EOF

# Share with team
mail -s "Pilot Sign-Off Report" engineering@sv-tms.com < pilot_sign_off_2026-03-02.md
```

---

## Rollout Progression Timeline

```
Day 0 (Today):
  - 14:00 Merge code to main
  - 14:30 Rebuild backend
  - 15:00 Run regression tests
  - 15:30 Deploy to staging
  - 16:00 Smoke tests on staging

Day 1:
  - 08:00 Deploy to pilot warehouse
  - 09:00 Notify pilot team, health monitoring enabled
  - 10:00-18:00 Continuous monitoring

Day 2-3:
  - 24-hour observation period
  - Daily health checks at 10 AM, 2 PM, 6 PM
  - Collect SLO metrics

Day 4 (Pilot Sign-Off):
  - 09:00 Review all metrics vs SLOs
  - 10:00 Team decision: Proceed to canary or hold
  - 11:00 Publish sign-off report

Day 5+:
  - If approved: Launch 10% canary rollout
  - Monitor for 48 hours
  - If stable: Proceed to full rollout
```

---

## Troubleshooting Quick Reference

| Issue                          | Symptom                                     | Solution                                                          |
| ------------------------------ | ------------------------------------------- | ----------------------------------------------------------------- |
| **Build Failure**              | `./mvnw` returns errors                     | Check Java version (21), run `clean package`                      |
| **Backend Won't Start**        | Logs show "Address already in use"          | `lsof -i :8080` and kill existing process                         |
| **DB Connection Error**        | "Can't connect to MySQL"                    | Verify MySQL running, check credentials in application.properties |
| **Tests Timeout**              | "Jest timeout after 30s"                    | Backend too slow, check DB indexes                                |
| **Security Test Fails**        | 403 for driver, but test expects 200        | Confirm SecurityConfig.java line 113 removed ROLE_DRIVER          |
| **Dispatch Won't Transition**  | 422 Invalid Transition                      | Verify current status in DB, check DispatchValidator rules        |
| **Safety Gate Enforced Wrong** | Loading allowed despite FAILED safety check | Verify LoadingWorkflowServiceImpl uses preEntrySafetyStatus       |

---

## Success Criteria

**Minimum (Go/No-Go Gate):**

- ✅ All 25+ regression tests passing
- ✅ 98%+ dispatch completion rate in pilot
- ✅ 0 security boundary violations
- ✅ No critical bugs reported

**Ideal (For Full Rollout):**

- ✅ 99%+ dispatch completion
- ✅ <500ms p95 approval latency
- ✅ Zero security incidents
- ✅ Driver feedback positive

---

**Last Updated:** March 2, 2026  
**Next Checkpoint:** Pilot completion + sign-off (March 4, 2026)
