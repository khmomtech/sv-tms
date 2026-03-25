> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Geofencing Feature

## Overview

Real-time geofencing system for monitoring driver locations and triggering alerts when drivers enter/exit designated zones.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌────────────────────┐
│  Driver Mobile  │────▶│  Backend WebSock │────▶│  Admin Dashboard   │
│  Location Update│     │  + Geofence Check│     │  Map Visualization │
└─────────────────┘     └──────────────────┘     └────────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │  Geofence Alert │
                        │  + FCM Notify   │
                        └─────────────────┘
```

## Features

### ✅ Phase 1 (Completed - March 2, 2026)

- **Geofence Types:**
  - Circular zones (center + radius)
  - Polygon zones (GeoJSON coordinates)
  - Linear zones (planned)

- **Alert Configuration:**
  - ENTER alerts only
  - EXIT alerts only
  - BOTH (entry + exit)
  - NONE (monitoring only)

- **Real-Time Detection:**
  - Point-in-polygon algorithm (Ray Casting)
  - Haversine distance calculation (~15m accuracy)
  - Previous location tracking for crossing detection
  - Event-driven architecture (LocationSavedEvent)

- **Notifications:**
  - WebSocket push to admin dashboard
  - FCM push to driver mobile app
  - Toast notifications in frontend
  - Audit trail in database

- **Map Visualization:**
  - Color-coded zones (green/orange/blue/gray)
  - Clickable zones with info display
  - Real-time crossing alerts
  - Support for Google Maps overlays

- **Speed Limit Zones:**
  - Optional speed limit per geofence
  - Foundation for speed violation alerts

### 🔄 Phase 2 (Planned)

- Geofence CRUD UI (create/edit/delete modals)
- Alert history dashboard
- Speed limit violation detection
- Comprehensive reporting
- Email/SMS notifications
- Geofence scheduling (time-based activation)
- Geofence groups and templates

### 🔮 Phase 3 (Future)

- Multi-polygon support (complex zones)
- Zone hierarchy (nested geofences)
- Heatmap analytics
- ML-based anomaly detection
- Integration with routing/dispatch system

## Backend Components

### Models

- **Geofence** (`model/Geofence.java`)
  - Supports CIRCLE, POLYGON, LINEAR types
  - ManyToOne relationship with PartnerCompany
  - OneToMany relationship with GeofenceAlert
  - Soft delete support (`active` flag)

- **GeofenceAlert** (`model/GeofenceAlert.java`)
  - Audit trail for all crossing events
  - Stores event coordinates, timestamp, distance from boundary
  - Indexes on driver_id, geofence_id, timestamp

### Services

- **GeofenceService** (`service/GeofenceService.java`)
  - CRUD operations for geofences
  - Point-in-polygon geometry algorithms
  - Crossing detection logic
  - WebSocket event publishing
  - 757 lines

- **GeofenceCheckingService** (`service/GeofenceCheckingService.java`)
  - Event listener for `LocationSavedEvent`
  - Checks all active geofences on location update
  - Respects alert configuration (ENTER/EXIT/BOTH/NONE)
  - Triggers FCM notifications
  - 259 lines

### REST API

- **GeofenceAdminController** (`controller/admin/GeofenceAdminController.java`)
  - Endpoint: `/api/admin/geofences/*`
  - Authorization: ADMIN or DISPATCHER role
  - 6 REST endpoints (CREATE, READ, UPDATE, DELETE, LIST, PAGINATED)
  - Health check endpoint (public)

### Repositories

- **GeofenceRepository** (`repository/GeofenceRepository.java`)
  - 7 query methods including custom JPQL
  - Pagination support
  - Date range queries
  - Count methods

- **GeofenceAlertRepository** (`repository/GeofenceAlertRepository.java`)
  - 8 query methods for alert history
  - Driver and geofence filtering
  - Date range queries
  - Last alert lookup

## Frontend Components

### Models

- **geofence.model.ts** (`models/geofence.model.ts`)
  - TypeScript interfaces matching backend DTOs
  - Enums: GeofenceType, AlertTypeEnum, GeofenceEventType
  - 76 lines

### Services

- **GeofenceService** (`services/geofence.service.ts`)
  - RxJS BehaviorSubject for state management
  - HTTP client for REST API calls
  - GeoJSON parsing/serialization
  - Color mapping for visualization
  - Local alert caching (last 50 events)
  - 237 lines

### Components

- **driver-gps-tracking.component.ts** (integration)
  - Geofence overlay rendering (Circle + Polygon)
  - WebSocket subscription for crossing alerts
  - Toast notifications
  - Click handlers for zone info
  - Lifecycle management (load/cleanup)

## Database Schema

### geofence table

| Column               | Type          | Description             |
| -------------------- | ------------- | ----------------------- |
| id                   | BIGINT        | Primary key             |
| partner_company_id   | BIGINT        | FK to partner_company   |
| name                 | VARCHAR(100)  | Geofence name           |
| description          | TEXT          | Optional description    |
| type                 | VARCHAR(20)   | CIRCLE, POLYGON, LINEAR |
| center_latitude      | DECIMAL(10,8) | For CIRCLE type         |
| center_longitude     | DECIMAL(11,8) | For CIRCLE type         |
| radius_meters        | DOUBLE        | For CIRCLE type         |
| geo_json_coordinates | TEXT          | For POLYGON type        |
| alert_type           | VARCHAR(20)   | ENTER, EXIT, BOTH, NONE |
| speed_limit_kmh      | INT           | Optional speed limit    |
| active               | BOOLEAN       | Soft delete flag        |
| created_at           | TIMESTAMP     | Creation timestamp      |
| updated_at           | TIMESTAMP     | Last update             |
| created_by           | VARCHAR(100)  | Username                |

**Indexes:**

- `idx_geofence_company_active` on (partner_company_id, active)
- `idx_geofence_type` on (type)
- `idx_geofence_created_at` on (created_at)

### geofence_alert table

| Column                        | Type          | Description            |
| ----------------------------- | ------------- | ---------------------- |
| id                            | BIGINT        | Primary key            |
| driver_id                     | BIGINT        | FK to driver           |
| geofence_id                   | BIGINT        | FK to geofence         |
| event_type                    | VARCHAR(20)   | ENTER or EXIT          |
| event_latitude                | DECIMAL(10,8) | Crossing point lat     |
| event_longitude               | DECIMAL(11,8) | Crossing point lng     |
| event_timestamp               | TIMESTAMP     | When crossing occurred |
| distance_from_boundary_meters | DOUBLE        | Proximity metric       |
| notification_sent             | BOOLEAN       | FCM sent flag          |
| created_at                    | TIMESTAMP     | Record creation        |

**Indexes:**

- `idx_geofence_alert_driver` on (driver_id)
- `idx_geofence_alert_geofence` on (geofence_id)
- `idx_geofence_alert_timestamp` on (event_timestamp)
- `idx_geofence_alert_event_type` on (event_type)

## Algorithms

### Point-in-Circle

```java
double distance = haversineDistance(pointLat, pointLng, centerLat, centerLng);
return distance <= radiusMeters;
```

**Haversine Formula:**

- Accounts for Earth's curvature
- Accuracy: ~15m for typical zones
- Complexity: O(1)

### Point-in-Polygon (Ray Casting)

```java
int intersections = 0;
for each edge in polygon {
    if horizontal ray from point intersects edge {
        intersections++;
    }
}
return (intersections % 2 == 1);  // Odd = inside
```

**Properties:**

- Works for any polygon (convex or concave)
- Complexity: O(n) where n = number of vertices
- Handles edge cases (point on boundary)

### Crossing Detection

```java
boolean wasInside = isPointInGeofence(prevLat, prevLng);
boolean isInside = isPointInGeofence(newLat, newLng);

if (!wasInside && isInside) return ENTER;
if (wasInside && !isInside) return EXIT;
return null;  // No crossing
```

## WebSocket Topics

### Published by Backend

- `/topic/admin/geofence-events` - Broadcast to all admin users
- `/user/queue/geofence-alerts` - User-specific queue for driver alerts

### Message Format

```json
{
  "driverId": 123,
  "driverName": "John Doe",
  "geofenceId": 45,
  "geofenceName": "Downtown Office",
  "eventType": "ENTER",
  "eventTimestamp": "2026-03-02T01:15:30.123Z",
  "latitude": 11.5565,
  "longitude": 104.9283
}
```

## Configuration

### Backend Properties

```properties
# Geofence settings (future)
geofence.crossing.detection.enabled=true
geofence.notification.fcm.enabled=true
geofence.alert.retention.days=90
```

### Frontend Environment

```typescript
// environment.ts
export const environment = {
  geofenceColors: {
    BOTH: "#28a745", // Green
    ENTER: "#ff9800", // Orange
    EXIT: "#2196F3", // Blue
    NONE: "#9e9e9e", // Gray
  },
  geofenceOpacity: 0.2,
  geofenceStrokeWeight: 2,
};
```

## Testing

**Test Guide:** [GEOFENCE_TESTING_GUIDE.md](../testing/GEOFENCE_TESTING_GUIDE.md)

**Test Script:** `/scripts/test-geofences.sh`

**Sample Data:**

- Downtown Office (CIRCLE, 500m, BOTH alerts)
- Warehouse District (POLYGON, ENTER alerts)
- School Zone (CIRCLE, 300m, speed limit 30 km/h)

**Test Coordinates:**

```
Center:   11.556374, 104.928206
Inside:   11.556500, 104.928300
Outside:  11.560000, 104.935000
Boundary: 11.560874, 104.928206
```

## Performance Considerations

### Optimization Strategies

1. **Company-scoped queries:** Only check geofences for driver's company
2. **Active flag filtering:** Exclude soft-deleted geofences early
3. **Event-driven processing:** Asynchronous crossing detection
4. **Index coverage:** All queries use indexed columns
5. **Local caching:** Frontend caches geofences via BehaviorSubject

### Scalability

- **O(n)** complexity where n = number of active geofences per company
- For 100 geofences × 1000 location updates/min = 100K checks/min
- Target: <10ms per location update processing
- Can optimize with spatial indexes (PostGIS) if needed

## Known Limitations

1. Crossing detection requires previous location (first update ignored)
2. Rapid location changes may miss crossings (mitigated by timestamp tracking)
3. Polygon vertices must be in correct order (counter-clockwise recommended)
4. No support for 3D zones (altitude-based geofencing)
5. Speed limit violations not yet enforced (foundation in place)

## Future Enhancements

### Short Term

- [ ] Geofence management UI (modals for create/edit/delete)
- [ ] Alert history viewer with filtering
- [ ] Speed violation real-time alerts

### Medium Term

- [ ] Comprehensive reporting dashboard
- [ ] Export geofence data (CSV, GeoJSON)
- [ ] Bulk geofence import
- [ ] Geofence templates library

### Long Term

- [ ] ML-based pattern detection (frequent crossings, dwell time)
- [ ] Integration with dispatch system (auto-assign based on zone)
- [ ] Multi-tenant geofence sharing
- [ ] Advanced analytics (zone utilization, heatmaps)

## References

- **Haversine Formula:** https://en.wikipedia.org/wiki/Haversine_formula
- **Ray Casting Algorithm:** https://en.wikipedia.org/wiki/Point_in_polygon
- **GeoJSON Spec:** https://datatracker.ietf.org/doc/html/rfc7946
- **Google Maps Overlays:** https://developers.google.com/maps/documentation/javascript/overlays

---

**Version:** 1.0  
**Last Updated:** March 2, 2026  
**Authors:** SV TMS Development Team  
**Status:** ✅ Phase 1 Complete
