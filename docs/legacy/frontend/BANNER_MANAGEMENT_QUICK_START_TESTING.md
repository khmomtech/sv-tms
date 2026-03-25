> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🚀 Banner Management - Quick Start Testing Guide

**Last Updated**: 2025-01-XX  
**Estimated Testing Time**: 15 minutes

---

## 🎯 Prerequisites

MySQL running (Docker or local)  
Backend running on port 8080  
Angular dev server running on port 4200  
Flutter app deployed on simulator/device  
Admin account credentials  
Driver account credentials

---

## ⚡ Quick Test (5 minutes)

### Step 1: Start Backend (30 seconds)
```bash
cd tms-backend
./mvnw spring-boot:run
```
Wait for: `Started DriverAppApplication in X seconds`

### Step 2: Verify Database Migration (30 seconds)
```bash
# Check if banners table exists
mysql -u root -p svlogistics_tms_db -e "DESCRIBE banners;"

# Check sample data
mysql -u root -p svlogistics_tms_db -e "SELECT id, title, category, active FROM banners;"
```

**Expected Output**:
```
+----+----------------+--------------+--------+
| id | title          | category     | active |
+----+----------------+--------------+--------+
|  1 | Welcome Driver | announcement |      1 |
|  2 | Safety First   | safety       |      1 |
|  3 | Earn More      | promotion    |      1 |
+----+----------------+--------------+--------+
```

### Step 3: Test Driver API (1 minute)
```bash
# Get access token (replace with your login endpoint)
TOKEN="your_driver_token_here"

# Fetch active banners
curl -X GET "http://localhost:8080/api/driver/banners/active" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Expected Response**:
```json
{
  "success": true,
  "message": "Banners retrieved successfully",
  "data": [
    {
      "id": 1,
      "title": "Welcome Driver",
      "titleKh": "សូមស្វាគមន៍ អ្នកបើកបរ",
      "subtitle": "Ready to make deliveries today",
      "category": "announcement",
      "active": true,
      "viewCount": 1,
      "clickCount": 0
    }
  ]
}
```

### Step 4: Test Admin Panel (2 minutes)
1. Open browser: `http://localhost:4200`
2. Login with admin credentials
3. Navigate to **Banner Management** (sidebar > Administration > Banner Management)
4. Verify you see 3 default banners
5. Click **Create Banner** button
6. Fill form:
   - Title: "Test Banner"
   - Subtitle: "Testing banner management"
   - Category: "Announcement"
   - Active: ✓
7. Click **Save**
8. Verify new banner appears in grid

### Step 5: Test Flutter App (1 minute)
1. Launch driver app on simulator
2. Login as driver
3. Open dashboard
4. **Verify carousel shows banners from API** (should see 4 banners now including "Test Banner")
5. Tap on a banner
6. Check console log: `Banner X tapped: Test Banner`

---

## 🧪 Full Test Suite (15 minutes)

### Test 1: Create Banner with Image (3 minutes)
1. In admin panel, click **Create Banner**
2. Fill form:
   ```
   Title (EN): Summer Promotion
   Title (KH): ការផ្តល់ជូនរដូវក្តៅ
   Subtitle (EN): 20% bonus on all trips
   Subtitle (KH): ប្រាក់រង្វាន់ 20% សម្រាប់ការធ្វើជើងដឹកទាំងអស់
   Category: Promotion
   Start Date: Today
   End Date: Tomorrow
   Display Order: 1
   Active: ✓
   ```
3. Click **Select Image** → Choose image from gallery
4. Click **Save**
5. **Verify**: New banner appears first in admin grid (displayOrder=1)

### Test 2: Verify Flutter Display (2 minutes)
1. **Pull to refresh** driver dashboard (or restart app)
2. **Verify**: "Summer Promotion" banner appears in carousel
3. Swipe carousel → should see new banner
4. **Switch language**: Settings → Language → ខ្មែរ
5. **Verify**: Carousel shows "ការផ្តល់ជូនរដូវក្តៅ" (Khmer title)

