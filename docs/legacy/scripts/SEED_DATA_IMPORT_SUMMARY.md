> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🚀 Complete Driver & Vehicle Seed Data - Import Summary

## ✅ Import Status: **SUCCESSFUL WITH VERIFIED LOGIN**

**Import Date:** January 23, 2026  
**Database:** svlogistics_tms_db  
**Seed File:** `data/import/seed_drivers_vehicles_final.sql`  
**Login Test:** ✅ PASSED - Driver login verified with JWT token generation

---

## 📊 Import Statistics

| Category                   | Count | ID Range             |
| -------------------------- | ----- | -------------------- |
| **Users (Login Accounts)** | 30    | 1001-1030            |
| **Drivers**                | 30    | 2001-2030            |
| **Vehicles**               | 30    | 3001-3030            |
| **Permanent Assignments**  | 30    | N/A                  |
| **Role Assignments**       | 30    | All have DRIVER role |

---

## 🔑 Login Credentials

### Universal Password

**All drivers use the same password:** `123456`

### Username Format

Username = Phone number **without spaces**

### Sample Credentials

| Driver Name | Phone        | Login Username | Password | License | Assigned Vehicle |
| ----------- | ------------ | -------------- | -------- | ------- | ---------------- |
| Sok Dara    | 012 345 6789 | `0123456789`   | 123456   | A       | PP 1A-1234       |
| Chan Sophea | 098 765 4321 | `0987654321`   | 123456   | B       | PP 1B-1234       |
| Lim Kosal   | 011 223 3445 | `0112233445`   | 123456   | C       | PP 1C-1234       |
| Kim Sovan   | 099 887 7665 | `0998877665`   | 123456   | A       | SR 2B-5678       |
| Heng Virak  | 015 678 9012 | `0156789012`   | 123456   | B       | KC 2B-5678       |
| Chhay Mony  | 012 345 6780 | `0123456780`   | 123456   | C       | KS 2C-5678       |
| Pov Ratana  | 098 765 4320 | `0987654320`   | 123456   | A       | BP 3C-9012       |
| San Thida   | 011 223 3440 | `0112233440`   | 123456   | C       | SR 3C-9012       |
| Oun Chanthy | 099 887 7660 | `0998877660`   | 123456   | B       | PP 3B-9012       |
| Keo Piseth  | 015 678 9010 | `0156789010`   | 123456   | A       | PP 4A-1111       |

---

## 👥 Driver Details

### License Class Distribution

- **Class A (Heavy Trucks):** 10 drivers
- **Class B (Medium Trucks):** 10 drivers
- **Class C (Light Vehicles):** 10 drivers

### Driver Batches

#### Batch 1: Core Fleet (2001-2010)

Original seed data with realistic Cambodian context.

#### Batch 2: CSV Imported (2011-2020)

Data imported from `drivers_import.csv` with normalized phone numbers.

#### Batch 3: Additional (2021-2030)

Extended fleet for testing and scalability.

### Driver Status Distribution

- **IDLE:** Majority (available for dispatch)
- **ONLINE:** Active drivers
- **OFFLINE:** Off-duty drivers

### Driver Zones

- Phnom Penh
- Siem Reap
- Battambang
- Kampong Cham
- Kampong Speu
- Zone A / Zone B

### Performance Metrics

All drivers have realistic performance scores:

- **Performance Score:** 78-95 (out of 100)
- **On-Time Percent:** 81-99%
- **Safety Score:** Excellent / Good
- **Leaderboard Rank:** 1-30

---

## 🚛 Vehicle Details

### Vehicle Type Distribution

| Type              | Size         | Count | License Required |
| ----------------- | ------------ | ----- | ---------------- |
| **Heavy Trucks**  | BIG_TRUCK    | 10    | Class A          |
| **Medium Trucks** | MEDIUM_TRUCK | 10    | Class B          |
| **Vans**          | SMALL_VAN    | 5     | Class C          |
| **Pickup Trucks** | SMALL_VAN    | 5     | Class C          |

