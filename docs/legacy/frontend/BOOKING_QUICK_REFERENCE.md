> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Booking System - Quick Reference Guide

## System Overview

The booking system enables customers to create transport bookings through the admin portal. It integrates customer selection, location management, and booking persistence.

```
┌─────────────────────────────────────────────────────────────┐
│                    Angular Frontend (Port 4200)             │
│  Booking Form → Customer Selection → Location Selection    │
│                   → Form Submission                         │
└──────────────────────────┬──────────────────────────────────┘
                           │ CreateBookingRequest
                           ▼
┌──────────────────────────────────────────────────────────────┐
│           Spring Boot Backend (Port 8080)                   │
│  BookingController → BookingService → BookingRepository     │
│            → MySQL Persistence                             │
└──────────────────────────────────────────────────────────────┘
```

## Frontend URL Routes

| Route | Purpose |
|-------|---------|
| `/bookings/create` | Create new booking form |
| `/bookings` | List all bookings |
| `/bookings/:id` | View booking details |
| `/bookings/:id/edit` | Edit existing booking |

## Backend API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/admin/bookings` | Create new booking |
| GET | `/api/admin/bookings` | List all bookings |
| GET | `/api/admin/bookings/{id}` | Get booking by ID |
| PUT | `/api/admin/bookings/{id}` | Update booking |
| DELETE | `/api/admin/bookings/{id}` | Delete booking |

## Key Components

### Frontend

**booking-form.component.ts**
- Manages form state and user interactions
- Handles customer selection with autocomplete
- Manages location search and selection
- Submits booking data to backend

**booking.service.ts**
- HTTP client for booking API
- Request/response handling
- Error management
- Base URL: `${environment.apiBaseUrl}/admin/bookings`

### Backend

**BookingService.java**
```java
public ResponseEntity<ApiResponse<BookingDto>> create(CreateBookingRequest req)
public ResponseEntity<ApiResponse<BookingDto>> getById(Long id)
public ResponseEntity<ApiResponse<List<BookingDto>>> list()
```

**BookingController.java**
```
@RestController
@RequestMapping("/api/admin/bookings")
```

## Data Models

### Customer Selection
```typescript
Customer {
  id: number
  name: string              // Used for display
  phone: string
  email: string
  type: "COMPANY" | "INDIVIDUAL"
}
```

### Location/Address
```typescript
OrderAddress {
  id: number
  name: string              // Company name
  address: string
  city: string
  province: string
  postalCode: string
  country: string
  contactName: string
  contactPhone: string
  customerId: number        // Associated customer
}
```

### Booking Creation Request
```typescript
CreateBookingDto {
  customerId: number
  pickupAddress: BookingAddressDto
  deliveryAddress: BookingAddressDto
  serviceType: "AIR" | "LAND" | "SEA"
  paymentType: "CASH" | "CREDIT" | "BANK_TRANSFER"
  pickupDate: Date
  deliveryDate: Date
  truckType?: string
  capacity?: number
  totalWeightTons?: number
  totalVolumeCbm?: number
  palletCount?: number
  specialHandlingNotes?: string
  requiresInsurance?: boolean
  estimatedCost?: number
  notes?: string
}
```

### Booking Response
```typescript
BookingDto {
  id: number
  customerId: number
  customerName: string
  customerPhone: string
  pickupAddress: OrderAddressDto
  deliveryAddress: OrderAddressDto
  serviceType: string
  paymentType: string
  pickupDate: Date
  deliveryDate: Date
  status: "CREATED" | "CONFIRMED" | "CANCELLED"
  ... all fields from request
}
```

## Form Fields & Validation

### Required Fields
- Customer (ng-select dropdown)
- Pickup Location (ng-select, autocomplete)
- Delivery Location (ng-select, autocomplete)
- Service Type (dropdown)
- Payment Type (dropdown)
- Pickup Date (date picker)

