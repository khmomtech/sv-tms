> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Performance Metrics Backend Integration Test Guide

## Overview
This guide helps you test the driver performance metrics integration between Flutter frontend and Spring Boot backend.

---

## Changes Made

### 1. Backend Entity (`Driver.java`)
Added performance tracking fields:
```java
@Column(name = "performance_score")
@Builder.Default
private Integer performanceScore = 92;

@Column(name = "leaderboard_rank")
@Builder.Default
private Integer leaderboardRank = 0;

@Column(name = "on_time_percent")
@Builder.Default
private Integer onTimePercent = 98;

@Column(name = "safety_score")
@Builder.Default
private String safetyScore = "Excellent";
```

### 2. Backend DTO (`DriverDto.java`)
Added fields with aliases for compatibility:
```java
// Performance metrics
private Integer performanceScore;
private Integer score; // Alias for performanceScore
private Integer rank; // Alias for leaderboardRank
private Integer leaderboardRank;
private Integer onTimePercent;
private String safety;
private String safetyScore; // Alias for safety
```

### 3. Database Migration
Created: `V1_12__add_driver_performance_metrics.sql`

---

## 🗄️ Database Setup

### Quick Update (Manual)
Run this SQL directly on your MySQL database:

```sql
-- Add performance metrics columns
ALTER TABLE drivers
ADD COLUMN IF NOT EXISTS performance_score INT DEFAULT 92,
ADD COLUMN IF NOT EXISTS leaderboard_rank INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS on_time_percent INT DEFAULT 98,
ADD COLUMN IF NOT EXISTS safety_score VARCHAR(50) DEFAULT 'Excellent';

-- Add indexes for performance queries
CREATE INDEX IF NOT EXISTS idx_drivers_performance_score ON drivers(performance_score);
CREATE INDEX IF NOT EXISTS idx_drivers_leaderboard_rank ON drivers(leaderboard_rank);

-- Update existing driver records with sample data
UPDATE drivers
SET 
  performance_score = 92,
  leaderboard_rank = 8,
  on_time_percent = 98,
  safety_score = 'Excellent'
WHERE id = 1;

-- Add varied test data for different drivers
UPDATE drivers SET performance_score = 95, leaderboard_rank = 3, on_time_percent = 99, safety_score = 'Outstanding' WHERE id = 2;
UPDATE drivers SET performance_score = 88, leaderboard_rank = 15, on_time_percent = 95, safety_score = 'Good' WHERE id = 3;
UPDATE drivers SET performance_score = 78, leaderboard_rank = 45, on_time_percent = 90, safety_score = 'Fair' WHERE id = 4;
```

### Using Docker
```bash
# Connect to MySQL container
docker exec -it sv-tms-mysql-1 mysql -u root -p

# Enter password from docker-compose.yml
# Then paste the SQL above
```

### Using MySQL CLI
```bash
mysql -h localhost -u root -p svlogistics_tms_db < tms-backend/src/main/resources/db/migration/V1_12__add_driver_performance_metrics.sql
```

---

## 🚀 Testing Steps

### Step 1: Apply Database Migration
```bash
cd /Users/sotheakh/Documents/develop/sv-tms

# Stop backend if running
kill $(cat backend-test.pid 2>/dev/null) 2>/dev/null

# Apply migration manually or let Spring Boot Flyway handle it on startup
```

### Step 2: Rebuild and Start Backend
```bash
cd tms-backend

# Clean compile
./mvnw clean compile -DskipTests

# Start backend
./mvnw spring-boot:run
```

### Step 3: Test API Endpoint
```bash
# Login to get JWT token
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"driver1","password":"password123"}' | jq -r '.data.token')

echo "Token: ${TOKEN:0:50}..."

# Fetch driver profile with performance metrics
curl -s -X GET "http://localhost:8080/api/driver/1" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq '.data | {
    id,
    firstName,
    lastName,
    rating,
    performanceScore,
    score,
    rank,
    leaderboardRank,
    onTimePercent,
    safety,
    safetyScore
  }'
```

### Expected Response
```json
{
  "id": 1,
  "firstName": "John",
  "lastName": "Doe",
  "rating": 4.8,
  "performanceScore": 92,
  "score": 92,
  "rank": 8,
  "leaderboardRank": 8,
  "onTimePercent": 98,
  "safety": "Excellent",
  "safetyScore": "Excellent"
}
```

### Step 4: Test Flutter Integration

#### Monitor Flutter Logs
```bash
# In the Flutter terminal, watch for profile fetch logs
# Look for:
# [DriverProvider] Profile loaded: John Doe (ID: 1)
# Then check the profile screen performance section
```

#### Verify UI Display
1. **Open Profile Screen** in the Flutter app
2. **Pull to refresh** to fetch latest data
3. **Check Performance Summary Card**:
   - Score should show: `92 / 100`
   - Rank should show: `#8 ដូចមណ្ឌលកម្រិតជាតិ`
   - Rating: `4.8` ⭐
   - On-time: `98%`
   - Safety: `Excellent`
   - Progress bar at 92%
   - Gold Rank badge

---

## 🔍 Debugging

### Check if Columns Exist
```sql
DESCRIBE drivers;
-- Should show: performance_score, leaderboard_rank, on_time_percent, safety_score
```

### Verify Data
```sql
SELECT 
  id,
  first_name,
  last_name,
  rating,
  performance_score,
  leaderboard_rank,
  on_time_percent,
  safety_score
FROM drivers
WHERE id = 1;
```

### Backend Logs
Look for:
```
[DriverDto] Mapping performance metrics: score=92, rank=8
```

