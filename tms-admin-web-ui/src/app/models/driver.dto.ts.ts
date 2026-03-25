// src/app/models/driver.dto.ts
export interface DriverDto {
  id: number;
  name: string;
  licenseNumber: string;
  phone: string;
  rating: number;
  isActive: boolean;
  zone?: string;
  vehicleType?: string;
  status?: string;
  lastLocationAt?: string;
  partnerCompany?: string;
  isPartner?: boolean;
  profilePicture?: string;
  latitude?: number;
  longitude?: number;
  deviceToken?: string;
  employeeId?: number;
  userId?: number;
  logs?: { time: string; lat: number; lng: number }[];
}
