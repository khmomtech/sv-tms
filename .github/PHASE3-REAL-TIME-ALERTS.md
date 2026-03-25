# Phase 3: Real-Time Alerts Implementation

## Overview

Add critical monitoring features inspired by Wialon: speeding alerts, harsh braking detection, geofencing, and aggressive driving behavior monitoring.

## Implementation Steps

### 1. Create Alert Models & Types

**Create `src/app/models/driver-alert.model.ts`:**

```typescript
export type AlertSeverity = "critical" | "warning" | "info";
export type AlertType =
  | "speeding"
  | "harsh_braking"
  | "harsh_acceleration"
  | "geofence_enter"
  | "geofence_exit"
  | "battery_low"
  | "engine_off"
  | "idle_timeout";

export interface DriverAlert {
  id: string;
  driverId: number;
  driverName?: string;
  type: AlertType;
  severity: AlertSeverity;
  timestamp: number;
  message: string;
  value?: number; // e.g., speed when speeding
  threshold?: number; // e.g., speed limit
  latitude?: number;
  longitude?: number;
  snoozedUntil?: number; // timestamp when snooze expires
  isAcknowledged?: boolean;
  metadata?: Record<string, any>;
}

export interface AlertRule {
  id: string;
  name: string;
  enabled: boolean;
  alertType: AlertType;
  threshold: number; // speed limit, g-force threshold, etc.
  duration?: number; // min duration to trigger (e.g., 5s of speeding)
  severity: AlertSeverity;
  cooldownMs?: number; // don't re-alert for X ms
}
```

---

### 2. Create Alert Service

**Create `src/app/services/driver-alert.service.ts`:**

