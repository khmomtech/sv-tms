# Phase 2 Deployment Checklist & Quick Reference

**Printed:** March 2, 2026  
**for:** Development & DevOps Teams  
**Duration:** Post on war room wall during pilot

---

## SECTION A: Code Integration (30 min)

### ☐ Pre-Merge Verification

```bash
cd /Users/sotheakh/Documents/develop/sv-tms
git status                    # ✓ Should show: working tree clean
git log --oneline -1          # ✓ Should show latest main branch commit
```

### ☐ Merge Worktree

```bash
git merge copilot-worktree-2026-03-01T17-58-11
# ✓ Expected: "Fast-forward" or merge commit created
```

### ☐ Rebuild Backend

```bash
cd tms-backend
./mvnw clean package -DskipTests
# ✓ Expected: "BUILD SUCCESS"
# ✓ Verify: target/tms-backend-*.jar exists
```

### ☐ Verify Key Files Modified

```bash
git show --name-only HEAD
# Should list:
# - src/main/java/com/svtrucking/logistics/security/SecurityConfig.java
# - src/main/java/com/svtrucking/logistics/enums/DispatchStatus.java
# - src/main/java/com/svtrucking/logistics/service/DispatchService.java
# - src/main/java/com/svtrucking/logistics/service/impl/LoadingWorkflowServiceImpl.java
```

---

## SECTION B: Local Testing (45 min)

### ☐ Start Backend

**Option A (Spring Boot):**

```bash
cd tms-backend && ./mvnw spring-boot:run
# Wait for: "Started Application in X.XXX seconds"
```

**Option B (Docker):**

```bash
cd /repo/infra && docker compose -f docker-compose.dev.yml up --build
# Wait for: All containers healthy (MySQL, Redis, backend, frontend)
```

### ☐ Verify Backend Ready

```bash
# Check in another terminal
curl http://localhost:8080/actuator/health
# ✓ Expected: {"status":"UP"}
```

### ☐ Test Security Boundary

```bash
# Get driver token first (check backend logs or test setup)
curl -X GET http://localhost:8080/api/admin/dispatches \
  -H "Authorization: Bearer <DRIVER_TOKEN>"
# ✓ Expected: 403 Forbidden
```

### ☐ Run Regression Test Suite

```bash
cd /repo
npm install --legacy-peer-deps  # (only if needed)
npm test -- DISPATCH_LIFECYCLE_REGRESSION
# ✓ Expected: 25+ tests PASS, Test output: 100% success
```

### ☐ Log Test Results

```bash
npm test -- DISPATCH_LIFECYCLE_REGRESSION > test_results_local_$(date +%s).txt
# Save for reference
```

---

## SECTION C: Staging Deployment (1 hour)

### ☐ Select Pilot Warehouse & Drivers

```
Warehouse ID: ________________________
Warehouse Name: ________________________
Driver Count: _____ (recommend: 5-10)
Admin User for Testing: ________________________
Test Driver Users: ________________________
```

### ☐ Create Production Backup

```bash
# SSH to staging server
ssh staging-db-host

# Backup database
cd /backups && ./backup-db.sh
# ✓ Expected: backup_20260302_*.sql created
```

### ☐ Deploy to Staging

```bash
cd tms-backend
./mvnw clean package -DskipTests -Dspring.profiles.active=staging

# Deploy JAR to staging server
scp target/tms-backend-*.jar deploy-user@staging-server:/opt/sv-tms/backend/

# Restart service
ssh deploy-user@staging-server "sudo systemctl restart tms-backend"
```

### ☐ Verify Staging Health

```bash
curl http://staging-server:8080/actuator/health
# ✓ Expected: {"status":"UP"}
```

### ☐ Run Tests on Staging

```bash
API_BASE_URL=http://staging-server:8080 npm test -- DISPATCH_LIFECYCLE_REGRESSION
# ✓ Expected: 100% success
```

---

## SECTION D: Production Pilot Deployment (1-2 hours)

### ☐ Final Go/No-Go Decision

| Criteria                | Status | Sign   |
| ----------------------- | ------ | ------ |
| Local tests 100% pass   | ✓ ☐    | **\_** |
| Staging tests 100% pass | ✓ ☐    | **\_** |
| Code review approved    | ✓ ☐    | **\_** |
| Pilot warehouse ready   | ✓ ☐    | **\_** |
| Rollback plan reviewed  | ✓ ☐    | **\_** |

**GO/NO-GO:** ☐ GO ☐ NO-GO  
**Authorized by:** **********\_\_\_\_**********  
**Time:** ****\_\_\_\_****

### ☐ Create Final Production Backup

