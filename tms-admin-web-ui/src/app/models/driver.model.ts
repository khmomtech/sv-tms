import type { Vehicle } from './vehicle.model';

// === Server-enum mirrors (uppercase) ===
export type VehicleTypeEnum = 'TRUCK' | 'BIKE' | 'VAN';
export type DriverStatusEnum = 'ACTIVE' | 'INACTIVE' | 'OFFLINE' | 'ON_TRIP' | 'IDLE' | 'BUSY';

// === Client status literals ===
export type DriverStatusLiteral =
  | 'online'
  | 'offline'
  | 'busy'
  | 'idle'
  | 'on-trip'
  | 'active'
  | 'inactive';

// Mapping from server enum to client status literal
const serverToClientStatusMap: Record<DriverStatusEnum, DriverStatusLiteral> = {
  ACTIVE: 'online',
  INACTIVE: 'inactive',
  OFFLINE: 'offline',
  ON_TRIP: 'on-trip',
  IDLE: 'idle',
  BUSY: 'busy',
};

export interface Driver {
  selected: unknown;
  // 🎯 Basic Info
  id: number;
  name: string; // Full name or alias
  fullName?: string; // Fallback full name
  firstName?: string;
  lastName?: string;
  licenseNumber: string;
  licenseClass?: string; // License class (e.g., commercial for trucks)
  phone: string;
  rating: number;
  isActive: boolean;
  zone?: string | null;

  // 📧 Contact Information
  email?: string; // Optional email
  countryCode?: string; // Country code for phone number
  address?: string; // Home address
  emergencyContact?: string; // Emergency contact number
  notes?: string; // Additional notes
  profilePicture?: string; // URL/path to profile image
  licenseExpiryDate?: string | Date | null;
  idCardExpiry?: string | Date | null; // Optional ID card validity
  idCardIssuedDate?: string | Date | null;
  idCardNumber?: string | null;

  // 🏢 Partner Info
  partnerCompany?: string;
  isPartner?: boolean;
  partnerCompanyId?: number;
  driverGroupId?: number;
  driverGroupName?: string;

  // 🚗 Assigned Vehicle
  assignedVehicleId?: number;
  assignedVehicle?: Vehicle;

  // 🚗 Current Vehicle Assignment (from DriverSearchDto - preferred fields)
  currentVehicleId?: number; // From vehicle_drivers.vehicle_id
  currentVehiclePlate?: string; // From vehicles.license_plate
  vehicleAssignedAt?: string | Date; // From vehicle_drivers.assigned_at

  // 📡 Current Location
  latitude?: number;
  longitude?: number;
  currentLatitude?: number;
  currentLongitude?: number;
  locationName?: string;
  timestamp?: string;
  lastUpdated?: string;

  // 📶 Telemetry / Tracking
  isMoving?: boolean;
  speed?: number;
  status?: DriverStatusLiteral;
  vehicleType?: VehicleTypeEnum;
  ignition?: boolean;
  vehicleBattery?: number;
  gpsBatteryVoltage?: number;
  odometer?: number;
  engineHours?: number;
  satelliteCount?: number;

  // Dispatch Info
  dispatchId?: number;
  isOnline?: boolean;
  dispatch?: {
    id: number;
    routeCode?: string;
    status?: string;
    tripType?: string | null;
    pickup?: {
      lat: number;
      lng: number;
      locationName?: string;
    };
    dropoff?: {
      lat: number;
      lng: number;
      locationName?: string;
    };
  };

  // 📊 Movement History
  logs: {
    time: string;
    lat: number;
    lng: number;
  }[];

  locationHistory?: {
    id: number;
    latitude: number;
    longitude: number;
    timestamp: string;
  }[];

  updatedFromSocket: boolean;

  // 🔐 Login Account (user account linked to driver)
  user?: {
    id: number;
    username: string;
    email: string;
    roles: string[];
  };

  // 📱 Registered Device
  deviceToken?: string;
}