### Flutter Logs
Look for:
```
[DriverProvider] Profile loaded: John Doe (ID: 1)
```

Then check what fields are in the response:
```dart
// Add temporary debug log in driver_provider.dart after line 208
debugPrint('[Performance Metrics] score=${data['performanceScore']}, rank=${data['rank']}');
```

---

## 📊 Sample Test Data

### Different Performance Tiers

```sql
-- Top Performer (Gold Elite)
UPDATE drivers SET 
  performance_score = 98,
  leaderboard_rank = 1,
  on_time_percent = 100,
  safety_score = 'Outstanding'
WHERE id = 1;

-- Good Performer (Silver)
UPDATE drivers SET 
  performance_score = 85,
  leaderboard_rank = 20,
  on_time_percent = 94,
  safety_score = 'Good'
WHERE id = 2;

-- Average Performer (Bronze)
UPDATE drivers SET 
  performance_score = 72,
  leaderboard_rank = 50,
  on_time_percent = 88,
  safety_score = 'Fair'
WHERE id = 3;

-- Low Performer
UPDATE drivers SET 
  performance_score = 58,
  leaderboard_rank = 120,
  on_time_percent = 75,
  safety_score = 'Needs Improvement'
WHERE id = 4;
```

---

## Verification Checklist

- [ ] Database columns created successfully
- [ ] Backend compiles without errors
- [ ] Backend starts without issues
- [ ] API endpoint returns performance fields
- [ ] Flutter receives performance data
- [ ] UI displays correct values (not fallbacks)
- [ ] Pull-to-refresh updates performance metrics
- [ ] Different performance tiers display correctly

---

## 🎯 Expected Behavior

### Before Integration
Flutter UI shows **fallback values** (hardcoded):
- Score: `92` (hardcoded)
- Rank: `8` (hardcoded)
- On-time: `98%` (hardcoded)
- Safety: `Excellent` (hardcoded)

### After Integration
Flutter UI shows **actual backend data**:
- Score: From `driver.performanceScore` (database value)
- Rank: From `driver.leaderboardRank` (database value)
- On-time: From `driver.onTimePercent` (database value)
- Safety: From `driver.safetyScore` (database value)

---

## 🔧 Troubleshooting

### Issue: Backend Compilation Errors
**Solution**: Check Lombok annotations are working
```bash
./mvnw clean compile -U -X | grep -i "performance"
```

### Issue: Columns Not Created
**Solution**: Run migration manually
```bash
mysql -u root -p svlogistics_tms_db < tms-backend/src/main/resources/db/migration/V1_12__add_driver_performance_metrics.sql
```

### Issue: API Returns NULL for Performance Fields
**Solution**: Check data exists in database
```sql
SELECT performance_score, leaderboard_rank FROM drivers WHERE id = 1;
```

### Issue: Flutter Still Shows Fallback Values
**Solution**: 
1. Clear app cache and restart
2. Add debug logs to verify API response
3. Check network logs in Flutter DevTools

---

## 📝 Testing Script

Save as `test-performance-integration.sh`:

```bash
#!/bin/bash

echo "=== Performance Metrics Integration Test ==="
echo ""

# 1. Check database
echo "1. Checking database columns..."
docker exec -it sv-tms-mysql-1 mysql -u root -proot123 -e "
  USE svlogistics_tms_db;
  DESCRIBE drivers;
" | grep -E "performance_score|leaderboard_rank|on_time_percent|safety_score"

# 2. Login and get token
echo ""
echo "2. Logging in..."
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"driver1","password":"password123"}' | jq -r '.data.token')

if [ "$TOKEN" != "null" ] && [ ! -z "$TOKEN" ]; then
  echo "Login successful"
  
  # 3. Fetch profile
  echo ""
  echo "3. Fetching driver profile..."
  RESPONSE=$(curl -s -X GET "http://localhost:8080/api/driver/1" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json")
  
  # 4. Extract performance fields
  echo ""
  echo "4. Performance Metrics:"
  echo "$RESPONSE" | jq '.data | {
    performanceScore,
    leaderboardRank,
    onTimePercent,
    safetyScore
  }'
  
  # 5. Verify not null
  SCORE=$(echo "$RESPONSE" | jq '.data.performanceScore')
  if [ "$SCORE" != "null" ]; then
    echo ""
    echo "SUCCESS: Performance metrics are integrated!"
  else
    echo ""
    echo "❌ FAIL: Performance metrics are NULL in response"
    echo "Check database and DTO mapping"
  fi
else
  echo "❌ Login failed - check backend is running"
fi
```

Make executable and run:
```bash
chmod +x test-performance-integration.sh
./test-performance-integration.sh
```

---

## 🎓 Next Steps

1. **Implement Real Metrics Calculation**:
   - Calculate `performanceScore` based on shipment completion rate
   - Calculate `leaderboardRank` based on scores across all drivers
   - Calculate `onTimePercent` from shipment delivery times
   - Determine `safetyScore` from incident reports

2. **Add Scheduled Jobs**:
   ```java
   @Scheduled(cron = "0 0 2 * * ?") // Daily at 2 AM
   public void updateDriverPerformanceMetrics() {
     // Recalculate all driver metrics
   }
   ```

3. **Add Performance History Tracking**:
   - Create `DriverPerformanceHistory` entity
   - Track monthly/weekly trends
   - Display charts in Flutter app

4. **Add Leaderboard Endpoint**:
   ```java
   @GetMapping("/api/drivers/leaderboard")
   public List<DriverDto> getTopPerformers() {
     return driverRepository.findTop100ByOrderByPerformanceScoreDesc();
   }
   ```

---

**Status**: Ready for testing after database migration and backend rebuild