```bash
ssh deploy-user@pilot-prod-server
cd /backups && sudo ./backup-prod-db.sh
# ✓ Backup file location: ________________
```

### ☐ Deploy to Pilot Production

```bash
# Deploy JAR
scp tms-backend/target/tms-backend-*.jar \
  deploy-user@pilot-prod-server:/opt/sv-tms/backend/

# Restart (requires verification before continuing)
read -p "Ready to restart backend? (y/n) " READY
ssh deploy-user@pilot-prod-server "sudo systemctl restart tms-backend"

# Wait 10 seconds
sleep 10

# Verify health
curl http://pilot-prod-server:8080/actuator/health
# ✓ Expected: {"status":"UP"}
```

### ☐ Notify Pilot Team

```bash
# Send notification with key info
cat << EOF | mail -s "Phase 2 Dispatch: Pilot Deployment LIVE" pilot-team@sv-tms.com

DEPLOYMENT LIVE: Phase 2 Dispatch Approval
===========================================

Time: $(date)
Warehouse: [WAREHOUSE HERE]
Drivers: [COUNT HERE]

WHAT CHANGED:
✓ New driver approval endpoint: /accept (replaces /confirm)
✓ Enhanced security: Drivers blocked from admin operations
✓ Better safety gates: Pre-entry checks prevent unsafe loading
✓ Stronger validation: Out-of-order state transitions blocked

TEST FLOW (for validation):
1. Admin creates dispatch
2. Driver accepts (status → DRIVER_CONFIRMED)
3. Driver arrives loading (status → ARRIVED_LOADING)
4. Safety inspector checks vehicle
5. Driver starts loading (status → LOADING)
...and so on through delivery

MONITORING:
- Backend Health: curl http://pilot-server:8080/actuator/health
- Issues: Report to #tms-incidents immediately
- Contact: engineering@sv-tms.com

EOF
```

---

## SECTION E: Pilot Monitoring (24+ hours)

### Day 1: Continuous Monitoring

**Every 4 hours, run health check:**

```bash
# 1. Backend Health
HEALTH=$(curl -s http://pilot-prod-server:8080/actuator/health | jq '.status')
echo "[$(date)] Backend: $HEALTH"

# 2. Error Count (last 4 hours)
ERROR_COUNT=$(mysql -h pilot-db -u root -p$PASS svlogistics_tms_db -e \
  "SELECT COUNT(*) FROM logs WHERE level='ERROR' AND created_at >= NOW() - INTERVAL 4 HOUR;" | tail -1)
echo "[$(date)] Errors (4h): $ERROR_COUNT"

# 3. Success Rate (last 24 hours)
SUCCESS=$(mysql -h pilot-db -u root -p$PASS svlogistics_tms_db -e \
  "SELECT COUNT(CASE WHEN status='CLOSED' THEN 1 END)*100.0/COUNT(*) \
   FROM dispatches WHERE created_at >= NOW() - INTERVAL 24 HOUR;" | tail -1)
echo "[$(date)] Success Rate: ${SUCCESS}%"

# 4. Security Events
SECURITY=$(mysql -h pilot-db -u root -p$PASS svlogistics_tms_db -e \
  "SELECT COUNT(*) FROM audit_log WHERE event='UNAUTHORIZED_ACCESS' AND timestamp >= NOW() - INTERVAL 4 HOUR;" | tail -1)
echo "[$(date)] Security Alerts: $SECURITY"
```

**SLO Targets (Display on War Room Board):**

| Metric           | Target | Actual   | Status |
| ---------------- | ------ | -------- | ------ |
| Backend Health   | UP     | \_\_\_\_ | ☐      |
| Error Rate (24h) | <10    | \_\_\_\_ | ☐      |
| Success Rate     | 98%+   | \_\_\_\_ | ☐      |
| Security Events  | 0      | \_\_\_\_ | ☐      |

### Day 2-3: Review & Sign-Off

```bash
# Final metrics collection
mysql -h pilot-db -u root -p$PASS svlogistics_tms_db << EOF

-- Success Rate
SELECT COUNT(CASE WHEN status='CLOSED' THEN 1 END)*100.0/COUNT(*) as rate
FROM dispatches WHERE created_at >= DATE_SUB(NOW(), INTERVAL 48 HOUR);

-- Transitions Rejected
SELECT COUNT(*) as rejected
FROM dispatch_status_change_errors
WHERE updated_at >= DATE_SUB(NOW(), INTERVAL 48 HOUR);

-- Security Violations
SELECT COUNT(*) as violations
FROM audit_log
WHERE event='UNAUTHORIZED_ACCESS' AND timestamp >= DATE_SUB(NOW(), INTERVAL 48 HOUR);

EOF
```

