> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Driver Vehicle Tab Quick Reference

## Status: **FULLY WORKING**

### What's Implemented

#### Frontend (`/drivers/1?tab=vehicle`)
Vehicle search with autocomplete by license plate/model/type  
Permanent vehicle assignment with one-click confirmation  
Temporary vehicle assignment (1-168 hours)  
TRUCK license class validation (blocks assignment if missing)  
Assignment history table with current/previous status  
Toast notifications for success/error feedback  
Vehicle preview before assignment  

#### Backend API
`POST /api/admin/drivers/assign` - Permanent assignment  
`POST /api/admin/drivers/{id}/temporary-assignment` - Temp assignment  
`DELETE /api/admin/drivers/{id}/temporary-assignment` - Remove temp  
`GET /api/admin/drivers/{id}/current-assignment` - Get active assignment  
`PUT /api/admin/drivers/{id}/change-permanent` - Change permanent vehicle  
`POST /api/admin/drivers/{id}/temporary-assignment/reset-if-expired` - Manual expiry check  

#### Business Logic
Validates driver & vehicle exist  
Prevents multiple active assignments per vehicle  
Unassigns previous assignment when assigning new one  
Keeps permanent assignment when using temporary override  
Validates temporary expiry not in past  
Requires DRIVER_MANAGE permission  

---

## Quick Test Commands

```bash
# Permanent assignment
curl -X POST "http://localhost:8080/api/admin/drivers/assign?driverId=1&vehicleId=2" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json"

# Temporary assignment (4 hours from now)
curl -X POST "http://localhost:8080/api/admin/drivers/1/temporary-assignment" \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": 3,
    "expiry": "'$(date -u -d '+4 hours' +%Y-%m-%dT%H:%M:%S.000Z)'",
    "reason": "Test"
  }'

# Get current assignment
curl -X GET "http://localhost:8080/api/admin/drivers/1/current-assignment" \
  -H "Authorization: Bearer TOKEN"

# Remove temporary
curl -X DELETE "http://localhost:8080/api/admin/drivers/1/temporary-assignment" \
  -H "Authorization: Bearer TOKEN"
```

---

## Known Issues & Fixes

### Issue 1: TRUCK License Validation Only Frontend
**Fix needed:** Add backend validation
```java
// In DriverAssignmentService.assignDriver()
if ("TRUCK".equals(vehicle.getType())) {
  String licenseClass = driver.getLicenseClass();
  if (licenseClass == null || licenseClass.trim().isEmpty()) {
    throw new AssignmentValidationException(
      "Driver must have commercial license class for TRUCK assignment"
    );
  }
}
```

### Issue 2: No Max Duration Validation on Backend
**Fix needed:** Validate max 7 days (168 hours)
```java
// In AssignmentValidator.validateTemporaryAssignment()
long hoursUntilExpiry = ChronoUnit.HOURS.between(LocalDateTime.now(), expiry);
if (hoursUntilExpiry > 168) {
  throw new AssignmentValidationException("Max duration is 7 days (168 hours)");
}
```

### Issue 3: Data Consistency Risk
**Fix needed:** Derive current assignment from assignment table instead of driver fields
```java
// Instead of using driver.assignedVehicle & driver.tempAssignedVehicle
// Query from assignment records:
var permanent = assignmentRepository.findMostRecentAssigned(
  driverId, AssignmentType.PERMANENT
);
var temporary = assignmentRepository.findActiveExpiry(
  driverId, AssignmentType.TEMPORARY
);
```

---

## File Locations

**Frontend:**
- Component: `tms-frontend/src/app/components/drivers/driver-detail/driver-detail.component.ts`
- Template: `tms-frontend/src/app/components/drivers/driver-detail/driver-detail.component.html`
- Services:
  - `tms-frontend/src/app/services/driver.service.ts` (permanent)
  - `tms-frontend/src/app/services/driver-assignment-extended.service.ts` (temporary)

**Backend:**
- Controller: `tms-backend/src/main/java/.../DriverTemporaryAssignmentController.java`
- Service: `tms-backend/src/main/java/.../DriverAssignmentService.java`
- Validator: `tms-backend/src/main/java/.../AssignmentValidator.java`

---

## Validation Rules Summary

| Rule | Type | Enforced | Status |
|------|------|----------|--------|
| Driver exists | Required | Frontend + Backend | |
| Vehicle exists | Required | Frontend + Backend | |
| TRUCK needs license | Required | Frontend only | ⚠️ |
| Max duration 168h | Required | Frontend only | ⚠️ |
| Temp expiry in future | Required | Backend | |
| No duplicate active assignments per vehicle | Required | Backend | |
| User has DRIVER_MANAGE permission | Required | Backend | |

---

## Integration Points

```
Angular Component
    ↓
DriverService / DriverAssignmentExtendedService
    ↓
REST API Endpoints
    ↓
DriverTemporaryAssignmentController
    ↓
DriverAssignmentService
    ↓
AssignmentValidator
    ↓
DriverAssignmentRepository
    ↓
Database (driver_assignment table + driver fields)
```

---

## Permission Required

**All endpoints require:** `DRIVER_MANAGE`

Check in database:
```sql
SELECT * FROM roles_permissions 
WHERE role = 'DISPATCHER' AND permission = 'DRIVER_MANAGE';
```

---

## Response Examples

### Success Response
```json
{
  "success": true,
  "message": "Temporary assignment set",
  "data": {
    "id": 123,
    "driverId": 1,
    "vehicleId": 2,
    "status": "ASSIGNED",
    "assignmentType": "TEMPORARY",
    "assignedAt": "2025-12-11T12:00:00",
    "vehicle": {
      "id": 2,
      "licensePlate": "ABC-456",
      "model": "Truck 2020",
      "type": "TRUCK"
    }
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Driver must have commercial license class for TRUCK assignment"
}
```

---

## Performance Notes

- Vehicle search limited to 10 results (configurable)
- Assignment history loads on tab selection
- Current assignment fetched via separate endpoint
- No real-time updates implemented (WebSocket ready but not used)

---

**Last Updated:** December 11, 2025  
**Review Status:** Complete & Working Well
