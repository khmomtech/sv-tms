import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { BehaviorSubject, Observable } from 'rxjs';
import type { DriverAlert, AlertRule } from '../models/driver-alert.model';
import { environment } from '../environments/environment';
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class DriverAlertService {
  private alertsSubject = new BehaviorSubject<DriverAlert[]>([]);
  public alerts$ = this.alertsSubject.asObservable();

  private activeAlertsSubject = new BehaviorSubject<Map<string, DriverAlert>>(new Map());
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

  /** Get current active alerts map (for testing) */
  getActiveAlerts(): Map<string, DriverAlert> {
    return this.activeAlertsSubject.value;
  }

  /** Get current alert history (for testing) */
  getAlertHistory(): DriverAlert[] {
    return this.alertsSubject.value;
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
        type: 'speeding',
        severity: 'warning',
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
        type: 'battery_low',
        severity: 'warning',
        value: telemetry.batteryLevel,
        message: `Driver ${driverId} battery low: ${telemetry.batteryLevel}%`,
        timestamp: now,
      });
    }

    // Harsh braking (deceleration > 0.6g ≈ 6 m/s²)
    if (telemetry.acceleration != null && telemetry.acceleration < -6) {
      this.maybeEmitAlert({
        driverId,
        type: 'harsh_braking',
        severity: 'warning',
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
        id: '1',
        name: 'Speeding',
        enabled: true,
        alertType: 'speeding',
        threshold: 80,
        severity: 'warning',
      },
      {
        id: '2',
        name: 'Harsh Braking',
        enabled: true,
        alertType: 'harsh_braking',
        threshold: 6,
        severity: 'warning',
      },
      {
        id: '3',
        name: 'Battery Low',
        enabled: true,
        alertType: 'battery_low',
        threshold: 15,
        severity: 'warning',
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
    const token = this.authService.getToken() || '';
    return new HttpHeaders({ Authorization: `Bearer ${token}` });
  }
}
