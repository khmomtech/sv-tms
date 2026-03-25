export type AlertSeverity = 'critical' | 'warning' | 'info';
export type AlertType =
  | 'speeding'
  | 'harsh_braking'
  | 'harsh_acceleration'
  | 'geofence_enter'
  | 'geofence_exit'
  | 'battery_low'
  | 'engine_off'
  | 'idle_timeout';

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
