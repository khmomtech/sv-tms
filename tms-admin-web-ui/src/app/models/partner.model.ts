export enum PartnershipType {
  DRIVER_FLEET = 'DRIVER_FLEET',
  CUSTOMER_CORPORATE = 'CUSTOMER_CORPORATE',
  FULL_SERVICE = 'FULL_SERVICE',
  LOGISTICS_PROVIDER = 'LOGISTICS_PROVIDER',
  TECHNOLOGY_PARTNER = 'TECHNOLOGY_PARTNER',
}

export enum PartnerStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
}

export interface PartnerCompany {
  id?: number;
  companyCode?: string;
  companyName: string;
  businessLicense?: string;
  contactPerson?: string;
  email?: string;
  phone?: string;
  address?: string;
  partnershipType: PartnershipType;
  status?: PartnerStatus;
  contractStartDate?: Date | string | null;
  contractEndDate?: Date | string | null;
  commissionRate?: number;
  creditLimit?: number;
  notes?: string;
  logoUrl?: string;
  website?: string;
  createdAt?: Date | number[] | string;
  updatedAt?: Date | number[] | string;
  createdBy?: string | null;
  updatedBy?: string | null;
}

export interface PartnerAdmin {
  id?: number;
  userId: number;
  partnerCompanyId: number;
  canManageDrivers: boolean;
  canManageCustomers: boolean;
  canViewReports: boolean;
  canManageSettings: boolean;
  isPrimary: boolean;
  createdAt?: Date | number[] | string;
  updatedAt?: Date | number[] | string;
  user?: {
    id: number;
    username: string;
    email: string;
  };
  partnerCompany?: PartnerCompany;
}

export interface PartnerAdminPermissions {
  canManageDrivers: boolean;
  canManageCustomers: boolean;
  canViewReports: boolean;
  canManageSettings: boolean;
}

export interface CustomerAccountRequest {
  username: string;
  password: string;
  email: string;
}

export const PARTNERSHIP_TYPE_LABELS: Record<PartnershipType, string> = {
  [PartnershipType.DRIVER_FLEET]: 'Driver Fleet',
  [PartnershipType.CUSTOMER_CORPORATE]: 'Corporate Customer',
  [PartnershipType.FULL_SERVICE]: 'Full Service Provider',
  [PartnershipType.LOGISTICS_PROVIDER]: 'Logistics Provider',
  [PartnershipType.TECHNOLOGY_PARTNER]: 'Technology Partner',
};

export const PARTNERSHIP_TYPE_COLORS: Record<PartnershipType, string> = {
  [PartnershipType.DRIVER_FLEET]: 'primary',
  [PartnershipType.CUSTOMER_CORPORATE]: 'accent',
  [PartnershipType.FULL_SERVICE]: 'warn',
  [PartnershipType.LOGISTICS_PROVIDER]: 'primary',
  [PartnershipType.TECHNOLOGY_PARTNER]: 'accent',
};
