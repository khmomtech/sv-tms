> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Quick Reference: Tracking Data Integration

## Service Usage - In Components

### Inject the Service
```typescript
constructor(private trackingService: ShipmentTrackingService) {}
```

### Subscribe to Data
```typescript
// In component class
ngOnInit() {
  // Current tracking info
  this.trackingService.currentTracking$.subscribe(data => {
    this.tracking = data;
  });

  // Pickup points for map
  this.trackingService.pickupPoints$.subscribe(points => {
    this.pickupPoints = points;
  });

  // Delivery points for map
  this.trackingService.deliveryPoints$.subscribe(points => {
    this.deliveryPoints = points;
  });

  // Order items
  this.trackingService.items$.subscribe(items => {
    this.items = items;
  });

  // Dispatch assignments
  this.trackingService.dispatches$.subscribe(dispatches => {
    this.dispatches = dispatches;
  });

  // Driver location updates
  this.trackingService.locationUpdates$.subscribe(location => {
    this.currentLocation = location;
  });
}
```

### Or Use Async Pipe (Recommended)
```typescript
<!-- In component template -->
<div *ngIf="(trackingService.currentTracking$ | async) as tracking">
  Order: {{ tracking.shipmentSummary.orderReference }}
  Customer: {{ tracking.shipmentSummary.customerName }}
</div>
```

---

## Template Usage

### Map with All Points
```html
<app-tracking-map
  [location]="(trackingService.locationUpdates$ | async)"
  [tracking]="(trackingService.currentTracking$ | async)"
  [pickupPoints]="(trackingService.pickupPoints$ | async) || []"
  [deliveryPoints]="(trackingService.deliveryPoints$ | async) || []">
</app-tracking-map>
```

### Items List
```html
<div *ngFor="let item of (trackingService.items$ | async) || []" class="p-4 border rounded">
  <div class="font-semibold">{{ item.description }}</div>
  <div class="text-sm text-gray-600">
    Quantity: {{ item.quantity }}
    <span *ngIf="item.weight"> | Weight: {{ item.weight }}kg</span>
  </div>
</div>
```

### Dispatch Info
```html
<div *ngFor="let dispatch of (trackingService.dispatches$ | async) || []" class="mb-4">
  <div class="bg-blue-50 p-4 rounded">
    <div class="font-semibold">Trip {{ dispatch.tripNo }}</div>
    <div class="text-sm text-gray-700">
      Route: {{ dispatch.route }} | Status: {{ dispatch.status }}
    </div>
    <div class="mt-2">
      <div>Driver: {{ dispatch.driver.fullName }} ({{ dispatch.driver.phone }})</div>
      <div>Vehicle: {{ dispatch.vehicle.vehicleNumber }}</div>
    </div>
  </div>
</div>
```

### Pickup/Delivery Locations
```html
<div class="mt-4">
  <h3 class="font-semibold mb-2">Loading Points</h3>
  <div *ngFor="let point of (trackingService.pickupPoints$ | async) || []" class="p-3 bg-blue-100 rounded mb-2">
    <div class="font-medium">{{ point.name }}</div>
    <div class="text-sm">{{ point.address }}</div>
    <div class="text-xs text-gray-600">
      {{ point.coordinates.latitude }}, {{ point.coordinates.longitude }}
    </div>
  </div>

  <h3 class="font-semibold mb-2 mt-4">Unloading Points</h3>
  <div *ngFor="let point of (trackingService.deliveryPoints$ | async) || []" class="p-3 bg-green-100 rounded mb-2">
    <div class="font-medium">{{ point.name }}</div>
    <div class="text-sm">{{ point.address }}</div>
    <div class="text-xs text-gray-600">
      {{ point.coordinates.latitude }}, {{ point.coordinates.longitude }}
    </div>
  </div>
</div>
```

### Current Driver Location
```html
<div *ngIf="(trackingService.locationUpdates$ | async) as location" class="bg-blue-50 p-4 rounded">
  <div class="font-semibold">🚚 Current Location</div>
  <div class="text-sm mt-2">
    {{ location.locationName || 'Unknown' }}
  </div>
  <div class="text-xs text-gray-600">
    Lat: {{ location.latitude | number: '1.4-6' }}
    Lng: {{ location.longitude | number: '1.4-6' }}
  </div>
  <div *ngIf="location.speed" class="text-xs">
    Speed: {{ location.speed }}km/h | Direction: {{ location.heading }}°
  </div>
  <div *ngIf="location.lastSeen" class="text-xs text-gray-500">
    Last seen: {{ location.lastSeen | date: 'short' }}
  </div>
</div>
```