### Test 3: Click Tracking (2 minutes)
1. Tap "Summer Promotion" banner in carousel
2. Check Flutter console: `Banner X clicked`
3. Go to admin panel
4. **Verify**: Banner card shows `Clicks: 1`, `CTR: Y%`
5. Tap same banner again in driver app
6. Refresh admin panel
7. **Verify**: `Clicks: 2`, CTR updated

### Test 4: Category Filtering (2 minutes)
1. In admin panel, change category filter to **Promotion**
2. **Verify**: Only "Summer Promotion" and "Earn More" banners visible
3. Change filter to **Safety**
4. **Verify**: Only "Safety First" banner visible
5. Change filter to **All**
6. **Verify**: All banners visible again

### Test 5: Edit Banner (2 minutes)
1. Click **Edit** on "Summer Promotion" banner
2. Change:
   ```
   Subtitle (EN): 30% bonus on all trips (updated)
   ```
3. Click **Save**
4. **Verify**: Grid shows updated subtitle
5. Go to driver app → pull to refresh
6. **Verify**: Carousel shows "30% bonus on all trips"

### Test 6: Toggle Active Status (1 minute)
1. Click **Toggle Status** on "Summer Promotion" banner
2. **Verify**: Badge changes to "Inactive" (red)
3. Go to driver app → pull to refresh
4. **Verify**: "Summer Promotion" banner NO LONGER appears in carousel
5. Go back to admin → toggle status again
6. **Verify**: Badge changes to "Active" (green)
7. Refresh driver app
8. **Verify**: Banner reappears

### Test 7: Date Range Scheduling (2 minutes)
1. Edit "Summer Promotion" banner
2. Set:
   ```
   Start Date: Tomorrow (future date)
   End Date: Next week
   ```
3. Click **Save**
4. Go to driver app → pull to refresh
5. **Verify**: Banner does NOT appear (start date is in future)
6. Edit banner again → set Start Date to Yesterday
7. Save and refresh driver app
8. **Verify**: Banner reappears

### Test 8: Delete Banner (1 minute)
1. Click **Delete** on "Test Banner"
2. Confirm deletion in dialog
3. **Verify**: Banner removed from grid
4. Refresh driver app
5. **Verify**: Banner no longer in carousel

---

## 🔍 Advanced Testing

### Test API Endpoints Directly

#### 1. Get All Banners (Admin)
```bash
curl -X GET "http://localhost:8080/api/admin/banners" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json"
```

#### 2. Get Banner by ID
```bash
curl -X GET "http://localhost:8080/api/admin/banners/1" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

#### 3. Create Banner
```bash
curl -X POST "http://localhost:8080/api/admin/banners" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "API Test Banner",
    "subtitle": "Created via API",
    "category": "general",
    "displayOrder": 10,
    "active": true
  }'
```

#### 4. Update Banner
```bash
curl -X PUT "http://localhost:8080/api/admin/banners/1" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Welcome",
    "subtitle": "Modified subtitle",
    "category": "announcement",
    "displayOrder": 1,
    "active": true
  }'
```

#### 5. Delete Banner
```bash
curl -X DELETE "http://localhost:8080/api/admin/banners/4" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

#### 6. Track Banner Click (Driver)
```bash
curl -X POST "http://localhost:8080/api/driver/banners/1/click" \
  -H "Authorization: Bearer $DRIVER_TOKEN" \
  -H "Content-Type: application/json"
```

---

## Success Criteria

| Test | Expected Result | Status |
|------|-----------------|--------|
| Database migration | `banners` table exists with 3 rows | ☐ |
| Backend API - Get active banners | Returns JSON with success=true | ☐ |
| Backend API - Track click | Returns success, increments click_count | ☐ |
| Admin Panel - Access route | `/banners` loads without errors | ☐ |
| Admin Panel - Create banner | New banner appears in grid | ☐ |
| Admin Panel - Edit banner | Changes saved and reflected | ☐ |
| Admin Panel - Delete banner | Banner removed from database | ☐ |
| Admin Panel - Filter by category | Only matching banners shown | ☐ |
| Flutter - Fetch banners | Carousel displays API data | ☐ |
| Flutter - Click tracking | Console logs click, API increments count | ☐ |
| Flutter - Localization | Khmer titles shown when locale=km | ☐ |
| Flutter - Error handling | Shows default carousel on API failure | ☐ |

