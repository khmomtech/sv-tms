> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🔍 Permission Issue Analysis & Complete Solution

## Current Status ✅

### Database Configuration (VERIFIED)
```
✓ All 3 driver permissions exist in database
✓ ADMIN role has all 3 driver permissions assigned
✓ Admin user (username: admin) has ADMIN role
✓ Effective permissions for admin user:
  - driver.view.all (from ADMIN role)
  - driver.manage (from ADMIN role)  
  - driver.account.manage (from ADMIN role)
```

### Code Configuration (VERIFIED)
```
✓ DriverController.java updated with hasAnyAuthority()
✓ All 5 document endpoints have correct @PreAuthorize annotations
✓ Permissions check: hasAnyAuthority('ADMIN', 'DISPATCHER') OR permission checks
```

## Problem Identified ⚠️

**The backend application is NOT RUNNING!**

Exit code: 137 (killed, likely OOM - Out of Memory)

### Evidence:
- Last terminal shows: `terminated with exit code: 137`
- Docker shows only MySQL running, no backend container
- Port 8080 is free (no process using it)

## Root Cause

Even though permissions are correctly configured, the error message **"Failed to load drivers. Access denied. You need DRIVER_VIEW_ALL or DRIVER_MANAGE permission to view driver documents"** is appearing because:

1. **Backend is down** → Frontend can't make API calls
2. **Old cached frontend error** → From previous failed attempts
3. **Session cache** → Old JWT token with old permissions

## Complete Solution

### Step 1: Restart Backend Application

#### Option A: Using Maven (Development)
```bash
cd /Users/sotheakh/Documents/develop/sv-tms/driver-app

# Kill any existing process on port 8080
lsof -ti:8080 | xargs kill -9 2>/dev/null

# Start with increased memory (to prevent OOM)
export MAVEN_OPTS="-Xmx2048m -Xms512m"
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

#### Option B: Using Docker (Recommended for Stability)
```bash
cd /Users/sotheakh/Documents/develop/sv-tms

# Rebuild and start driver-app
docker compose -f docker-compose.dev.yml up --build -d driver-app

# Check logs
docker compose -f docker-compose.dev.yml logs -f driver-app
```

#### Option C: Run as JAR (Production-like)
```bash
cd /Users/sotheakh/Documents/develop/sv-tms/driver-app

# Build
./mvnw clean package -DskipTests

# Run with memory settings
java -Xmx2048m -Xms512m -jar target/driver-app-*.jar --spring.profiles.active=dev
```

### Step 2: Clear All Caches

```bash
# Start Redis if not running
docker start svtms-redis 2>/dev/null || docker compose -f docker-compose.dev.yml up -d redis

# Clear Redis cache
docker exec -it svtms-redis redis-cli FLUSHALL

# Clear browser cache & cookies
# (Use browser DevTools: F12 → Application → Clear storage)
```

### Step 3: Clear User Session

1. **Log out completely** from the application
2. **Clear browser cache** (Ctrl+Shift+Delete / Cmd+Shift+Delete)
3. **Clear localStorage**:
   - Open Browser DevTools (F12)
   - Go to Application/Storage tab
   - Clear Local Storage and Session Storage
4. **Log in again** with admin credentials

### Step 4: Verify Backend is Running

```bash
# Check if port 8080 is in use
lsof -i:8080

# Should show java process running

# Test API endpoint
curl -X GET http://localhost:8080/actuator/health

# Should return: {"status":"UP"}
```

### Step 5: Test Permission Access

1. Navigate to Drivers page
2. Select a driver
3. Click on Documents tab
4. Should now load without "Access denied" error

## Why It Failed Before

### Timeline of Events:
1. Database permissions were granted correctly
2. Code was updated with hasAnyAuthority()
3. Application compiled successfully  
4. Application started on port 8080
5. ❌ **Application crashed (exit code 137 = killed by OS)**
6. ❌ User tried to access documents → Backend not responding
7. ❌ Frontend shows cached error message

### The OOM Issue

Exit code 137 typically means the process was killed by the OS due to:
- **Out of Memory (OOM)** - Most likely cause
- Manual kill signal
- Container memory limit exceeded

**Solution:** Increase JVM memory allocation

## Verification Checklist

After restarting, verify each item:

### 1. Backend Running
```bash
✓ curl http://localhost:8080/actuator/health
  Expected: {"status":"UP"}
```

### 2. Database Permissions
```bash
✓ ./diagnose-permissions.sh
  Expected: All green checkmarks
```

### 3. Code Changes Applied
```bash
✓ grep -A 2 "Get all documents for a driver" driver-app/src/main/java/com/svtrucking/logistics/controller/drivers/DriverController.java
  Expected: @PreAuthorize with hasAnyAuthority
```

### 4. User Can Access
- ✓ Log in as admin
- ✓ Navigate to Drivers  
- ✓ Select driver
- ✓ Click Documents tab
- ✓ See document list (or empty list, but no access denied)

## Monitoring Commands

```bash
# Monitor backend logs
tail -f driver-app/app.log | grep -i "access\|denied\|permission\|document"

# Monitor backend startup
docker compose -f docker-compose.dev.yml logs -f driver-app

# Check memory usage
docker stats driver-app

# Check Java process memory
ps aux | grep java
```

## If Still Getting Errors

### Check 1: Backend is Actually Running
```bash
lsof -i:8080
# If nothing, backend is down - restart it
```

### Check 2: Check Actual Backend Error
```bash
tail -100 driver-app/app.log | grep -i "access denied"
# Look for the REAL error message from Spring Security
```

### Check 3: Verify User Role in Token
```bash
# Decode JWT token from browser
# Go to jwt.io and paste the token
# Check if 'roles' contains 'ADMIN'
```

### Check 4: Enable Debug Logging
```properties
# In application.properties, add:
logging.level.com.svtrucking.logistics.security=TRACE
logging.level.org.springframework.security=DEBUG
```

## Quick Fix Summary

```bash
# 1. Start Redis (if not running)
docker start svtms-redis

# 2. Clear cache
docker exec -it svtms-redis redis-cli FLUSHALL

# 3. Kill old backend
lsof -ti:8080 | xargs kill -9

# 4. Start backend with more memory
cd driver-app
export MAVEN_OPTS="-Xmx2048m -Xms512m"
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev &

# 5. Wait for startup (watch for "Started Application")
tail -f app.log

# 6. Log out and back in to web app

# 7. Test access to driver documents
```

## Expected Behavior After Fix

1. Backend runs stably without crashing
2. Admin user can view driver list
3. Admin user can click on driver → Documents tab
4. Document list loads (or shows empty list)
5. No "Access denied" errors
6. Can create, edit, delete documents

## Files Changed Summary

| File | Status | Purpose |
|------|--------|---------|
| `fix-admin-permissions.sql` | Executed | Grant permissions to ADMIN |
| `DriverController.java` | Updated | Use hasAnyAuthority instead of hasRole |
| Database: `role_permissions` | Updated | 3 permissions added to ADMIN role |
| `diagnose-permissions.sh` | Created | Diagnostic tool |
| `PERMISSION_ISSUE_ANALYSIS.md` | Created | This document |

## Next Steps

1. **Immediate**: Restart backend with increased memory
2. **Short-term**: Monitor memory usage, adjust if needed
3. **Long-term**: Consider deploying with Docker for better resource management

---

**Status**: Permissions configured correctly  
**Issue**: Backend not running ❌  
**Action Required**: Restart backend application with sufficient memory