### Vehicle Manufacturers

- **HINO** (Ranger 500, Profia 700, Dutro 300)
- **ISUZU** (Giga FVZ/CYZ, NQR 75P, NPR 75L)
- **MITSUBISHI FUSO** (Fighter, Canter FE85, Super Great)
- **TOYOTA** (Hiace, Hilux Revo)
- **HYUNDAI** (Starex)
- **FORD** (Ranger XLT)

### Vehicle Status Distribution

- **AVAILABLE:** Ready for dispatch (majority)
- **IN_USE:** Currently assigned and active
- **MAINTENANCE:** (none in seed data)

### License Plates (Cambodian Format)

- **PP** - Phnom Penh
- **SR** - Siem Reap
- **BP** - Battambang
- **KC** - Kampong Cham
- **KS** - Kampong Speu

---

## 🔗 Driver-Vehicle Assignments

### Assignment Strategy

All 30 drivers have **permanent assignments** to vehicles with **matching license classes**:

- **10 Class A drivers** → 10 Heavy Trucks (BIG_TRUCK)
- **10 Class B drivers** → 10 Medium Trucks (MEDIUM_TRUCK)
- **10 Class C drivers** → 10 Light Vehicles (VAN/SMALL_VAN)

### Assignment Validation

✅ **All assignments are valid** - License classes match vehicle requirements

### Assignment Details

- **Assigned By:** SYSTEM_SEED
- **Assigned At:** 2026-01-15 08:00:00
- **Reason:** Descriptive assignment context (e.g., "Core fleet - Sok Dara on HINO Ranger")

---

## 🧪 Testing Guide

### 1. Test Driver Login ✅ **VERIFIED**

```bash
# Using curl
curl -X POST http://localhost:8080/api/auth/driver/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "0123456789",
    "password": "123456",
    "deviceId": "test-device-001"
  }'

# Using httpie
http POST http://localhost:8080/api/auth/driver/login \
  username=0123456789 \
  password=123456 \
  deviceId=test-device-001
```

**Expected Response:** ✅ Success

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "username": "0123456789",
      "email": "sokdara@svtms.com",
      "roles": ["DRIVER"],
      "driverId": 2001,
      "zone": "Phnom Penh",
      "status": "IDLE"
    },
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiJ9..."
  }
}
```

**Note:** `deviceId` parameter is required for driver login. Use any non-empty string for testing.

### 2. Test Driver List API

```bash
curl -X GET http://localhost:8080/api/admin/drivers \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 3. Test Vehicle List API

```bash
curl -X GET http://localhost:8080/api/admin/vehicles \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Test Assignment Query

```sql
-- Check assignments with license validation
SELECT
    CONCAT(d.first_name, ' ', d.last_name) as driver,
    d.license_class as driver_license,
    v.license_plate,
    v.required_license_class as vehicle_requires,
    CASE
        WHEN d.license_class = v.required_license_class
        THEN '✓ VALID'
        ELSE '✗ MISMATCH'
    END as validation
FROM permanent_assignments pa
JOIN drivers d ON pa.driver_id = d.id
JOIN vehicles v ON pa.vehicle_id = v.id
WHERE d.id BETWEEN 2001 AND 2030;
```

---

## 📁 File Locations

| File                  | Location                                         | Purpose                               |
| --------------------- | ------------------------------------------------ | ------------------------------------- |
| **Final Seed SQL**    | `data/import/seed_drivers_vehicles_final.sql`    | Production-ready seed data (30+30+30) |
| **Legacy Seed SQL**   | `data/import/seed_drivers_vehicles_users.sql`    | Initial version (10+10+10)            |
| **Extended Seed SQL** | `data/import/seed_complete_drivers_vehicles.sql` | Schema mismatch version (not used)    |
| **CSV Import**        | `data/import/drivers_import.csv`                 | Original 10 drivers from Excel        |

---

## 🔧 Re-Import Instructions

### Full Re-Import

```bash
docker exec -i svtms-mysql mysql -u root -prootpass svlogistics_tms_db \
  < data/import/seed_drivers_vehicles_final.sql
