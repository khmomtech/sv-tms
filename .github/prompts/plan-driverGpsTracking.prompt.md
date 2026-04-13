# Plan: Driver GPS & Tracking System Improvements (Wialon-Inspired)

## TL;DR

Your current GPS tracking has **real-time capability** but suffers from **WebSocket reliability**, **rendering performance**, and **stale data** issues. Wialon excels at real-time alerts, smooth rendering at scale, and automated monitoring. This plan focuses on fixing the WebSocket layer (reconnection logic), optimizing rendering with clustering, adding critical alerts (speeding, geofencing, harsh driving), and implementing better telemetry collection—all within your existing architecture.

---

## Current State Issues (Found)

### 1. WebSocket Reliability

- [driver-location.service.ts](tms-admin-web-ui/src/app/services/driver-location.service.ts#L83) uses basic exponential backoff (4s → capped at budget)
- No adaptive reconnection based on network conditions
- Multiple pending subscriptions can cause memory leaks
- No circuit breaker pattern

### 2. Rendering Performance

- Rendering 400+ markers + polylines simultaneously on Google Maps
- No marker clustering at low zoom levels
- Sidebar virtualizes drivers but map doesn't
- Frequent DOM churn from presence updates on slow networks

### 3. Stale Data

- REST fallback polling every 30s (too slow) — Wialon updates every 1-3s
- No distinction between "stale" (5-10m old) vs "old" (>30m)
- Presence timeout of 65s is aggressive; drivers appear offline too quickly

### 4. UI Issues

- Manual marker animation can jank with many drivers
- No clustering → overdraw at low zoom
- Selected driver sidebar doesn't auto-follow on map pan
- Limited telemetry shown (speed, battery only)

---

## Implementation Steps

### Phase 1: Fix WebSocket & Real-Time (Critical)

#### 1.1 Improve WebSocket Reconnection Strategy

**File**: [driver-location.service.ts](tms-admin-web-ui/src/app/services/driver-location.service.ts#L225)

Changes needed:

- Replace linear exponential backoff with jitter (avoid thundering herd)
- Detect network changes via `online`/`offline` events; reset backoff on network recovery
- Track subscription state; re-subscribe only if lost (not on every reconnect)
- Add circuit breaker: after 6 failed attempts, use REST-only mode for 5 minutes before retry

**Code snippet to add**:

```typescript
// Exponential backoff with jitter
private getNextBackoffMs(): number {
  const jitter = Math.random() * 1000; // 0-1000ms
  return Math.min(this.backoff + jitter, 60000); // cap at 60s
}

// Network change detection
if (typeof window !== 'undefined') {
  window.addEventListener('online', () => {
    this.backoff = this.baseDelay; // reset on network recovery
    this.reconnect();
  });
}
```

#### 1.2 Add Network Quality Monitoring

**New file**: `tms-admin-web-ui/src/app/services/network-quality.service.ts`

Features:

- Monitor WebSocket message latency (track time between send/receive)
- Detect degraded state (>5s latency); downgrade to polling + compression
- Auto-resume WebSocket when latency normalizes

#### 1.3 Implement Adaptive Polling

**File**: [driver-location.service.ts](tms-admin-web-ui/src/app/services/driver-location.service.ts#L300)

Changes:

- When WS disconnected → poll every 5s (not 30s)
- When WS connected → no polling
- Compress payloads: send only deltas (changed drivers) not full state

**Backend API support needed**:

```
GET /api/admin/drivers/live-drivers?delta=true&lastTimestamp=1234567890
```

---

### Phase 2: Optimize Rendering (Performance)

#### 2.1 Add Marker Clustering

**File**: [driver-gps-tracking.component.ts](tms-admin-web-ui/src/app/driver-gps-tracking/driver-gps-tracking.component.ts#L1) / [live-driver-location.component.ts](tms-admin-web-ui/src/app/live-driver-location/live-driver-location.component.ts)

Implementation:

- Install `@googlemaps/markerclustererplus` library
- Cluster at zoom < 13
- Show count + aggregate status in cluster (e.g., "12 🟢 3 🔴")
- Uncluster when user clicks or zooms in

**npm package**:

```bash
npm install @googlemaps/markerclustererplus
```

#### 2.2 Lazy Re-render Markers

**File**: [driver-gps-tracking.component.ts](tms-admin-web-ui/src/app/driver-gps-tracking/driver-gps-tracking.component.ts#L350) - `applyLiveUpdate()` method

Changes:

- Batch updates: coalesce 5-10 location updates per 400ms window
- Only re-render if position changed > 20m (not every tiny jitter)
- Use map `maxZoom` + `bounds changed` to skip off-screen marker updates

Current code:

```typescript
// Ignore tiny jitter: <8m movement and slow speed
const tinyMove = this.distanceMeters(prevLat, prevLng, lat, lng);
const reportedSpeed = typeof update?.speed === 'number' ? update.speed : (driver.speed ?? 0);
if (tinyMove < 8 && reportedSpeed <= 1) {
  // Still update presence/battery/lastUpdated but avoid DOM churn
  ...
}
```

Improve to:

```typescript
// Ignore tiny jitter: <20m movement when zoomed out
const threshold = this.zoom < 13 ? 30 : 8; // 30m when zoomed out, 8m when in
const tinyMove = this.distanceMeters(prevLat, prevLng, lat, lng);
const reportedSpeed = typeof update?.speed === 'number' ? update.speed : (driver.speed ?? 0);
if (tinyMove < threshold && reportedSpeed <= 1) {
  // Still update presence/battery/lastUpdated but avoid DOM churn
  ...
}
```

#### 2.3 Optimize Polyline History

**File**: [driver-gps-tracking.component.ts](tms-admin-web-ui/src/app/driver-gps-tracking/driver-gps-tracking.component.ts#L375) - `getPolylinePath()` method

Changes:

- Cap per-driver history at 50 points (not 200) when zoom < 14
- Drop every 2nd-3rd point when zoomed out; show all when zoomed in
- Lazy-load historical route on demand (click "show full trip" button)

```typescript
getPolylinePath(driver: Driver): google.maps.LatLngLiteral[] {
  let logs = driver.logs?.filter((log) => log.lat != null && log.lng != null) || [];

  // Thin out points at low zoom
  if (this.zoom < 14) {
    const step = this.zoom < 11 ? 3 : 2; // every 3rd point at zoom < 11
    logs = logs.filter((_, i) => i % step === 0);
  }

  // Cap total count
  const maxPoints = this.zoom < 14 ? 50 : 200;
  if (logs.length > maxPoints) {
    logs = logs.slice(-maxPoints);
  }

  return logs.map((log) => ({ lat: log.lat, lng: log.lng }));
}
```

---

### Phase 3: Add Critical Alerts & Telemetry (Wialon Features)

#### 3.1 Real-Time Alert Rules

**New backend endpoint**: `POST /api/admin/drivers/{id}/telemetry`

Alert types to implement:

- **Speeding**: > 80 km/h → visual badge + red marker outline
- **Harsh Braking**: deceleration > 0.6g → orange notification
- **Geofence Violations**: enter/exit zones → instant alert
- **Engine Off While Parked**: detect engine cutoff; alert if stays off > 10 min
- **Battery Critical** (mobile): < 15% → warning badge

#### 3.2 Telemetry Collection

**Backend collects from driver app**:

- Current speed, acceleration/deceleration
- Engine status (running/idle)
- Fuel level
- Battery level
- Network status (WiFi/4G/signal strength)

**DTO**:

```typescript
export interface TelemetryData {
  driverId: number;
  timestamp: number;
  speed: number;
  acceleration?: number;
  engineStatus?: "running" | "idle" | "off";
  fuelLevel?: number;
  batteryLevel?: number;
  networkType?: "wifi" | "4g" | "3g" | "unknown";
  signalStrength?: number; // 0-100
}
```

#### 3.3 Alert UI Component

**New file**: `tms-admin-web-ui/src/app/components/driver-alerts/driver-alerts.component.ts`

Features:

- Toast notifications for critical alerts (top-right)
- Notification log in sidebar (last 50 alerts per driver)
- Snooze/dismiss alerts (5 min, 1 hr, until next trip)

---

### Phase 4: Stale Data & Presence Management

#### 4.1 Improve Presence Detection

**File**: [driver-gps-tracking.component.ts](tms-admin-web-ui/src/app/driver-gps-tracking/driver-gps-tracking.component.ts#L150) - `isOnline()` method

Align with Wialon's "last ping" model:

- **Active** (🟢): last update < 10s ago
- **Idle** (🟡): 10-60s ago
- **Offline** (🔴): > 60s ago
- Show "last seen" timestamp in driver card (e.g., "3 min ago")

```typescript
getPresenceStatus(driver: Driver): 'active' | 'idle' | 'offline' {
  const byPresence = this.lastSeenByDriver[driver.id!] ?? 0;
  const byUpdated = toMs(driver.lastUpdated);
  const t = Math.max(byPresence, byUpdated);
  const ageMs = Date.now() - t;

  if (ageMs < 10_000) return 'active';
  if (ageMs < 60_000) return 'idle';
  return 'offline';
}
```

#### 4.2 Stale Data Visual Indicator

**File**: [driver-gps-tracking.component.html](tms-admin-web-ui/src/app/driver-gps-tracking/driver-gps-tracking.component.html)

Changes:

- Fade out marker opacity if > 5 min without update (show 70% opacity)
- Add "⚠️ stale" badge in driver list
- Blue outline = fresh (< 30s), gray = old (> 5 min)

In template:

```html
<div [ngClass]="getAgeClass(driver)">
  <!-- Blue for fresh, gray for old -->
</div>
```

In component:

```typescript
getAgeClass(driver: Driver): string {
  const ageMs = Date.now() - (toMs(driver.lastUpdated) ?? 0);
  if (ageMs < 30_000) return 'border-blue-500'; // fresh
  if (ageMs < 300_000) return 'border-gray-400'; // stale (5m)
  return 'border-red-300'; // very old
}
```

#### 4.3 Backend: Extend Telemetry Retention

**Changes**:

- Store last 24h of per-driver pins in Redis (not just current location)
- Expose `/api/admin/drivers/{id}/replay?startTime=X&endTime=Y` for route playback (future)

**Redis key structure**:

```
driver:locations:{driverId}:history -> sorted set by timestamp
  score: unix timestamp (ms)
  value: { lat, lng, speed, heading, accuracy, timestamp }
```

**TTL**: 24 hours (auto-expire old entries)

---

### Phase 5: UI/UX Enhancements

#### 5.1 Add Sidebar Match Map Selection

**Files**: [driver-gps-tracking.component.ts](tms-admin-web-ui/src/app/driver-gps-tracking/driver-gps-tracking.component.ts) + [driver-gps-tracking.component.html](tms-admin-web-ui/src/app/driver-gps-tracking/driver-gps-tracking.component.html)

Changes:

- When map marker is clicked → sidebar scrolls to & highlights driver
- When driver list item is clicked → map pans & zooms to driver; shows polyline

```typescript
onMarkerClick(marker: google.maps.Marker, driver: Driver): void {
  this.selectedDriver = driver;
  // Scroll sidebar to driver
  const element = document.getElementById(`driver-${driver.id}`);
  element?.scrollIntoView({ behavior: 'smooth', block: 'center' });
  this.cdr.markForCheck();
}
```

#### 5.2 Geo-Search/Radius Filter (nice-to-have for Phase 2)

- "Show drivers within 50 km of origin" → new filter input in toolbar

#### 5.3 Export & Share

- "Export trip" → CSV (timestamp, lat, lng, speed)
- "Share live link" → generate short URL to embed tracking widget

---

## Verification Checklist

### Test Locally

Start dev server: `npm start` → http://localhost:4200/live/drivers

#### Phase 1: WebSocket Resilience

- [ ] Disconnect WiFi → app should poll, reconnect when online
- [ ] Backend down (kill `./mvnw spring-boot:run`) → graceful fallback to REST
- [ ] Reconnect backend → WS resumes without manual refresh
- [ ] No reconnect spam in console (should stabilize after 1-2 attempts)

#### Phase 2: Rendering Performance

- [ ] Seed 400+ drivers via backend SQL: test marker rendering <100ms
- [ ] Zoom in/out → clustering activates/deactivates
- [ ] No UI jank; smooth panning with 50+ drivers
- [ ] Polyline simplifies when zoomed out; shows all points when zoomed in

#### Phase 3: Alerts

- [ ] Simulate speeding: driver app reports speed > 80 km/h → red outline + toast
- [ ] Simulate geofence: trigger location in/out of zone → notification
- [ ] Dismiss alert → doesn't reappear until next event
- [ ] Alert history persists in sidebar (last 50 alerts)

#### Phase 4: Stale Detection

- [ ] Driver goes offline → marker fades, shows 🔴
- [ ] Timestamp updates ("5 min ago" → "6 min ago")
- [ ] REST polling resumes, updates as expected
- [ ] Stale badge appears after 5 min no update

#### Phase 5: E2E Test

- [ ] Full trip: driver app sends location → backend → frontend within 2-3s
- [ ] No WebSocket reconnect churn (logs should show 1 connect, 0 reconnects over 5 min)
- [ ] Clicking marker → sidebar scrolls & highlights driver
- [ ] Clicking driver → map pans to driver location

---

## Technical Decisions

| Decision                    | Choice                                                          | Rationale                                           |
| --------------------------- | --------------------------------------------------------------- | --------------------------------------------------- |
| Clustering Library          | `@googlemaps/markerclustererplus`                               | Lightweight, official Google support, no major deps |
| Alert Storage               | Redis `geofences:{driverId}` → list of active violations        | 1-hour TTL, fast lookup, auto-cleanup               |
| Fallback Strategy           | WS → adaptive REST poll (5s) → exponential backoff if both fail | Graceful degradation, no hard failures              |
| History Cap                 | 50 points per driver by default, 200 when zoomed in             | Trade memory vs detail; reduce rendering churn      |
| Stale Timeout               | 60s (matches `ONLINE_WINDOW_MS`), visual fade at 5 min          | Conservative; visual feedback at 5m                 |
| Presence Model              | Active (< 10s), Idle (10-60s), Offline (> 60s)                  | Wialon-aligned; three-state clarity                 |
| Polling Interval (degraded) | 5s when WS disconnected                                         | 6x faster than current 30s; acceptable CPU cost     |
| Marker Threshold            | 20m at zoom < 13, 8m at zoom >= 13                              | Perceivable difference; less jank at low zoom       |

---

## Dependencies to Add

```bash
npm install @googlemaps/markerclustererplus --save
```

Optional future enhancements:

```bash
npm install turf @turf/distance  # for advanced geofencing
npm install chart.js ng2-charts   # for trip analytics dashboard
```

---

## Rollout Strategy

1. **Week 1**: Phase 1 (WebSocket fix) — test in staging; deploy to prod
2. **Week 2**: Phase 2 (Clustering + optimization) — limit to 5% users; monitor performance
3. **Week 3**: Phase 3 (Alerts framework) — gradual rollout; fine-tune thresholds with ops team
4. **Week 4**: Phase 4 + 5 (Polish) — full release

---

## Success Metrics

- **WebSocket reliability**: 99%+ uptime; < 1 reconnect per hour per user
- **Rendering**: Map renders 400 drivers in < 100ms; 60 FPS when panning
- **Stale data**: < 2s average latency from driver app update to map
- **Alert accuracy**: 0 false positives for speeding; geofence detection < 5s
- **User feedback**: NPS + 40; zero "tracking is slow" complaints

---

## Notes

- All changes are **backwards compatible** with existing API (no breaking changes)
- Existing driver app doesn't need changes for Phase 1-2; Phase 3 requires telemetry reporting from mobile
- Phase 4 presences on backend side are already in place (`lastSeen` tracking); frontend just visualizes better
- Future enhancement: "Replay trip" button that scrubs through historical positions using `/replay` endpoint
