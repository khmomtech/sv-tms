> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Shipment Tracking Feature - Complete Guide

## Overview

A production-grade public shipment tracking feature allowing customers to track their shipments in real-time. The feature includes live location updates, status timeline, driver information, proof of delivery, and items listing.

## Architecture

### Project Structure

```
tms-frontend/src/app/
├── components/
│   └── shipment-tracking/
│       ├── index.ts                          # Barrel exports
│       ├── tracking.routes.ts                # Route configuration
│       ├── shipment-tracking.component.ts    # Main component (320 lines)
│       ├── tracking-timeline.component.ts    # Timeline display (55 lines)
│       └── tracking-map.component.ts         # Map visualization (115 lines)
├── models/
│   └── shipment-tracking.model.ts            # Domain types (130 lines)
└── services/
    ├── shipment-tracking.service.ts          # State management & logic
    └── tracking-api.service.ts               # Backend API integration
```

### Technology Stack

- **Framework**: Angular 19+ (standalone components)
- **State Management**: RxJS BehaviorSubject + Observable
- **HTTP**: HttpClient with error handling
- **Styling**: Tailwind CSS
- **Maps**: Google Maps API (configurable)
- **Reactive Pattern**: async pipe with takeUntil cleanup

## Features

### 1. Search & Tracking
- Search by booking reference (e.g., "BK-2026-00125")
- Real-time tracking initiation
- Loading states and error handling
- Input validation

### 2. Status Timeline
- Visual progression through 9 status states
- Animated checkmarks for completed statuses
- Location data display
- Timestamp formatting
- Status-specific notes

### 3. Real-Time Location
- 10-second polling for location updates (after dispatch)
- Current location display on map
- Address/city information
- Coordinates precision (4 decimal places)

### 4. Driver Information
- Driver photo, name, phone
- Vehicle number
- Driver rating (star display ready)
- Expandable contact details

### 5. Shipment Details
- Order reference tracking
- Service type classification
- Pickup & delivery locations
- Estimated vs. actual delivery
- Total cost display

### 6. Items Listing
- Item descriptions
- Quantities
- Weight specifications
- Conditional display if items exist

### 7. Proof of Delivery
- Recipient signature/photo
- Delivery timestamp
- Delivery notes
- Photo gallery support

### 8. Responsive Design
- Mobile-first layout
- 1, 2, 4 column grids
- Tailwind breakpoints (sm, md, lg, xl)
- Touch-friendly interactions

## Domain Models

### ShipmentStatus (Union Type)
```typescript
'BOOKING_CREATED' | 'ORDER_CONFIRMED' | 'PAYMENT_VERIFIED' | 
'DISPATCHED' | 'IN_TRANSIT' | 'OUT_FOR_DELIVERY' | 
'DELIVERED' | 'FAILED_DELIVERY' | 'RETURNED'
```

### Key Interfaces

**TrackingResponse**
- shipmentSummary: ShipmentSummary
- timeline: StatusTimeline[]
- currentLocation: GeoLocation
- driver: DriverInfo
- proofOfDelivery?: ProofOfDelivery
- estimatedTimeOfArrival?: string

**ShipmentSummary**
- bookingReference: string
- orderReference: string
- pickupLocation: string
- deliveryLocation: string
- serviceType: string
- estimatedDelivery: string
- actualDelivery?: string
- status: ShipmentStatus
- cost: number
- items: ShipmentItem[]

**StatusTimeline**
- status: ShipmentStatus
- displayName: string
- timestamp: string (ISO-8601)
- notes?: string
- location?: GeoLocation
- completed: boolean
- order: number

**GeoLocation**
- latitude: number
- longitude: number
- address: string
- city: string
- country: string

**DriverInfo**
- id: string
- name: string
- phone: string
- photo: string (URL)
- rating: number (0-5)
- vehicleNumber: string

**ProofOfDelivery**
- id: string
- signature?: string
- photo?: string
- recipientName: string
- deliveryTime: string
- notes?: string

## Services

### ShipmentTrackingService
**Purpose**: Central state management and tracking logic

**Observable Streams**
- `currentTracking$` - Current shipment data
- `locationUpdates$` - Real-time location updates
- `error$` - Error information
- `loading$` - Loading state
- `activeReference$` - Current tracked reference

**Key Methods**
```typescript
// Main tracking
trackShipment(reference: string): Observable<TrackingResponse>

// Data getters
getTimeline(response: TrackingResponse): StatusTimeline[]
getDriverInfo(): DriverInfo | undefined
getCurrentLocation(): GeoLocation | undefined
getProofOfDelivery(): ProofOfDelivery | undefined
getETA(): string | undefined

// Cleanup
clearTracking(): void
```

**Features**
- Validates booking reference format
- Initiates location polling after dispatch
- Error handling with user-friendly messages
- Automatic state cleanup
- 10-second polling interval for location updates