```typescript
import { Injectable } from "@angular/core";
import { HttpClient, HttpHeaders } from "@angular/common/http";
import { BehaviorSubject, Observable } from "rxjs";
import type { DriverAlert, AlertRule } from "../models/driver-alert.model";
import { environment } from "../environments/environment";
import { AuthService } from "./auth.service";

@Injectable({ providedIn: "root" })
export class DriverAlertService {
  private alertsSubject = new BehaviorSubject<DriverAlert[]>([]);
  public alerts$ = this.alertsSubject.asObservable();

  private activeAlertsSubject = new BehaviorSubject<Map<string, DriverAlert>>(
    new Map(),
  );
  public activeAlerts$ = this.activeAlertsSubject.asObservable();

  // Last timestamp each driver triggered each alert type (cooldown tracking)
  private lastAlertTs = new Map<string, number>();
  private readonly ALERT_COOLDOWN_MS = 30000; // 30s between same alert type per driver

  private rulesCache: AlertRule[] = [];

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {
    this.loadRules();
  }

  /**
   * Check telemetry and rules; emit alerts if thresholds exceeded.
   */
  checkAndEmitAlerts(driverId: number, telemetry: any): void {
    const now = Date.now();

    // Speeding alert
    if (telemetry.speed != null && telemetry.speed > 80) {
      this.maybeEmitAlert({
        driverId,
        type: "speeding",
        severity: "warning",
        threshold: 80,
        value: telemetry.speed,
        message: `Driver ${driverId} speeding: ${telemetry.speed} km/h`,
        timestamp: now,
      });
    }

    // Battery low alert
    if (telemetry.batteryLevel != null && telemetry.batteryLevel < 15) {
      this.maybeEmitAlert({
        driverId,
        type: "battery_low",
        severity: "warning",
        value: telemetry.batteryLevel,
        message: `Driver ${driverId} battery low: ${telemetry.batteryLevel}%`,
        timestamp: now,
      });
    }

    // Harsh braking (deceleration > 0.6g ≈ 6 m/s²)
    if (telemetry.acceleration != null && telemetry.acceleration < -6) {
      this.maybeEmitAlert({
        driverId,
        type: "harsh_braking",
        severity: "warning",
        value: Math.abs(telemetry.acceleration),
        message: `Driver ${driverId} harsh braking: ${Math.abs(telemetry.acceleration).toFixed(1)} m/s²`,
        timestamp: now,
      });
    }
  }

  /**
   * Emit alert only if not in cooldown period.
   */
  private maybeEmitAlert(alert: Partial<DriverAlert>): void {
    const key = `${alert.driverId}:${alert.type}`;
    const lastAlert = this.lastAlertTs.get(key) ?? 0;

    if (Date.now() - lastAlert < this.ALERT_COOLDOWN_MS) {
      return; // Still in cooldown
    }

    const fullAlert: DriverAlert = {
      id: `${key}:${Date.now()}`,
      driverId: alert.driverId!,
      driverName: alert.driverName,
      type: alert.type!,
      severity: alert.severity!,
      timestamp: alert.timestamp!,
      message: alert.message!,
      value: alert.value,
      threshold: alert.threshold,
      latitude: alert.latitude,
      longitude: alert.longitude,
    };

    this.lastAlertTs.set(key, Date.now());

    // Emit to active alerts map
    const active = this.activeAlertsSubject.value;
    active.set(fullAlert.id, fullAlert);
    this.activeAlertsSubject.next(new Map(active));

    // Keep history (up to 100 alerts)
    const history = this.alertsSubject.value;
    history.push(fullAlert);
    if (history.length > 100) history.shift();
    this.alertsSubject.next([...history]);

    // Optional: POST to backend for persistence
    this.logAlertToBackend(fullAlert).subscribe();
  }

  /** Snooze an alert for 5 minutes. */
  snoozeAlert(alertId: string, durationMs: number = 300000): void {
    const active = this.activeAlertsSubject.value;
    const alert = active.get(alertId);
    if (alert) {
      alert.snoozedUntil = Date.now() + durationMs;
      active.set(alertId, alert);
      this.activeAlertsSubject.next(new Map(active));
    }
  }

  /** Dismiss an alert. */
  dismissAlert(alertId: string): void {
    const active = this.activeAlertsSubject.value;
    active.delete(alertId);
    this.activeAlertsSubject.next(new Map(active));
  }

  /** Load alert rules from backend. */
  private loadRules(): void {
    // TODO: Implement REST call to /api/admin/alert-rules
    // For now, use defaults
    this.rulesCache = [
      {
        id: "1",
        name: "Speeding",
        enabled: true,
        alertType: "speeding",
        threshold: 80,
        severity: "warning",
      },
      {
        id: "2",
        name: "Harsh Braking",
        enabled: true,
        alertType: "harsh_braking",
        threshold: 6,
        severity: "warning",
      },
      {
        id: "3",
        name: "Battery Low",
        enabled: true,
        alertType: "battery_low",
        threshold: 15,
        severity: "warning",
      },
    ];
  }

  /** Log alert to backend for analytics. */
  private logAlertToBackend(alert: DriverAlert): Observable<any> {
    return this.http.post(
      `${environment.baseUrl}/api/admin/drivers/${alert.driverId}/alerts`,
      alert,
      { headers: this.authHeaders() },
    );
  }

  private authHeaders(): HttpHeaders {
    const token = this.authService.getToken() || "";
    return new HttpHeaders({ Authorization: `Bearer ${token}` });
  }
}
```

---

### 3. Create Alert Toast Notification Component

**Create `src/app/components/driver-alert-toast/driver-alert-toast.component.ts`:**

