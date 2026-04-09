/**
 * Geofence models for Frontend
 */

export enum GeofenceType {
  CIRCLE = 'CIRCLE',
  POLYGON = 'POLYGON',
  LINEAR = 'LINEAR',
}

export enum AlertTypeEnum {
  ENTER = 'ENTER',
  EXIT = 'EXIT',
  BOTH = 'BOTH',
  NONE = 'NONE',
}

export enum GeofenceEventType {
  ENTER = 'ENTER',
  EXIT = 'EXIT',
}

export interface Geofence {
  id: number;
  name: string;
  description?: string;
  type: GeofenceType;
  centerLatitude?: number;
  centerLongitude?: number;
  radiusMeters?: number;
  geoJsonCoordinates?: string; // GeoJSON string
  alertType: AlertTypeEnum;
  speedLimitKmh?: number;
  active: boolean;
  createdAt: string;
  updatedAt: string;
  createdBy?: string;
  tags?: string[]; // Category tags
}

export interface GeofenceCreateRequest {
  partnerCompanyId: number;
  name: string;
  description?: string;
  type: GeofenceType;
  centerLatitude?: number;
  centerLongitude?: number;
  radiusMeters?: number;
  geoJsonCoordinates?: string;
  alertType?: AlertTypeEnum;
  speedLimitKmh?: number;
  active?: boolean;
  tags?: string[];
}

export interface GeofenceAlert {
  id: number;
  driverId: number;
  driverName?: string;
  geofenceId: number;
  geofenceName?: string;
  eventType: GeofenceEventType;
  eventLatitude: number;
  eventLongitude: number;
  eventTimestamp: string;
  distanceFromBoundaryMeters?: number;
  notificationSent: boolean;
  createdAt: string;
}

export interface GeofenceEvent {
  driverId: number;
  driverName: string;
  geofenceId: number;
  geofenceName: string;
  eventType: string; // ENTER or EXIT
  eventTimestamp: string;
  latitude: number;
  longitude: number;
}
