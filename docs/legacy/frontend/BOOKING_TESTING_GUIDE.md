> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Booking System Testing Guide

## System Status

**Backend**: Spring Boot running on `http://localhost:8080`
**Frontend**: Angular running on `http://localhost:4200`
**Database**: MySQL 8.0 running on `localhost:3307`
**Redis**: Running on `localhost:6379`

## Manual Testing Steps

### Step 1: Access the Application
1. Open browser to `http://localhost:4200`
2. If prompted for login, use credentials from application documentation
3. Navigate to "Bookings" → "Create New Booking" or direct URL: `http://localhost:4200/bookings/create`

### Step 2: Test Customer Selection
1. **Expected behavior**:
   - Customer dropdown appears with search field
   - Type a customer name (e.g., "Karate" or first few letters)
   - List filters to matching customers
   - Can select a customer

2. **Verification**:
   - Selected customer displays in `name` field (not `customerName`)
   - Form is ready to proceed to location selection

### Step 3: Test Location Dropdowns (After Customer Selected)
1. **Expected behavior**:
   - After customer selection, "Pickup Location" and "Delivery Location" dropdowns **enable**
   - Start typing in Pickup Location (minimum 2 characters)
   - Dropdown shows matching addresses for **selected customer only**
   - Select a pickup location

2. **Verification**:
   - Pickup address fields auto-fill:
     - `addressLine` → populated with selected address line
     - `city` → populated
     - `province`, `postalCode` → populated if available
   - Contact fields populate if available

3. **Test Location Constraints**:
   - Try typing in location dropdown **before** selecting customer
   - **Expected**: Dropdown should remain disabled
   - Select a customer → dropdown should enable
   - Clear customer selection → dropdown should disable again

### Step 4: Test Location Auto-fill
1. **Expected behavior**:
   - When you select a location from dropdown, form fields auto-populate
   - Same for Delivery Location dropdown

2. **Verify Each Address Section**:
   - **Pickup Address**:
     - `pickupAddress.addressLine` filled
     - `pickupAddress.city` filled
     - `pickupAddress.province` filled (if available)
     - `pickupAddress.postalCode` filled
     - `pickupAddress.companyName` filled (from location name)
   - **Delivery Address**: Same pattern

### Step 5: Fill Remaining Form Fields
1. **Service & Payment**:
   - Select Service Type (e.g., "AIR", "LAND", "SEA")
   - Select Payment Type (e.g., "CASH", "CREDIT", "BANK_TRANSFER")

2. **Dates**:
   - Set Pickup Date (must be today or future)
   - Set Delivery Date (should be >= Pickup Date)

3. **Vehicle & Cargo**:
   - Truck Type (optional): e.g., "BOX_TRUCK", "FLATBED"
   - Capacity (optional): e.g., 5 tons
   - Weight (optional): e.g., 2.5 tons
   - Volume (optional): e.g., 10 CBM
   - Pallets (optional): e.g., 4

4. **Additional Options**:
   - Insurance Required (checkbox)
   - Special Handling Notes (text field)
   - General Notes (text field)

### Step 6: Submit Booking
1. Click **"Create Booking"** button
2. **Expected behavior**:
   - Form submits to `POST /api/admin/bookings`
   - Loading state shown (spinner or disabled button)
   - Server processes request

3. **Success Case**:
   - Page redirects to `/bookings/{id}` (booking detail view)
   - Booking detail page shows created booking with all fields
   - Status shows as "CREATED"

4. **Error Cases** (backend validation):
   - Missing customerId → Error: "customerId is required"
   - Missing pickup address → Error message
   - Invalid date range → Error message
   - If customer not found → Error: "Customer not found"

### Step 7: Verify Database Persistence
1. **Access MySQL database**:
   ```bash
   mysql -u root -proot -h localhost -P 3307 tms_db
   ```

2. **Query bookings table**:
   ```sql
   SELECT id, customer_id, service_type, payment_type, pickup_date, status
   FROM bookings
   ORDER BY id DESC LIMIT 5;
   ```