---

## SECTION F: Emergency Contacts & Escalation

**Team Slack Channels:**

- `#tms-incidents` ← Report issues immediately
- `#tms-engineering` ← Team coordination
- `#tms-pilots` ← Pilot-specific updates

**Email Escalation:**

- First Alert: engineering@sv-tms.com
- Critical Issue: engineering@sv-tms.com + leadership@sv-tms.com
- Security Issue: security@sv-tms.com + engineering@sv-tms.com

**On-Call Engineer (if applicable):**

- Name: **********\_\_\_\_**********
- Phone: **********\_\_\_\_**********
- Slack: **********\_\_\_\_**********

---

## SECTION G: Rollback Procedure (DO NOT ATTEMPT WITHOUT LEADERSHIP APPROVAL)

**CONDITIONS FOR ROLLBACK:**

- ❌ Backend health cannot be restored
- ❌ 5+ unresolved critical bugs reported
- ❌ Security boundary violation detected
- ❌ >15% dispatch failures

**ROLLBACK STEPS (30-60 min):**

```bash
# 1. ANNOUNCE ROLLBACK
# Post to #tms-incidents: "INITIATING ROLLBACK - Phase 2 pilot suspended"

# 2. STOP BACKEND
ssh deploy-user@pilot-prod-server "sudo systemctl stop tms-backend"

# 3. RESTORE DATABASE
ssh deploy-user@pilot-prod-server << EOF
  BACKUP=$(ls -t /backups/backup_prod_*.sql | head -1)
  echo "Restoring from: $BACKUP"
  mysql -h localhost -u root -p$PASS svlogistics_tms_db < $BACKUP
  echo "✓ Database restored"
EOF

# 4. RESTART WITH OLD CODE
ssh deploy-user@pilot-prod-server << EOF
  # Copy previous JAR or rebuild from previous commit
  cd /opt/sv-tms/backend
  git checkout HEAD~1  # Revert 1 commit
  ./mvnw clean package -DskipTests
  java -jar target/tms-backend-*.jar &
EOF

# 5. VERIFY RESTORED
curl http://pilot-prod-server:8080/actuator/health
# ✓ Expected: {"status":"UP"}

# 6. NOTIFY TEAM
echo "✅ ROLLBACK COMPLETE - Old version restored" | \
  mail -s "Pilot Rollback: COMPLETE" engineering@sv-tms.com
```

---

## SECTION H: Reference Links

**Key Files (Bookmark These):**

- [Implementation Summary](../docs/IMPLEMENTATION_SUMMARY_2026-03-02.md)
- [Regression Test Suite README](../docs/testing/REGRESSION_TEST_SUITE_README.md)
- [Deployment Guide](../deploy/DEPLOYMENT_GUIDE_PHASE_2_2026-03-02.md)
- [API Docs (Live)](http://localhost:8080/swagger-ui.html) — Available when backend running

**Backend Source Code:**

- SecurityConfig: `tms-backend/src/main/java/.../security/SecurityConfig.java`
- DispatchStatus: `tms-backend/src/main/java/.../enums/DispatchStatus.java`
- DispatchService: `tms-backend/src/main/java/.../service/DispatchService.java`
- LoadingWorkflow: `tms-backend/src/main/java/.../service/impl/LoadingWorkflowServiceImpl.java`

---

## QUICK COMMAND REFERENCE

```bash
# ============ BUILD & TEST ============
cd tms-backend
./mvnw clean package -DskipTests              # Build backend
npm test -- DISPATCH_LIFECYCLE_REGRESSION     # Run tests

# ============ LOCAL DEPLOYMENT ============
./mvnw spring-boot:run                        # Start backend
curl http://localhost:8080/actuator/health    # Check health

# ============ STAGING/PRODUCTION ============
git merge copilot-worktree-2026-03-01T17-58-11  # Merge changes
scp target/tms-backend-*.jar user@server:/...   # Deploy JAR
ssh user@server "sudo systemctl restart ..."     # Restart service

# ============ MONITORING ============
curl http://server:8080/actuator/health       # Health check
tail -f /var/log/tms-backend.log              # View logs (if SSH'd)
curl http://server:8080/v3/api-docs | jq     # Check OpenAPI spec

# ============ DATABASE ============
mysql -h host -u root -p db -e "SELECT ..."   # Run query
./backup-db.sh                                # Create backup
```

---

**PRINT THIS PAGE**  
**POST ON WAR ROOM WALL**  
**UPDATE BOXES AS TASKS COMPLETE**

---

_Generated: March 2, 2026_  
_For: Phase 2 Dispatch Approval Pilot_  
_Owner: Engineering Team_