### Optional Fields
- Truck Type
- Capacity
- Total Weight (tons)
- Total Volume (CBM)
- Pallet Count
- Special Handling Notes
- Insurance Required (checkbox)
- General Notes (textarea)
- Estimated Cost

## Form Interaction Flow

```
1. User opens /bookings/create
   ↓
2. Form displays customer dropdown (empty initially)
   ↓
3. User types customer name (e.g., "Karate")
   ↓
4. Frontend calls CustomerService.search(term)
   ↓
5. Dropdown shows matching customers
   ↓
6. User selects customer
   ↓
7. Location dropdowns ENABLE (were disabled before)
   ↓
8. User types location name in Pickup Location (min 2 chars)
   ↓
9. Frontend calls AddressService.search(customerId, term)
   ↓
10. Dropdown shows customer-scoped addresses
    ↓
11. User selects location
    ↓
12. Form auto-fills address fields from selected location
    ↓
13. User fills remaining fields (service type, payment, dates)
    ↓
14. User clicks "Create Booking"
    ↓
15. Form validates all required fields
    ↓
16. Frontend builds CreateBookingRequest
    ↓
17. POST /api/admin/bookings with request body
    ↓
18. Backend validates and persists
    ↓
19. Frontend receives BookingDto response
    ↓
20. Redirect to /bookings/:id (booking detail page)
```

## Common Code Snippets

### Get Booking by ID (Frontend)
```typescript
this.bookingService.getById(bookingId).subscribe({
  next: (booking) => console.log(booking),
  error: (err) => console.error(err)
});
```

### List All Bookings (Frontend)
```typescript
this.bookingService.list().subscribe({
  next: (bookings) => console.log(bookings),
  error: (err) => console.error(err)
});
```

### Create Booking (Frontend)
```typescript
const createRequest = {
  customerId: 1,
  pickupAddress: { /* ... */ },
  deliveryAddress: { /* ... */ },
  serviceType: "LAND",
  paymentType: "CREDIT",
  pickupDate: new Date(),
  // ...
};

this.bookingService.create(createRequest).subscribe({
  next: (booking) => {
    console.log('Booking created:', booking);
    this.router.navigate(['/bookings', booking.id]);
  },
  error: (err) => this.error = err.message
});
```

### Query Bookings (Backend/SQL)
```sql
-- Get all bookings with customer and address details
SELECT 
  b.id, b.customer_id, c.name as customer_name,
  b.service_type, b.payment_type, b.status,
  pa.name as pickup_location, da.name as delivery_location,
  b.pickup_date, b.delivery_date
FROM bookings b
JOIN customers c ON b.customer_id = c.id
LEFT JOIN order_addresses pa ON b.pickup_address_id = pa.id
LEFT JOIN order_addresses da ON b.delivery_address_id = da.id
WHERE b.status != 'CANCELLED'
ORDER BY b.created_at DESC;
```

## Debugging Quick Tips

### Frontend Debugging

**Check Form State**
```typescript
// In browser console
const form = document.querySelector('app-booking-form');
console.log(form.__ngContext__[8].component.bookingForm.value);
```

**Check RxJS Streams**
```typescript
// Add tap operator to debug
pickupLocations$ = this.pickupLocationSearchInput$.pipe(
  tap(term => console.log('Search term:', term)),
  debounceTime(300),
  // ...
);
```

**Check API Calls**
```
Browser Dev Tools → Network Tab
Filter: XHR
Look for: /api/admin/bookings, /api/admin/customer-addresses
```

### Backend Debugging

**Check Logs**
```bash
docker logs svtms-backend | grep -i booking
```

**Check Database**
```bash
mysql -u root -proot -h localhost -P 3307 tms_db
SELECT * FROM bookings;
SELECT * FROM order_addresses;
```