3. **Verify address references**:
   ```sql
   SELECT b.id, b.customer_id, 
          pa.id as pickup_addr_id, pa.name as pickup_name, pa.address as pickup_addr,
          da.id as delivery_addr_id, da.name as delivery_name, da.address as delivery_addr
   FROM bookings b
   LEFT JOIN order_addresses pa ON b.pickup_address_id = pa.id
   LEFT JOIN order_addresses da ON b.delivery_address_id = da.id
   WHERE b.id = {booking_id};
   ```

### Step 8: Test Address Reuse
1. **Create second booking** with same customer
2. **Pickup Location**: Select a location you already used
3. **Expected behavior**:
   - **No duplicate address created**
   - Second booking should reference same address ID
   - Verify in database: Both bookings have same `pickup_address_id`

---

## API Testing (cURL)

### Get Valid JWT Token
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"YOUR_USERNAME","password":"YOUR_PASSWORD"}'
```

### Create Booking (API Direct Test)
```bash
curl -X POST http://localhost:8080/api/admin/bookings \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": 1,
    "pickupAddress": {
      "addressLine": "123 Main St",
      "city": "Phnom Penh",
      "province": "Phnom Penh",
      "postalCode": "12000",
      "country": "Cambodia",
      "contactName": "John Doe",
      "contactPhone": "+855123456789",
      "companyName": "Karate Shop"
    },
    "deliveryAddress": {
      "addressLine": "456 Oak Ave",
      "city": "Siem Reap",
      "province": "Siem Reap",
      "postalCode": "17000",
      "country": "Cambodia",
      "contactName": "Jane Smith",
      "contactPhone": "+855987654321",
      "companyName": "Distribution Center"
    },
    "serviceType": "LAND",
    "paymentType": "CREDIT",
    "pickupDate": "2026-01-15",
    "deliveryDate": "2026-01-20",
    "truckType": "BOX_TRUCK",
    "capacity": 5,
    "totalWeightTons": 2.5,
    "totalVolumeCbm": 10,
    "palletCount": 4
  }'
```

### List All Bookings
```bash
curl -X GET http://localhost:8080/api/admin/bookings \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

### Get Single Booking
```bash
curl -X GET http://localhost:8080/api/admin/bookings/{id} \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

---

## Test Scenarios

### Scenario 1: Successful Booking Creation
**Objective**: Create a valid booking and verify all fields persist

**Steps**:
1. Select existing customer (e.g., "Karate")
2. Select existing pickup location
3. Select different delivery location
4. Fill service type, payment type, dates
5. Submit form
6. Verify redirect to detail page
7. Check database for persisted data

**Expected Outcome**:
- Booking created with ID
- Customer reference correct
- Both addresses linked
- All fields populated
- Status = "CREATED"

### Scenario 2: Address Reuse
**Objective**: Verify existing addresses are reused, not duplicated

**Steps**:
1. Create first booking with addresses
2. Note address IDs from database
3. Create second booking with same customer and same locations
4. Check database address IDs

**Expected Outcome**:
- No new address records created
- Both bookings reference same address IDs
- Database stays clean (no duplicates)

### Scenario 3: Location Disabled Until Customer Selected
**Objective**: Verify location dropdowns are disabled until customer selection

**Steps**:
1. Open booking form
2. Try to click on Pickup Location dropdown
3. Verify it's disabled
4. Select a customer
5. Try to click on Pickup Location dropdown
6. Verify it's enabled

**Expected Outcome**:
- Dropdowns start disabled (grayed out)
- After customer selection, enable
- User cannot search locations without customer

### Scenario 4: Typeahead Search
**Objective**: Verify location search filters by customer and requires min 2 chars

**Steps**:
1. Select a customer
2. Type "A" in Pickup Location → should show no results or loading
3. Type "AB" (2 chars) → should show filtered results
4. Type "ABC" → should show filtered results
5. Delete to "A" again → should reset

**Expected Outcome**:
- Less than 2 chars: no request or no results shown
- 2+ chars: shows customer-scoped addresses
- Only addresses for selected customer shown

### Scenario 5: Form Validation
**Objective**: Verify required fields are validated

**Steps**:
1. Try to submit form without:
   - Selecting customer
   - Selecting pickup location
   - Selecting delivery location
   - Choosing service type
   - Choosing payment type

**Expected Outcome**:
- Required fields show validation errors (red outline/message)
- Submit button disabled until all required fields filled
- Backend also validates (returns error response)

---

## Debugging Tips

### If Form Doesn't Load
1. Check browser console for JavaScript errors: `F12` → Console
2. Check Angular Vite logs: `docker logs svtms-angular`
3. Verify backend is running: `curl http://localhost:8080/actuator`