```

### Clean and Re-Import

```sql
-- WARNING: This deletes all seed data!
DELETE FROM permanent_assignments WHERE driver_id BETWEEN 2001 AND 2030;
DELETE FROM user_roles WHERE user_id BETWEEN 1001 AND 1030;
DELETE FROM drivers WHERE id BETWEEN 2001 AND 2030;
DELETE FROM vehicles WHERE id BETWEEN 3001 AND 3030;
DELETE FROM users WHERE id BETWEEN 1001 AND 1030;

-- Then re-import
SOURCE /path/to/seed_drivers_vehicles_final.sql;
```

---

## ✨ Key Features

### 1. Realistic Cambodian Context

- Authentic Cambodian names (Sok, Chan, Lim, etc.)
- Real license plate formats (PP 1A-1234, SR 2B-5678)
- Common Cambodian zones and cities

### 2. Complete User Accounts

- All drivers have user accounts
- BCrypt password hashing
- DRIVER role assignment
- Email addresses for notifications

### 3. Performance Tracking

- Performance scores (78-95)
- Safety ratings (Good/Excellent)
- On-time percentages (81-99%)
- Leaderboard rankings (1-30)

### 4. License Validation

- Drivers matched to compatible vehicles
- Class A → Heavy trucks
- Class B → Medium trucks
- Class C → Light vehicles/vans

### 5. Permanent Assignments

- One-to-one driver-vehicle mapping
- Assignment tracking (assigned_by, assigned_at)
- Reason for each assignment
- Ready for dispatch workflows

---

## 🎯 Next Steps

### 1. Mobile App Testing

Test driver login in Flutter driver app:

```dart
await AuthService.login(
  username: '0123456789',
  password: '123456',
);
```

### 2. Bulk Order Import Testing

Use the seed drivers/vehicles to test bulk order imports:

```bash
# Upload Excel with references to:
# - Driver phones: 012 345 6789, 098 765 4321, etc.
# - Vehicle plates: PP 1A-1234, SR 2B-5678, etc.
```

### 3. Dispatch Testing

Assign orders to drivers with assigned vehicles.

### 4. Performance Dashboard

View leaderboard with 30 drivers and their scores.

### 5. Fleet Management

Test vehicle assignment/unassignment workflows.

---

## 📝 Notes

- **Password Security:** All passwords are `123456` for testing only. Change for production!
- **Phone Format:** Usernames use phone without spaces (`0123456789`), but driver records keep formatted phone (`012 345 6789`)
- **CSV Integration:** Batch 2 (2011-2020) uses data from `drivers_import.csv` with normalized `+855` format
- **Extensibility:** ID ranges allow for additional seed data (e.g., 2031-2050 for more drivers)

---

## 🐛 Troubleshooting

### Issue: Login fails with "Invalid credentials"

**Solution:** Verify password is exactly `123456` and username matches phone without spaces

### Issue: Driver not found in mobile app

**Solution:** Check if driver status is ONLINE or IDLE (not OFFLINE)

### Issue: Vehicle assignment mismatch

**Solution:** Run license validation query to check compatibility

### Issue: Import fails with duplicate key error

**Solution:** Run clean script first or use `ON DUPLICATE KEY UPDATE` (already in SQL)

---

## ✅ Validation Checklist

- [x] 30 users created with DRIVER role
- [x] 30 drivers with unique phones
- [x] 30 vehicles with unique plates
- [x] 30 permanent assignments
- [x] All passwords are `123456`
- [x] All usernames match phone format
- [x] License classes match vehicle requirements
- [x] Performance metrics realistic
- [x] Cambodian context accurate
- [x] No orphaned records
- [x] No foreign key violations

---

**🎉 Import Complete! Your database is now populated with 30 production-ready drivers, vehicles, and user accounts for comprehensive testing.**