**Check API Response**
```bash
curl -X GET http://localhost:8080/api/admin/bookings/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Performance Tips

1. **Debounce Search**: 300ms prevents excessive API calls
2. **Min 2 Characters**: Don't search for single characters
3. **Customer Scoping**: Filter addresses in database, not in code
4. **Lazy Loading**: Only load form fields when needed
5. **Virtual Scrolling**: ng-select handles large lists efficiently

## Security Considerations

1. **JWT Required**: All endpoints protected with Bearer token
2. **Customer Isolation**: Addresses shown only for selected customer
3. **Input Validation**: Required on both frontend and backend
4. **CORS Protection**: Proxy setup in Angular dev server
5. **SQL Injection**: Using JPA prevents SQL injection

## Troubleshooting

### Form Won't Load
```
Check: Browser console for errors
Fix: Clear browser cache, hard refresh (Cmd+Shift+R)
```

### Locations Not Showing
```
Check: Did you select a customer?
Check: Network tab - is address API returning data?
Fix: Ensure customer has addresses in database
```

### Submit Fails
```
Check: Are all required fields filled (red outline)?
Check: Are dates valid (pickup ≤ delivery)?
Check: Network tab - what error does backend return?
```

### Address Fields Don't Auto-fill
```
Check: Did location selection complete (should see spinner)?
Check: Address object has expected properties
Fix: Check console for JavaScript errors
```

## Important Files Reference

| File | Purpose | Location |
|------|---------|----------|
| booking-form.component.ts | Main form logic | `tms-frontend/src/app/features/bookings/` |
| booking-form.component.html | Form template | `tms-frontend/src/app/features/bookings/` |
| booking.service.ts | API client | `tms-frontend/src/app/services/` |
| BookingController.java | API endpoints | `tms-backend/src/.../controller/admin/` |
| BookingService.java | Business logic | `tms-backend/src/.../service/` |
| Booking.java | Data model | `tms-backend/src/.../model/` |
| BookingDto.java | Response DTO | `tms-backend/src/.../dto/` |

## Environment Variables

**Frontend** (`environment.ts`)
```typescript
apiBaseUrl: 'http://localhost:8080'
```

**Backend** (`.env`)
```
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3307/tms_db
SPRING_DATASOURCE_USERNAME=root
SPRING_DATASOURCE_PASSWORD=root
JWT_SECRET=your-secret-key
```

## Docker Commands

```bash
# Start all services
docker-compose -f docker-compose.dev.yml up -d

# Check backend logs
docker logs -f svtms-backend

# Check frontend logs
docker logs -f svtms-angular

# Restart backend
docker restart svtms-backend

# Stop all services
docker-compose down

# View running services
docker ps | grep svtms
```

## Testing Database Manually

```bash
# Connect to MySQL
mysql -u root -proot -h localhost -P 3307 tms_db

# View all bookings
SELECT * FROM bookings;

# View bookings with customer names
SELECT b.*, c.name FROM bookings b 
JOIN customers c ON b.customer_id = c.id;

# Count bookings by status
SELECT status, COUNT(*) FROM bookings GROUP BY status;

# Check address reuse
SELECT pa.id, COUNT(*) as usage_count
FROM bookings b
JOIN order_addresses pa ON b.pickup_address_id = pa.id
GROUP BY pa.id
HAVING COUNT(*) > 1;
```

## Important Notes

- ⚠️ **Customer must be selected** before location dropdowns appear
- ⚠️ **Location search needs min 2 characters** to prevent flooding
- ⚠️ **Addresses are customer-scoped** (can't see other customer's addresses)
- ⚠️ **Delivery date must be >= pickup date** (form validation)
- ⚠️ **JWT token required** for all API endpoints
- ℹ️ **Addresses reuse automatically** (no duplicates created)
- ℹ️ **All timestamps** stored in UTC (created_at, updated_at)
- ℹ️ **Audit trail** maintained (created_by, updated_by)

---

**Last Updated**: 2026-01-09  
**Version**: 1.0  
**Status**: Production Ready