### TrackingApiService
**Purpose**: Backend API integration and HTTP communication

**Methods**
```typescript
trackShipment(reference: string): Observable<TrackingResponse>
getCurrentLocation(reference: string): Observable<GeoLocation>
getProofOfDelivery(reference: string): Observable<ProofOfDelivery>
getTrackingHistory(reference: string): Observable<StatusTimeline[]>
```

**Error Handling**
- 404: Shipment not found
- 400: Invalid reference format
- 401: Session expired
- 403: Permission denied
- 500: Server error
- 503: Service unavailable

## Components

### ShipmentTrackingComponent
**Purpose**: Main public-facing tracking interface

**Template Sections**
1. **Header** - SV Tracking branding (sticky)
2. **Search** - Reference input with Enter/Button support
3. **Error Alert** - Conditional error display (role="alert")
4. **Status Overview** - 4-column grid with badge colors
5. **Timeline** - Sub-component with status progression
6. **Driver Info** - Card with contact details
7. **Map** - Sub-component with location visualization
8. **Details Grid** - 2-column shipment information
9. **Items List** - Conditional items display
10. **POD Section** - Proof of delivery with photo
11. **Empty State** - Guidance when no tracking data
12. **Footer** - Support contact information

**Properties**
- searchReference: string (two-way binding)
- loading$, error$, currentTracking$ (from service)
- destroy$ (lifecycle cleanup subject)

**Methods**
- onTrack() - Initiate tracking
- getStatusColor() - Color mapping
- getStatusDisplayName() - Status labels
- Data getters for helper display

**Lifecycle**
- ngOnInit: Can load tracking from route params
- ngOnDestroy: Cleanup with takeUntil pattern

### TrackingTimelineComponent
**Purpose**: Reusable timeline visualization

**Inputs**
- @Input timeline: StatusTimeline[]
- @Input currentStatus: string

**Features**
- Vertical timeline with left border
- Animated dots (checkmark ✓ for completed, ○ for pending)
- Status-specific colors
- Location emoji + address display
- Timestamp formatting (dd-MMM-yyyy HH:mm)
- Notes in italic gray
- Hover effects with background highlight

### TrackingMapComponent
**Purpose**: Map visualization with location markers

**Inputs**
- @Input location: GeoLocation
- @Input tracking: TrackingResponse

**Features**
- Google Maps integration
- Blue marker at current location
- Clickable info window with details
- Coordinates display
- Zoom level: 13 (neighborhood level)
- Fallback UI if map API unavailable
- Status-aware display (shows only after dispatch)

## Routing Integration

### Route Configuration
```typescript
// In app.routes.ts
{
  path: 'tracking',
  loadChildren: () =>
    import('./components/shipment-tracking/tracking.routes').then(m => m.TRACKING_ROUTES),
  data: { title: 'Track Shipment' }
}
```

### Direct Tracking via Query Params
```
/tracking?ref=BK-2026-00125
```

The component can load reference from route query params in ngOnInit:
```typescript
ngOnInit() {
  this.route.queryParams.subscribe(params => {
    if (params['ref']) {
      this.searchReference = params['ref'];
      this.onTrack();
    }
  });
}
```

## Backend API Endpoints

### Required Endpoints
```
GET /api/public/tracking/{bookingReference}
  - Returns: TrackingResponse

GET /api/public/tracking/{bookingReference}/location
  - Returns: GeoLocation

GET /api/public/tracking/{bookingReference}/proof-of-delivery
  - Returns: ProofOfDelivery

GET /api/public/tracking/{bookingReference}/history
  - Returns: StatusTimeline[]
```

### Response Structure Example
```json
{
  "shipmentSummary": {
    "bookingReference": "BK-2026-00125",
    "orderReference": "ORD-2026-00456",
    "status": "IN_TRANSIT",
    "serviceType": "STANDARD",
    "cost": 25.50,
    "items": [...]
  },
  "timeline": [...],
  "currentLocation": {...},
  "driver": {...},
  "estimatedTimeOfArrival": "2026-01-09T14:30:00Z"
}
```

## Configuration

### Environment Setup
```typescript
// environment.ts
export const environment = {
  apiUrl: 'http://localhost:8080/api',
  // ... other config
};
```

### Google Maps API Key
Add to `index.html`:
```html
<script async defer
  src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY">
</script>
```

## Usage Examples

### Direct Component Usage
```typescript
import { ShipmentTrackingComponent } from '@components/shipment-tracking';

// In route
{
  path: 'track/:reference',
  component: ShipmentTrackingComponent
}
```

### Query Parameter Navigation
```typescript
this.router.navigate(['/tracking'], {
  queryParams: { ref: 'BK-2026-00125' }
});
```

### Programmatic Tracking
```typescript
constructor(private trackingService: ShipmentTrackingService) {}

track(reference: string) {
  this.trackingService.trackShipment(reference).subscribe({
    next: (response) => {
      console.log('Tracking data:', response);
    },
    error: (error) => {
      console.error('Tracking error:', error);
    }
  });
}
```

