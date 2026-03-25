> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Order → Delivery User Guide

Purpose: concise runbook for users (Admin/Dispatcher, Driver, Customer) to understand and operate the end-to-end Order → Completed Delivery flows.

Audience
- Admin / Dispatcher: create/assign orders, convert bookings, monitor progress
- Driver: receive assignments, update status, upload POD
- Customer: create bookings or track orders

Quick Concepts
- Booking-first: Customer creates a booking that is later converted to a `TransportOrder` by admin/dispatcher.
- Order-first: Admin or import creates a `TransportOrder` directly (used by 3PL, bulk imports, or manual admin entries).
- TransportOrder: the canonical entity containing stops, items, and schedule used by dispatch and drivers.
- Dispatch: the assignment of a `TransportOrder` to a driver/vehicle (may include `loadingTeam`).
- Messaging: realtime via STOMP/SockJS (`/topic/*`, `/user/queue/*`), push via FCM.

Canonical Status Flow (recommended)
- `CREATED` → `ASSIGNED` → `ACCEPTED` / `DRIVER_CONFIRMED` → `EN_ROUTE` → `PICKED_UP` / `LOADED` → `IN_TRANSIT` → `DELIVERED` → `COMPLETED`
- Extra statuses: `SELF_PICKUP`, `LOADED_BY_TEAM`, `FAILED_DELIVERY`, `RETURNED`, `CANCELLED`.

Start Points
- Booking-first: Customer → `POST /api/customer/{id}/bookings` → booking persisted → admin converts (`convertToOrder`) → `TransportOrder` created → dispatch.
- Order-first: Admin → `POST /api/admin/transportorders` (or import) → `TransportOrder` persisted → dispatch.

Key Endpoints (reference)
- Customer create booking: `POST /api/customer/{customerId}/bookings`
- Admin create transport order: `POST /api/admin/transportorders`
- Booking → order conversion: `POST /api/admin/bookings/{id}/convert` (see `BookingController.convertToOrder`)
- List / get transport orders (admin): `GET /api/admin/transportorders`, `GET /api/admin/transportorders/{id}`
- Customer order list: `GET /api/customer/{customerId}/orders` (CustomerOrdersController)
- Assign booking/order (dispatch): `POST /api/admin/bookings/{id}/assign` or dispatch API endpoints
- Driver status updates: `PATCH /api/driver/{driverId}/status`
- Upload POD/media: `POST /api/uploads`
- Auth: `POST /api/auth/login`, `POST /api/auth/refresh`
- Public tracking: `GET /api/public/tracking?ref={ref}`

No-Driver / G-team Cases (KHB)
- Use a `bookingType` or `origin` flag: `SELF_PICKUP` or `NO_DRIVER` to skip driver dispatch.
- Optionally assign a `loadingTeam` entity and publish loading assignments to a loading-team STOMP topic.
- Statuses for these flows: `CREATED` → `READY_FOR_PICKUP` → `PICKED_UP` → `COMPLETED`.

Data & Audit Recommendations
- Add `origin` on `TransportOrder` (values: `BOOKING`, `MANUAL`, `BULK_IMPORT`, `API`) and `sourceReference` (bookingId / external ref).
- Enforce same validation rules on direct order creation as on booking→order conversion (addresses, stops, weights, billing customer data).
- Idempotency: use `sourceReference` to avoid duplicate orders on retries/imports.

Dispatch & Notifications
- Dispatch should accept both `bookingId` and `transportOrderId` as source.
- STOMP connect must include token in headers or query param; driver subscribes to `/user/queue/assignments`.
- Backend should send FCM push for assignment in addition to STOMP for offline drivers.

Smoke Test (quick)
1. Start stack:
```bash
docker compose -f docker-compose.dev.yml up --build -d
```
2. Get tokens (replace creds):
```bash
curl -s -X POST http://localhost:8080/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"test_customer","password":"password"}' | jq -r '.accessToken'
```
3. Create booking (customer):
```bash
TOKEN=<token>
curl -s -X POST "http://localhost:8080/api/customer/123/bookings" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"pickupAddress":"A","deliveryAddress":"B","items":[{"description":"pallet","qty":2}],"bookingType":"STANDARD"}' | jq
```
4. Convert/assign (admin):
```bash
ADMIN_TOKEN=<admin_token>
# convert booking to order (if needed)
curl -s -X POST "http://localhost:8080/api/admin/bookings/BOOKING_ID/convert" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
# assign
curl -s -X POST "http://localhost:8080/api/admin/bookings/BOOKING_ID/assign" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/json" \
  -d '{"driverId":987,"vehicleId":55}'
```
5. Simulate driver status updates:
```bash
DRIVER_TOKEN=<driver_token>
curl -s -X PATCH "http://localhost:8080/api/driver/987/status" \
  -H "Authorization: Bearer $DRIVER_TOKEN" -H "Content-Type: application/json" \
  -d '{"bookingId":"BOOKING_ID","status":"ACCEPTED"}'
# then EN_ROUTE, PICKED_UP, DELIVERED
```
6. Upload POD:
```bash
curl -s -X POST "http://localhost:8080/api/uploads" \
  -H "Authorization: Bearer $DRIVER_TOKEN" \
  -F "file=@/path/to/signature.jpg" \
  -F "bookingId=BOOKING_ID"
```
7. Verify final status:
```bash
curl -s -X GET "http://localhost:8080/api/customer/123/bookings/BOOKING_ID" -H "Authorization: Bearer $TOKEN" | jq '.status'
```

Troubleshooting
- No STOMP messages: confirm token passed at connect, check `/user/queue/*` subscription, verify backend publishes to that user queue.
- Driver not notified: check FCM logs and retry/backoff on push.
- Endpoint boundary problems: ensure admin UI uses `/api/admin/*`, driver uses `/api/driver/*`, customer uses `/api/customer/{id}/*` — avoid cross-contamination.
- MapStruct / Lombok changes: run `./mvnw clean package` to regenerate annotation-processor outputs.

Testing & CI Recommendations
- Add integration test: "create TransportOrder (manual) → dispatch → driver accept → deliver" using H2 or docker MySQL in CI.
- Add e2e Playwright test for Admin create → assign → visible driver assignment (UI+mock STOMP).
- Add a smoke script (curl + STOMP client) into `tools/` and include in `README`.

Next steps / Contacts
- If you want, I can: create the smoke scripts in the repo, or add the `origin` field + DB migration scaffold, or scaffold the integration test. Tell me which to do next.

---
_Last updated: 2026-01-15_
