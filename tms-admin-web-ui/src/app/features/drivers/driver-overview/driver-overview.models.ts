export type DriverStatusFilter =
  | 'ALL'
  | 'ONLINE'
  | 'ON_TRIP'
  | 'OFFLINE'
  | 'SUSPENDED'
  | 'RESIGNED';

export interface DriverFlagDto {
  type: 'CRITICAL' | 'WARNING';
  label: string;
  detail?: string;
}

export interface DriverSummaryDto {
  id: number;
  name: string;
  status: 'ONLINE' | 'ON_TRIP' | 'OFFLINE';
  statusLabel: string;
  vehiclePlate?: string;
  phone?: string;
  lastLocationName?: string;
  lastUpdateLabel?: string;
  lastUpdateTime?: string;
  photoUrl?: string;
  currentTripId?: number;
  currentTripCode?: string;
  flags: DriverFlagDto[];
}

export interface DriverStatsDto {
  totalDrivers: number;
  svEmployees: number;
  partnerDrivers: number;
  exitDrivers: number;
  activeDrivers: number;
  suspendedDrivers: number;
  onlineDrivers: number;
  onTripDrivers: number;
  offlineDrivers: number;
  expiredDocuments: number;
  nearExpiryDocuments: number;
  utilizationRate: number;
}

export interface ExpiringDocAlertDto {
  id: number;
  driverName: string;
  documentName: string;
  daysLeft: number;
  expiresOn: string;
}

export interface IncidentAlertDto {
  id: number;
  code?: string;
  driverName: string;
  title: string;
  severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  reportedAt: string;
}

export interface DeviceAlertDto {
  driverId: number;
  driverName: string;
  offlineDurationMinutes: number;
  lastSeenLabel: string;
}

export interface DriverAlertsDto {
  docs: ExpiringDocAlertDto[];
  incidents: IncidentAlertDto[];
  devices: DeviceAlertDto[];
}

export interface PermissionsDto {
  canCreateDriver: boolean;
  canAssignVehicle: boolean;
  canSuspendDriver: boolean;
  canBroadcast: boolean;
}
