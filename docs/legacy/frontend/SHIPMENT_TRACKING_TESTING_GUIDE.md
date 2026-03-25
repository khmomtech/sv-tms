> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Shipment Tracking Feature - Quick Testing Guide

## Setup

### 1. Start the Development Stack
```bash
cd /Users/sotheakh/Documents/develop/sv-tms

# Start all services (MySQL, Redis, Backend, Frontend)
docker compose -f docker-compose.dev.yml up --build

# Wait for:
# - Backend: http://localhost:8080 ✓
# - Frontend: http://localhost:4200 ✓
# - MySQL: localhost:3307 ✓
# - Redis: localhost:6379 ✓
```

### 2. Access the Tracking Feature
```
http://localhost:4200/tracking
```

## Manual Testing Scenarios

### Scenario 1: Search for Active Tracking
1. Navigate to `/tracking`
2. Enter valid booking reference: `BK-2026-00125`
3. Click "Track Shipment" or press Enter
4. **Expected**: 
   - Loading spinner appears briefly
   - Shipment data loads
   - Timeline shows status progression
   - Driver info displays
   - Map section shows location

### Scenario 2: Invalid Reference
1. Enter: `INVALID-123`
2. Click "Track Shipment"
3. **Expected**: 
   - Error alert appears
   - Message: "Shipment not found..."
   - Search field remains editable

### Scenario 3: Empty Search
1. Leave search field empty
2. Click "Track Shipment"
3. **Expected**:
   - Button disabled (grayed out)
   - No API call made

### Scenario 4: Real-Time Location Updates
1. Search for active shipment in transit
2. Watch the "Current Location" section
3. **Expected**:
   - Location updates every 10 seconds
   - Coordinates change if driver is moving
   - Map updates (if Google Maps configured)

### Scenario 5: Proof of Delivery Display
1. Search for DELIVERED shipment: `BK-2026-DELIVERED`
2. Scroll to "Proof of Delivery" section
3. **Expected**:
   - Recipient name visible
   - Delivery timestamp displayed
   - Photo/signature section (if available)
   - Notes if present

### Scenario 6: Items Listing
1. Track any shipment with items
2. Scroll to "Shipment Items" section
3. **Expected**:
   - Item descriptions listed
   - Quantities shown
   - Weight specifications visible
   - Conditional display (only if items > 0)

### Scenario 7: Direct Tracking via URL
1. Navigate to: `/tracking?ref=BK-2026-00125`
2. **Expected**:
   - Component loads with ref from query param
   - Automatically calls trackShipment()
   - Data displays without manual search

### Scenario 8: Mobile Responsiveness
1. Open DevTools (F12)
2. Toggle device toolbar
3. Test screen sizes:
   - iPhone 12 (390px)
   - iPad (768px)
   - Desktop (1920px)
4. **Expected**:
   - 1 column on mobile
   - 2 columns on tablet
   - 4 columns on desktop
   - Touch-friendly spacing

## API Testing

### Verify Backend Endpoints
```bash
# Test main tracking endpoint
curl -X GET http://localhost:8080/api/public/tracking/BK-2026-00125 \
  -H "Content-Type: application/json"

# Response should match TrackingResponse interface
# {
#   "shipmentSummary": {...},
#   "timeline": [...],
#   "currentLocation": {...},
#   "driver": {...},
#   "proofOfDelivery": {...}
# }
```

### Check Location Updates
```bash
curl -X GET http://localhost:8080/api/public/tracking/BK-2026-00125/location
# Response: {"latitude": 11.5564, "longitude": 104.9282, ...}
```

### Check POD
```bash
curl -X GET http://localhost:8080/api/public/tracking/BK-2026-00125/proof-of-delivery
# Response: {"recipientName": "John", "deliveryTime": "...", ...}
```

## Browser DevTools Inspection

### Check Network Tab
1. Open DevTools → Network tab
2. Track a shipment
3. **Verify**:
   - GET /api/tracking/{ref} → 200 OK
   - Location polling starts (10-second intervals)
   - No 404 or 500 errors

### Check Console
1. Open DevTools → Console
2. Track a shipment
3. **Verify**:
   - No TypeScript compilation errors
   - No JavaScript errors
   - Map initialization logs (if configured)

### Check Performance
1. Open DevTools → Performance tab
2. Record tracking search
3. **Verify**:
   - Initial load < 1 second
   - Component render < 500ms
   - No memory leaks after multiple tracks

## Data Validation

### Verify Model Types
In browser console:
```javascript
// Check observable streams
// From ShipmentTrackingService
console.log(trackingService.currentTracking$.value)
console.log(trackingService.error$.value)
console.log(trackingService.loading$.value)
console.log(trackingService.locationUpdates$.value)
```

### Verify Timeline Order
1. Track shipment
2. Open browser console
3. Execute:
```javascript
const timeline = trackingService.currentTracking$.value?.timeline;
timeline.forEach(t => console.log(t.order, t.displayName, t.completed))
// Should show 1-9 in ascending order
// Should show checkmarks (✓) for completed
```

### Verify Status Colors
1. In template, inspect status badge element
2. **Verify color classes**:
   - BOOKING_CREATED → blue
   - IN_TRANSIT → orange
   - DELIVERED → green
   - FAILED_DELIVERY → red

## Error Scenarios

### Test 404 Error
1. Search: `BK-NOTFOUND`
2. **Expected error message**:
   "Shipment not found. Please check the booking reference."