---

## Method Usage

### Track a Shipment
```typescript
this.trackingService.trackShipment('2025345-00001').subscribe({
  next: (response) => {
    console.log('Tracking loaded:', response);
    // All observables automatically updated
  },
  error: (err) => {
    console.error('Tracking failed:', err);
  }
});
```

### Get Data Directly (for one-time reads)
```typescript
// Get current tracking data without subscription
const tracking = this.trackingService.getCurrentTracking();
const items = this.trackingService.getItems();
const pickupPoints = this.trackingService.getPickupPoints();
const deliveryPoints = this.trackingService.getDeliveryPoints();
const dispatches = this.trackingService.getDispatches();
const driver = this.trackingService.getDriverInfo();
const location = this.trackingService.getCurrentLocation();
```

### Clear Data
```typescript
this.trackingService.clearTracking();
// All observables reset to null/[]
```

---

## Data Structures

### OrderPoint
```typescript
interface OrderPoint {
  name: string;              // "KHB", "BTB", etc.
  address: string;           // Full address
  coordinates: {
    latitude: number;        // e.g., 11.627
    longitude: number;       // e.g., 104.891
  };
}
```

### ShipmentItem
```typescript
interface ShipmentItem {
  description: string;       // "Electronics", "Laptop", etc.
  quantity: number;          // 2
  weight?: number;           // kg
  dimension?: {
    length: number;
    width: number;
    height: number;
  };
}
```

### DispatchAssignment
```typescript
interface DispatchAssignment {
  dispatchId: string;        // "DISP-001"
  tripNo: string;            // "TRIP-2025-001"
  route: string;             // "KHB-BTB"
  driver: DriverInfo;        // Driver object
  vehicle: {
    vehicleNumber: string;   // "KH-1234"
    model?: string;          // "Isuzu"
    capacity?: number;       // 5000
  };
  status: string;            // "IN_TRANSIT", "COMPLETED"
  createdAt?: string;        // ISO timestamp
  completedAt?: string;      // ISO timestamp
}
```

### GeoLocation
```typescript
interface GeoLocation {
  latitude: number;
  longitude: number;
  locationName?: string;     // "Tonle Bassac"
  lastSeen?: number;         // Unix timestamp
  isOnline?: boolean;        // true
  accuracy?: number;         // 25
  speed?: number;            // 45 km/h
  heading?: number;          // 180 degrees
  address?: string;          // Legacy field
}
```

---

## Common Patterns

### Display Order Summary
```html
<div *ngIf="(trackingService.currentTracking$ | async) as tracking">
  <h1>{{ tracking.shipmentSummary.orderReference }}</h1>
  <p>Customer: {{ tracking.shipmentSummary.customerName }}</p>
  <p>Status: {{ tracking.shipmentSummary.status }}</p>
  <p>Estimated Delivery: {{ tracking.shipmentSummary.estimatedDelivery | date: 'short' }}</p>
</div>
```

### Show All Pickup Points on Map
```html
<!-- Already handled by tracking-map component -->
<app-tracking-map
  [pickupPoints]="(trackingService.pickupPoints$ | async) || []"
  [deliveryPoints]="(trackingService.deliveryPoints$ | async) || []"
  [location]="(trackingService.locationUpdates$ | async)">
</app-tracking-map>
```

### Create Items Table
```html
<table>
  <thead>
    <tr>
      <th>Item</th>
      <th>Qty</th>
      <th>Weight</th>
      <th>Dimensions</th>
    </tr>
  </thead>
  <tbody>
    <tr *ngFor="let item of (trackingService.items$ | async) || []">
      <td>{{ item.description }}</td>
      <td>{{ item.quantity }}</td>
      <td>{{ item.weight }}kg</td>
      <td>
        <span *ngIf="item.dimension">
          {{ item.dimension.length }} × {{ item.dimension.width }} × {{ item.dimension.height }}
        </span>
      </td>
    </tr>
  </tbody>
</table>
```