### If Locations Don't Show
1. Verify customer is selected
2. Check browser Network tab: Should see request to `/api/admin/customer-addresses?customerId=X`
3. Verify backend is returning addresses: `curl "http://localhost:8080/api/admin/customer-addresses?customerId=1" -H "Authorization: Bearer ..."`

### If Submission Fails
1. Check browser Console for client-side errors
2. Check Network tab for request/response details
3. Verify JWT token is valid: `curl http://localhost:8080/actuator/health -H "Authorization: Bearer ..."`
4. Check backend logs: `docker logs svtms-backend | tail -50`

### If Address Auto-fill Doesn't Work
1. Verify location selection event fired (browser Dev Tools)
2. Check form group exists: `bookingForm.get('pickupAddressGroup')`
3. Verify address object has expected properties

---

## Database Inspection

### Check Bookings Created
```bash
mysql -u root -proot -h localhost -P 3307 tms_db -e "
  SELECT id, customer_id, service_type, payment_type, status, created_at 
  FROM bookings 
  ORDER BY created_at DESC 
  LIMIT 10;
"
```

### Check Address Usage
```bash
mysql -u root -proot -h localhost -P 3307 tms_db -e "
  SELECT oa.id, oa.name, oa.address, oa.city, 
         COUNT(b.id) as booking_count
  FROM order_addresses oa
  LEFT JOIN bookings b ON oa.id = b.pickup_address_id OR oa.id = b.delivery_address_id
  GROUP BY oa.id
  ORDER BY booking_count DESC;
"
```

### Check Customer-Address Relationship
```bash
mysql -u root -proot -h localhost -P 3307 tms_db -e "
  SELECT c.id, c.name, COUNT(oa.id) as address_count
  FROM customers c
  LEFT JOIN order_addresses oa ON c.id = oa.customer_id
  GROUP BY c.id
  ORDER BY address_count DESC;
"
```

---

## Success Criteria

A successful implementation should meet these criteria:

- [ ] **UI**: Customer dropdown loads and filters by name
- [ ] **UI**: Location dropdowns appear and filter by customer
- [ ] **UI**: Location selection auto-fills address fields
- [ ] **UI**: Form submits without errors
- [ ] **API**: Backend receives CreateBookingRequest correctly
- [ ] **DB**: Booking record created in MySQL
- [ ] **DB**: Customer reference is correct
- [ ] **DB**: Address references are correct
- [ ] **DB**: Address deduplication works (no duplicates created)
- [ ] **Navigation**: Redirect to booking detail page successful
- [ ] **Detail Page**: Shows all submitted fields correctly

---

## Performance Notes

- Address search uses debounce (300ms) to reduce API calls
- Minimum 2 characters required before search to reduce server load
- Customer filtering on frontend + backend provides security + performance
- Address caching in RxJS prevents unnecessary API calls
- ng-select virtualizes large lists for better performance

---

## Known Limitations & Future Work

1. **Package Items**: Not yet persisted; currently frontend-only
2. **Status Transitions**: Confirm/Cancel/Convert endpoints not yet implemented
3. **Batch Import**: Cannot bulk import bookings (single create only)
4. **Tracking**: Real-time booking updates not yet implemented (polling only)
5. **Email Notifications**: Not yet integrated with booking creation

---

## Support

For issues or questions:
1. Check this testing guide first
2. Review `BOOKING_SYSTEM_IMPLEMENTATION_SUMMARY.md` for architectural details
3. Check backend logs: `docker logs svtms-backend`
4. Check frontend logs: `docker logs svtms-angular`
5. Check database: Connect directly via MySQL CLI