```typescript
import { Component, Input, Output, EventEmitter } from "@angular/core";
import { CommonModule } from "@angular/common";
import type { DriverAlert } from "../../models/driver-alert.model";

@Component({
  selector: "app-driver-alert-toast",
  standalone: true,
  imports: [CommonModule],
  template: `
    <div
      class="fixed top-4 right-4 max-w-sm p-4 rounded shadow-lg z-50 animate-slideInRight"
      [ngClass]="{
        'bg-red-100 border-l-4 border-red-500': alert.severity === 'critical',
        'bg-yellow-100 border-l-4 border-yellow-500':
          alert.severity === 'warning',
        'bg-blue-100 border-l-4 border-blue-500': alert.severity === 'info',
      }"
    >
      <div class="flex justify-between items-start">
        <div>
          <h3
            class="font-semibold"
            [ngClass]="{
              'text-red-800': alert.severity === 'critical',
              'text-yellow-800': alert.severity === 'warning',
              'text-blue-800': alert.severity === 'info',
            }"
          >
            {{ alert.type | titlecase }}
          </h3>
          <p class="text-sm mt-1">{{ alert.message }}</p>
          <p class="text-xs mt-2 opacity-70">
            {{ alert.timestamp | date: "short" }}
          </p>
        </div>
        <div class="flex gap-2 ml-4">
          <button
            (click)="onSnooze()"
            class="text-sm px-2 py-1 bg-white rounded hover:bg-gray-100"
          >
            Snooze
          </button>
          <button
            (click)="onDismiss()"
            class="text-sm px-2 py-1 bg-white rounded hover:bg-gray-100"
          >
            ✕
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      @keyframes slideInRight {
        from {
          transform: translateX(400px);
          opacity: 0;
        }
        to {
          transform: translateX(0);
          opacity: 1;
        }
      }
      .animate-slideInRight {
        animation: slideInRight 0.3s ease-out;
      }
    `,
  ],
})
export class DriverAlertToastComponent {
  @Input() alert!: DriverAlert;
  @Output() snoozed = new EventEmitter<string>();
  @Output() dismissed = new EventEmitter<string>();

  onSnooze(): void {
    this.snoozed.emit(this.alert.id);
  }

  onDismiss(): void {
    this.dismissed.emit(this.alert.id);
  }
}
```

---

### 4. Update driver-gps-tracking Component to Show Alerts

**Add to imports:**

```typescript
import { DriverAlertService } from "../services/driver-alert.service";
import { DriverAlertToastComponent } from "../components/driver-alert-toast/driver-alert-toast.component";
```

**Add to component properties:**

```typescript
activeAlerts: Map<string, DriverAlert> = new Map();
```

**Add to ngOnInit:**

```typescript
// Subscribe to active alerts
this.driverAlertService.activeAlerts$.subscribe((alerts) => {
  this.activeAlerts = alerts;
  this.cdr.markForCheck();
});
```

**Update template to show toasts (add to driver-gps-tracking.component.html):**

```html
<!-- Alert toasts -->
<ng-container *ngFor="let alert of activeAlerts | keyvalue">
  <app-driver-alert-toast
    [alert]="alert.value"
    (snoozed)="driverAlertService.snoozeAlert($event)"
    (dismissed)="driverAlertService.dismissAlert($event)"
  >
  </app-driver-alert-toast>
</ng-container>
```

---

### 5. Integrate Telemetry into Live Updates

**Update driver-gps-tracking component's applyLiveUpdate method:**

```typescript
// After location is updated, check for alerts
this.driverAlertService.checkAndEmitAlerts(driver.id!, {
  speed: driver.speed,
  batteryLevel: (driver as any).batteryLevel,
  acceleration: (update as any).acceleration, // future: from telemetry
});
```

---

## Testing Plan

1. **Speeding Alert**
   - Driver sends speed > 80 km/h
   - Toast appears with yellow warning
   - Cooldown prevents spam (30s)

2. **Harsh Braking**
   - Simulate acceleration < -6 m/s²
   - Orange toast appears
   - Message shows exact deceleration

3. **Battery Low**
   - Driver battery < 15%
   - Red alert appears
   - Persists until dismissed or snoozed

4. **Snooze & Dismiss**
   - Click snooze → alert disappears for 5 min
   - Click dismiss → alert goes away immediately
   - No spam after snooze duration

5. **Alert History**
   - Last 100 alerts logged in sidebar
   - Shows timestamp, driver, severity
   - Click to scroll driver into view on map

---

## Future Enhancements

- [ ] Geofencing: trigger on zone entry/exit (requires backend zones API)
- [ ] Accident detection: sharp heading + speed change
- [ ] Harsh acceleration: acceleration > 0.5g
- [ ] Idle timeout: engine off but vehicle stationary > 10 min
- [ ] Route deviation: off assigned route > 500m
- [ ] Fatigue detection: continuous driving > 4 hours without break
- [ ] Custom alert rules UI (admin panel)
- [ ] Email/SMS notifications for critical alerts
- [ ] Alert escalation (if not acknowledged in 5 min, notify fleet manager)
