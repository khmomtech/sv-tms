export interface DeviceRegisterDto {
  id: number;
  driverId: number | null;
  driverName: string;

  deviceId: string;
  deviceName: string;
  os: string;
  version: string;
  appVersion: string;
  manufacturer: string;
  model: string;
  ipAddress: string;
  location: string;

  status: 'PENDING' | 'APPROVED' | 'BLOCKED'; // Match Java enum DeviceStatus

  registeredAt: string; // ISO date-time string (LocalDateTime from backend)
  approvedBy: string;
  statusUpdatedAt: string; // ISO date-time string (LocalDateTime from backend)

  showMenu?: boolean; // Local UI-only field
}
