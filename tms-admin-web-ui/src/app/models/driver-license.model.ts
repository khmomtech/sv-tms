export interface DriverLicense {
  id?: number;
  driverId: number;
  driverName?: string;
  licenseNumber: string;
  licenseClass?: string; // Cambodia: A1, A, B1, B, C, C1, D, E - Critical for vehicle assignment validation
  issuedDate?: string;
  expiryDate?: string;
  issuingAuthority?: string;
  licenseImageUrl?: string;
  licenseFrontImage?: string;
  licenseBackImage?: string;
  notes?: string;
  expired?: boolean;
}