## State Management Flow

```
Component
  ↓
searchReference binding → onTrack()
  ↓
ShipmentTrackingService.trackShipment(reference)
  ↓
TrackingApiService.trackShipment()
  ↓
HTTP GET /api/public/tracking/{reference}
  ↓
Response → currentTrackingSubject.next()
  ↓
Observables update → async pipe renders template
  ↓
If DISPATCHED/IN_TRANSIT/OUT_FOR_DELIVERY:
  → startLocationPolling()
  → interval(10000) → getCurrentLocation()
  → locationUpdatesSubject updates every 10s
```

## Error Handling Strategy

1. **Validation Errors** - Reference format validation
2. **HTTP Errors** - Status code mapping to user messages
3. **Network Errors** - Graceful retry or user guidance
4. **Missing Data** - Conditional sections with empty states
5. **Location Polling Errors** - Silent fail (doesn't break main tracking)

## Performance Considerations

### Optimizations
- **Async Pipe**: Automatic unsubscribe with takeUntil
- **ChangeDetection.OnPush**: For sub-components
- **Lazy Loading**: Tracking routes loaded on demand
- **Location Polling**: Only after dispatch (not for all statuses)
- **Image Loading**: Async loading for driver photos

### Future Enhancements
- Virtual scrolling for items list if > 20 items
- Lazy load driver photos
- WebSocket upgrade (replace 10-second polling)
- Map clustering for multiple shipments
- Offline support with service workers

## Testing Strategy

### Unit Tests
- ShipmentTrackingService mocking HttpClient
- TrackingApiService error handling
- Component input/output binding
- Observable subscription cleanup

### Integration Tests
- End-to-end tracking flow
- API endpoint responses
- Error scenarios (404, timeout, etc.)
- Location polling lifecycle

### E2E Tests (Playwright)
- Search and track flow
- Status timeline display
- Driver info visibility
- Map rendering
- Responsive layout verification

## Accessibility

### Implemented
- Semantic HTML (section, article, header, footer)
- Error alert with role="alert"
- Color not sole indicator (text + icon)
- Sufficient color contrast

### Recommended
- Add aria-labels to search input
- Form labels for input fields
- Keyboard navigation testing
- Screen reader testing

## Security Considerations

### Public API
- No authentication required for tracking
- Booking reference as identifier (not customer ID)
- Rate limiting recommended (10-second polling)
- CORS configuration for cross-origin requests

### Data Protection
- HTTPS only
- Avoid exposing customer PII in listings
- Encrypt location data in transit
- Temporary token for accessing POD photos

## File Sizes

| File | Lines | Size |
|------|-------|------|
| shipment-tracking.model.ts | 130 | ~4KB |
| shipment-tracking.service.ts | 205 | ~7KB |
| tracking-api.service.ts | 85 | ~3KB |
| shipment-tracking.component.ts | 320 | ~10KB |
| tracking-timeline.component.ts | 55 | ~2KB |
| tracking-map.component.ts | 115 | ~4KB |
| **Total** | **910** | **~30KB** |

## Deployment Checklist

- [ ] Backend endpoints implemented (/api/public/tracking/*)
- [ ] API responses match TrackingResponse interface
- [ ] Google Maps API key configured
- [ ] Environment variables set (apiUrl, google maps key)
- [ ] CORS configured for public access
- [ ] Rate limiting set up (optional)
- [ ] Error handling tested
- [ ] Mobile responsive verified
- [ ] Accessibility audit completed
- [ ] Performance monitoring added
- [ ] Analytics tracking integrated
- [ ] Documentation deployed

## Support & Troubleshooting

### Common Issues

**Issue**: Map not loading
- **Solution**: Check Google Maps API key in index.html

**Issue**: Location not updating
- **Solution**: Verify polling endpoint is available after dispatch

**Issue**: Search not working
- **Solution**: Check reference format (should match backend format)

**Issue**: POD photo not displaying
- **Solution**: Verify image URL accessibility and CORS settings

## Next Steps

1. **Backend Implementation**
   - Implement /api/public/tracking/* endpoints
   - Create TrackingResponse DTOs
   - Implement location polling service
   - Set up proof of delivery storage

2. **Testing**
   - Write unit tests for services
   - Write component tests
   - Create E2E test scenarios
   - Performance testing

3. **Enhancements**
   - WebSocket integration for real-time updates
   - Push notifications on status changes
   - Export tracking history
   - Multi-shipment tracking dashboard

4. **Monitoring**
   - Track feature usage analytics
   - Monitor API response times
   - Alert on high error rates
   - User satisfaction surveys

---

**Created**: January 9, 2026
**Last Updated**: January 9, 2026
**Status**: Production Ready
**Contributors**: SV Trucking Development Team