// === Write model for POST /api/drivers (must NOT include id) ===
export interface DriverCreateDto {
  // Names must match backend DriverCreateRequest
  firstName: string;
  lastName: string;
  name?: string;
  licenseNumber?: string;
  phone: string;
  rating?: number;
  isActive?: boolean;
  zone?: string | null;

  vehicleType?: VehicleTypeEnum;
  status?: DriverStatusEnum;

  latitude?: number;
  longitude?: number;

  deviceToken?: string;
  profilePicture?: string;
  idCardExpiry?: string | Date | null;
  idCardIssuedDate?: string | Date | null;
  idCardNumber?: string | null;

  // Backend expects `partner` (boolean) instead of `isPartner`
  partner?: boolean;
  partnerCompany?: string;
  partnerCompanyId?: number;
  driverGroupId?: number;

  employeeId?: number;
  assignedVehicleId?: number;
}

// === Helpers to build clean payloads for create ===
export function toVehicleTypeEnum(t?: string | Driver['vehicleType']): VehicleTypeEnum | undefined {
  if (!t) return undefined;
  const v = String(t).toLowerCase();
  if (v === 'truck') return 'TRUCK';
  if (v === 'bike') return 'BIKE';
  if (v === 'van') return 'VAN';
  return undefined;
}

export function toDriverStatusEnum(
  s?: string | DriverStatusLiteral | Driver['status'],
): DriverStatusEnum | undefined {
  if (!s) return undefined;
  // Normalize input to uppercase with underscores for matching server enum keys
  const normalized = String(s).toUpperCase().replace(/[- ]/g, '_');
  const allowed: DriverStatusEnum[] = ['ACTIVE', 'INACTIVE', 'OFFLINE', 'ON_TRIP', 'IDLE', 'BUSY'];
  return allowed.includes(normalized as DriverStatusEnum)
    ? (normalized as DriverStatusEnum)
    : undefined;
}

/**
 * Map server enum status to client status literal
 */
export function serverStatusToClientStatus(
  status?: DriverStatusEnum,
): DriverStatusLiteral | undefined {
  if (!status) return undefined;
  return serverToClientStatusMap[status];
}

/**
 * Map any driver-like form object to DriverCreateDto, stripping id and read-only fields.
 */
export function mapToDriverCreateDto(form: Partial<Driver> & Record<string, any>): DriverCreateDto {
  return {
    firstName: (form.firstName ?? '').toString().trim(),
    lastName: (form.lastName ?? '').toString().trim(),
    name: form.name?.toString().trim(),
    licenseNumber: form.licenseNumber?.toString().trim(),
    phone: (form.phone ?? '').toString().trim(),
    rating: form.rating,
    isActive: form.isActive,
    zone: (form.zone ?? null) as string | null,

    vehicleType: toVehicleTypeEnum(form.vehicleType),
    status: toDriverStatusEnum(form.status),

    latitude: form.latitude ?? form.currentLatitude,
    longitude: form.longitude ?? form.currentLongitude,

    deviceToken: form.deviceToken,
    profilePicture: (form as any).profilePicture,
    idCardExpiry: (form as any).idCardExpiry,
    idCardIssuedDate: (form as any).idCardIssuedDate,
    idCardNumber: (form as any).idCardNumber,

    partner: typeof form.isPartner === 'boolean' ? form.isPartner : (form as any).partner,
    partnerCompany: form.partnerCompany,
    partnerCompanyId:
      form.partnerCompanyId !== undefined && form.partnerCompanyId !== null
        ? Number(form.partnerCompanyId)
        : undefined,
    driverGroupId:
      form.driverGroupId !== undefined && form.driverGroupId !== null
        ? Number(form.driverGroupId)
        : undefined,

    employeeId: (form as any).employeeId,
    assignedVehicleId: form.assignedVehicleId,
  };
}

// NOTE: Do NOT send `Driver` to create endpoints. Use `DriverCreateDto` (and map via mapToDriverCreateDto)
// to avoid sending read-only fields such as `id`, tracking/telemetry, dispatch, etc.
