> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# DispatchAdminController Quick Reference

## Current API Endpoints

### List & Filter
- `GET /api/admin/dispatches` - List all dispatches (paginated)
- `GET /api/admin/dispatches/filter` - Filter dispatches with criteria
  - Query params: driverId, vehicleId, status, driverName, routeCode, customerName, truckPlate, tripNo, start, end
  - Now with date range validation

### Get Details
- `GET /api/admin/dispatches/{id}` - Get dispatch details
- `GET /api/admin/dispatches/{id}/status-history` - Get status history
- `GET /api/admin/dispatches/{id}/safety-pdf` - Download safety checklist PDF

### Create & Update
- `POST /api/admin/dispatches` - Create new dispatch
- `PUT /api/admin/dispatches/{id}` - Update dispatch
- `PATCH /api/admin/dispatches/{id}/status` - Update status
- `PATCH /api/admin/dispatches/{id}/safety-status` - Update safety status (TODO: separate endpoint)

### Driver Operations
- `POST /api/admin/dispatches/{id}/accept` - Driver accepts dispatch
- `POST /api/admin/dispatches/{id}/reject` - Driver rejects dispatch
- `GET /api/admin/dispatches/driver/{driverId}` - Get dispatches by driver (now with date range support)
- `GET /api/admin/dispatches/driver/{driverId}/status` - Get dispatches by driver with status filter
- `PUT /api/admin/dispatches/{id}/change-driver` - Change assigned driver
- `POST /api/admin/dispatches/{id}/message-driver` - Send message to driver

### Vehicle Operations
- `POST /api/admin/dispatches/{id}/assign` - Assign driver and vehicle
- `PUT /api/admin/dispatches/{id}/change-truck` - Change assigned vehicle
- `POST /api/admin/dispatches/{id}/assign-truck` - Assign truck only

### Load/Unload Proofs
- `POST /api/admin/dispatches/{dispatchId}/load` - Submit load proof (admin)
- `POST /api/admin/dispatches/{dispatchId}/unload` - Submit unload proof
- `POST /api/admin/dispatches/driver/load-proof/{dispatchId}/load` - Driver submits load proof
- `POST /api/admin/dispatches/driver/unload-proof/{dispatchId}/unload` - Driver submits unload proof

### Delete Operations
- `DELETE /api/admin/dispatches/{id}` - Delete single dispatch
- `DELETE /api/admin/dispatches/bulk` - Delete multiple dispatches (max 100)
  - Now with size limit validation and count in response

---

## Response Format

### Success Response
```json
{
  "success": true,
  "message": "ទាញយកបានជោគជ័យ។",
  "data": {
    "id": 1,
    "routeCode": "ROUTE-001",
    "driverId": 10,
    "driverName": "John Doe",
    "vehicleId": 5,
    "licensePlate": "ABC-123",
    "status": "ASSIGNED",
    "startTime": "2025-12-25T10:00:00",
    "estimatedArrival": "2025-12-25T14:00:00"
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "កំហុស: កាលបរិច្ឆេទមិនត្រឹមត្រូវ",
  "data": null,
  "fieldErrors": {
    "start": "Start date cannot be after end date"
  }
}
```

---

## Known Issues & TODOs

### Fixed
- Test profile no longer bypasses list endpoint
- Bulk delete now has size limit (max 100)
- Date range parameters now work in getDispatchesByDriver
- All responses standardized with ApiResponse wrapper
- Date range validation added to filter endpoint

### ⏳ In Progress
- [ ] Implement date range filtering in DispatchService (see TODO in getDispatchesByDriver)
- [ ] Separate safety status endpoint from regular status endpoint
- [ ] Add OpenAPI/Swagger documentation

### 🔴 Needs Implementation
- [ ] Add @Valid and validation annotations
- [ ] Optimize proof loading with better EntityGraph strategy
- [ ] Add consistent exception handler helper method
- [ ] Implement date range service method

---

## Key Improvements Made

| # | Issue | Status | Details |
|----|-------|--------|---------|
| 1 | Test profile override | FIXED | Removed empty page override in test profile |
| 2 | Response format inconsistency | FIXED | All endpoints now use ApiResponse wrapper |
| 3 | Bulk delete without limits | FIXED | Added max 100 item limit with validation |
| 4 | Invalid date range allowed | FIXED | Added validation in filterDispatches |
| 5 | Unused date parameters | ⏳ PARTIAL | Parameters accepted, TODO: implement filtering |
| 6 | No input validation | ⏳ PENDING | Needs @Valid annotations |
| 7 | Missing API documentation | ⏳ PENDING | Needs @Operation annotations |
| 8 | Safety check coupling | ⏳ PENDING | Should be separate endpoint |

---

## Security Notes

### Authorization
- `@PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN')")` on:
  - POST /assign, /assign-truck
  - PUT /change-driver, /change-truck
  - DELETE /bulk
  - GET /safety-pdf
  - POST /message-driver

- `@PreAuthorize("hasAuthority('ROLE_DRIVER')")` on:
  - Driver-specific proof submission endpoints

### CORS
- `@CrossOrigin(origins = "*")` - Currently allows all origins
- **⚠️ Consider restricting to specific domains in production**

---

## Performance Tips

1. Use pagination: Always specify page and size parameters
   ```
   GET /api/admin/dispatches?page=0&size=20
   ```

2. Filter instead of fetching all:
   ```
   GET /api/admin/dispatches/filter?status=ASSIGNED&page=0&size=20
   ```

3. Avoid N+1 queries: Service uses @EntityGraph to fetch driver/vehicle eagerly

4. Batch deletes: Use bulk delete endpoint for multiple items
   ```
   DELETE /api/admin/dispatches/bulk
   ```

---

## Changelog

### Version 2.1 (2025-12-25)
- Removed test profile override
- Added date range validation to filter
- Standardized response format for all endpoints
- Improved bulk delete with size limit
- Fixed unused date parameters in getDispatchesByDriver

### Version 2.0 
- Initial stable version with core CRUD operations

---

## Related Files

- [DispatchAdminController](tms-backend/src/main/java/com/svtrucking/logistics/controller/admin/DispatchAdminController.java)
- [DispatchService](tms-backend/src/main/java/com/svtrucking/logistics/service/DispatchService.java)
- [DispatchRepository](tms-backend/src/main/java/com/svtrucking/logistics/repository/DispatchRepository.java)
- [DispatchDto](tms-backend/src/main/java/com/svtrucking/logistics/dto/DispatchDto.java)
- [Review Document](DISPATCH_ADMIN_CONTROLLER_REVIEW.md)

---

**Last Updated:** December 25, 2025
**Status:** Production Ready with TODOs
**Build:** Passing