---

## 🐛 Common Issues & Fixes

### Issue 1: Banners table not found
**Cause**: Migration not run  
**Fix**:
```bash
cd tms-backend
./mvnw flyway:migrate
# or
./mvnw spring-boot:run (will auto-migrate)
```

### Issue 2: 401 Unauthorized in driver app
**Cause**: Invalid or expired token  
**Fix**: Re-login in driver app

### Issue 3: Admin panel shows empty grid
**Cause**: API call failed or no banners in database  
**Fix**:
1. Check browser console for errors
2. Verify backend is running: `curl http://localhost:8080/actuator/health`
3. Insert sample data:
   ```sql
   INSERT INTO banners (title, category, display_order, active, created_at, updated_at)
   VALUES ('Test', 'general', 1, 1, NOW(), NOW());
   ```

### Issue 4: Flutter carousel shows default banners only
**Cause**: API request failed or returned empty array  
**Fix**:
1. Check Flutter console for error logs
2. Verify API URL in `ApiConstants.baseUrl`
3. Test API manually: `curl http://localhost:8080/api/driver/banners/active -H "Authorization: Bearer $TOKEN"`

### Issue 5: Images not loading in Flutter
**Cause**: Image URL incorrect or CORS issue  
**Fix**:
1. Verify `imageUrl` field in database contains valid path (e.g., `/uploads/banners/image.jpg`)
2. Check `ApiConstants.imageUrl` points to correct host
3. Test image URL in browser: `http://localhost:8080/uploads/banners/image.jpg`

### Issue 6: Click tracking not working
**Cause**: API endpoint not called or token invalid  
**Fix**:
1. Check Flutter console for errors when tapping banner
2. Verify `onTap` callback is wired in `CarouselItem`
3. Test endpoint manually:
   ```bash
   curl -X POST "http://localhost:8080/api/driver/banners/1/click" \
     -H "Authorization: Bearer $TOKEN"
   ```

---

## 📊 Performance Benchmarks

| Metric | Target | Actual |
|--------|--------|--------|
| API Response Time (GET /active) | < 200ms | ⏱️ |
| Flutter Carousel Load Time | < 1s | ⏱️ |
| Admin Panel Load Time | < 2s | ⏱️ |
| Database Query Time | < 50ms | ⏱️ |

---

## 🎓 Learning Resources

- **Spring Boot Flyway**: https://flywaydb.org/documentation/usage/gradle
- **Angular Standalone Components**: https://angular.io/guide/standalone-components
- **Flutter FutureBuilder**: https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html
- **Carousel Slider**: https://pub.dev/packages/carousel_slider

---

## Testing Checklist

Print this and check off as you test:

**Backend**
- [ ] Database migration applied
- [ ] Sample data inserted
- [ ] GET /api/driver/banners/active returns 3 banners
- [ ] GET /api/driver/banners/category/safety returns 1 banner
- [ ] POST /api/driver/banners/1/click increments count
- [ ] GET /api/admin/banners returns all banners
- [ ] POST /api/admin/banners creates new banner
- [ ] PUT /api/admin/banners/1 updates banner
- [ ] DELETE /api/admin/banners/X deletes banner

**Admin Panel**
- [ ] Route /banners accessible
- [ ] Grid displays all banners
- [ ] Create form validates input
- [ ] Image picker works
- [ ] Edit form pre-fills data
- [ ] Delete confirmation dialog shows
- [ ] Category filter works
- [ ] Analytics display (views, clicks, CTR)

**Flutter App**
- [ ] Carousel loads on dashboard
- [ ] Displays banners from API
- [ ] Shows fallback on error
- [ ] Khmer titles shown when locale=km
- [ ] Click tracking works
- [ ] Gradient colors match categories
- [ ] Images load from server

**Integration**
- [ ] Admin creates → Driver sees (after refresh)
- [ ] Admin toggles active → Driver carousel updates
- [ ] Driver clicks → Admin analytics update
- [ ] Admin sets date range → Driver respects schedule

---

**End of Quick Start Guide** 🎉