### Display Driver & Vehicle Info
```html
<div *ngIf="(trackingService.currentTracking$ | async) as tracking">
  <div *ngIf="tracking.driver" class="bg-gray-50 p-4 rounded">
    <h3 class="font-semibold">Driver Information</h3>
    <p>{{ tracking.driver.fullName }}</p>
    <p>{{ tracking.driver.phone }}</p>
    <p *ngIf="tracking.driver.rating">Rating: ⭐ {{ tracking.driver.rating }}</p>
    
    <h3 class="font-semibold mt-4">Vehicle</h3>
    <p>{{ tracking.driver.vehicleNumber }}</p>
    <p *ngIf="tracking.driver.tripNo">Trip: {{ tracking.driver.tripNo }}</p>
    <p *ngIf="tracking.driver.status">Status: {{ tracking.driver.status }}</p>
  </div>
</div>
```

---

## Loading & Error States

### Show Loading State
```html
<div *ngIf="(trackingService.loading$ | async) === true" class="p-4 text-center">
  ⏳ Loading tracking information...
</div>
```

### Show Error State
```html
<div *ngIf="(trackingService.error$ | async) as error" class="p-4 bg-red-100 rounded">
  <div class="text-red-700">{{ error.message }}</div>
  <div *ngIf="error.details" class="text-sm text-red-600">{{ error.details }}</div>
</div>
```

---

## Component Integration Example

```typescript
import { Component, OnInit } from '@angular/core';
import { ShipmentTrackingService } from '@services/shipment-tracking.service';

@Component({
  selector: 'app-tracking-page',
  template: `
    <div class="container mx-auto p-4">
      <!-- Map -->
      <app-tracking-map
        [location]="(trackingService.locationUpdates$ | async)"
        [tracking]="(trackingService.currentTracking$ | async)"
        [pickupPoints]="(trackingService.pickupPoints$ | async) || []"
        [deliveryPoints]="(trackingService.deliveryPoints$ | async) || []">
      </app-tracking-map>

      <!-- Order Info -->
      <div *ngIf="(trackingService.currentTracking$ | async) as tracking" class="mt-6">
        <h2>{{ tracking.shipmentSummary.orderReference }}</h2>
        <p>{{ tracking.shipmentSummary.customerName }}</p>
      </div>

      <!-- Items -->
      <div class="mt-6">
        <h3>Items</h3>
        <div *ngFor="let item of (trackingService.items$ | async) || []">
          {{ item.description }} × {{ item.quantity }}
        </div>
      </div>

      <!-- Dispatch -->
      <div class="mt-6">
        <h3>Dispatch</h3>
        <div *ngFor="let dispatch of (trackingService.dispatches$ | async) || []">
          <p>Driver: {{ dispatch.driver.fullName }}</p>
          <p>Vehicle: {{ dispatch.vehicle.vehicleNumber }}</p>
        </div>
      </div>
    </div>
  `
})
export class TrackingPageComponent implements OnInit {
  constructor(public trackingService: ShipmentTrackingService) {}

  ngOnInit() {
    // Get reference from route params and track
    const reference = '2025345-00001'; // from route
    this.trackingService.trackShipment(reference).subscribe();
  }
}
```

---

## Migration from Old Code

### Before:
```typescript
// Only location available
const location = this.trackingService.getCurrentLocation();
```

### After:
```typescript
// Full data available
const tracking = this.trackingService.getCurrentTracking();
const items = this.trackingService.getItems();
const pickupPoints = this.trackingService.getPickupPoints();
const deliveryPoints = this.trackingService.getDeliveryPoints();
const dispatches = this.trackingService.getDispatches();

// Or use observables
this.trackingService.items$.subscribe(items => { ... });
this.trackingService.pickupPoints$.subscribe(points => { ... });
```

---

## Performance Tips

✅ **Use async pipe** - Automatically unsubscribes
```html
{{ (trackingService.items$ | async) | json }}
```

✅ **Use OnPush change detection** - For better performance
```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush
})
```

✅ **Combine observables** - When displaying related data
```typescript
import { combineLatest } from 'rxjs';

combineLatest([
  this.trackingService.currentTracking$,
  this.trackingService.pickupPoints$,
  this.trackingService.deliveryPoints$
]).subscribe(([tracking, pickups, deliveries]) => {
  // All data available at once
});
```

---

## Next Steps

1. Update existing component templates to use new data
2. Add items table display
3. Add dispatch/driver info card
4. Add pickup/delivery point list
5. Integrate WebSocket for real-time updates
6. Add polyline visualization on map
7. Add timeline of dispatch events
8. Add ETA calculation based on current speed