### Test 400 Error
1. Search: `INVALID_FORMAT_123_@#$`
2. **Expected error message**:
   "Invalid booking reference format."

### Test 401 Error (Session Expired)
1. Clear localStorage/cookies
2. Search any reference
3. **Expected error message**:
   "Session expired. Please login again."

### Test 500 Error
1. Stop backend service: `docker compose down`
2. Try to track
3. **Expected error message**:
   "Server error. Please try again later."

## Component Integration Testing

### Test Keyboard Navigation
1. Open `/tracking`
2. Tab through elements
3. **Verify**:
   - Search input receives focus
   - "Track" button accessible via Tab
   - Enter key on input triggers search

### Test Form State
1. Type in search field: `BK-2026-00125`
2. Clear field (select all + delete)
3. **Verify**: Button becomes disabled

### Test Async Pipe Unsubscribe
1. Track shipment
2. Wait 3 seconds
3. Navigate away: `router.navigate(['/'])`
4. **Verify**: Polling stops (no more API calls)

## Map Component Testing

### Test Map Initialization
1. Track shipment in transit
2. Scroll to Map section
3. **Verify**:
   - Map container renders (not loading spinner)
   - Blue marker visible
   - Map centered on coordinates

### Test Map Marker Click
1. Click on marker
2. **Verify**:
   - Info window appears
   - Shows location details
   - Info window closable

### Test Fallback UI
1. Disconnect from internet or block Google Maps API
2. Track shipment
3. **Verify**:
   - Map section shows location info card
   - No errors in console
   - Graceful degradation

## Performance Benchmarks

### Expected Metrics
- Initial load: < 2 seconds
- First contentful paint: < 1.5 seconds
- Interactive: < 3 seconds
- Bundle size: ~30KB (all tracking code)
- Location polling CPU impact: < 2%

### Measure with DevTools Lighthouse
1. Open DevTools → Lighthouse
2. Run "Mobile" or "Desktop" audit
3. **Targets**:
   - Performance: > 85
   - Accessibility: > 90
   - Best Practices: > 90

## Test Data References

### Sample Booking References
- `BK-2026-00125` → BOOKING_CREATED
- `BK-2026-00126` → ORDER_CONFIRMED
- `BK-2026-00127` → PAYMENT_VERIFIED
- `BK-2026-00128` → DISPATCHED
- `BK-2026-00129` → IN_TRANSIT
- `BK-2026-00130` → OUT_FOR_DELIVERY
- `BK-2026-00131` → DELIVERED
- `BK-2026-00132` → FAILED_DELIVERY
- `BK-2026-00133` → RETURNED

### Mock Responses (Backend Seed Data)
Create in `PermissionInitializationService` or test data loader:
```java
// SeedTrackingData.java
List<Shipment> mockShipments = List.of(
  new Shipment()
    .setBookingReference("BK-2026-00125")
    .setStatus(ShipmentStatus.BOOKING_CREATED)
    .setPickupLocation("Phnom Penh, Cambodia")
    .setDeliveryLocation("Sihanoukville, Cambodia")
    .setCost(25.50)
    // ... more fields
);
```

## Regression Testing Checklist

After making changes, verify:

- [ ] Search still works for valid reference
- [ ] Invalid reference shows error
- [ ] Empty search button disabled
- [ ] Timeline displays correctly
- [ ] Status colors applied
- [ ] Driver info visible
- [ ] Items list shows (if present)
- [ ] POD section conditional
- [ ] Map initializes (if Google Maps configured)
- [ ] Location polling starts after dispatch
- [ ] Error cleanup works (no memory leaks)
- [ ] Mobile responsive on 3 sizes
- [ ] Keyboard navigation works
- [ ] No console errors
- [ ] No TypeScript errors

## CI/CD Testing

### Pre-commit Checks
```bash
# Lint
npm run lint

# Type check
npx tsc --noEmit

# Unit tests
npm run test -- --include='**/shipment-tracking/**'

# Build
npm run build
```

### Pre-push Checks
```bash
# E2E tests
npm run test:e2e

# Full test suite
npm run test:ci

# Performance check
npm run build -- --stats-json
```

## Troubleshooting

### Issue: "Module not found: shipment-tracking.service"
- **Solution**: Ensure all import paths use correct relative paths
- Check barrel export in `index.ts`

### Issue: "TypeError: Cannot read property 'shipmentSummary' of null"
- **Solution**: Add safe navigation in template: `tracking?.shipmentSummary`
- Use `async` pipe with default: `(currentTracking$ | async)?.shipmentSummary`

### Issue: Google Map not rendering
- **Solution**: Add API key to `index.html`
- Check browser console for API errors
- Verify CORS settings

### Issue: Location polling not starting
- **Solution**: Check shipment status is DISPATCHED/IN_TRANSIT/OUT_FOR_DELIVERY
- Verify endpoint `/api/public/tracking/{ref}/location` exists
- Check for network errors in DevTools

## Next Testing Steps

1. **Unit Tests** - Write tests for services and components
2. **Integration Tests** - Test with real backend API
3. **E2E Tests** - Playwright scenarios for user flows
4. **Load Testing** - Simulate 100+ concurrent users
5. **Accessibility Testing** - WCAG 2.1 AA compliance
6. **Performance Testing** - Google Lighthouse targets
7. **Security Testing** - OWASP Top 10 validation

---

**Last Updated**: January 9, 2026
**Testing Team**: QA & Development
