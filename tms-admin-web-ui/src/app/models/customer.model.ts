import type { CompanyDetails } from './CompanyDetails';
import type { IndividualDetails } from './IndividualDetails';

export type CustomerLifecycleStage =
  | 'LEAD'
  | 'PROSPECT'
  | 'QUALIFIED'
  | 'CUSTOMER'
  | 'AT_RISK'
  | 'DORMANT'
  | 'CHURNED';

export interface Customer {
  id?: number;
  customerCode?: string;
  type: 'INDIVIDUAL' | 'COMPANY';
  name: string;
  email?: string;
  phone: string;
  address?: string;
  website?: string;
  customerGroup?: string;
  city?: string;
  state?: string;
  zip?: string;
  country?: string;
  paymentTerm?: string;
  codAllowed?: boolean;
  defaultServiceType?: string;
  notes?: string;
  status: 'ACTIVE' | 'INACTIVE';
  balance?: number;
  gender?: string;
  passportNumber?: string;
  isBanned?: boolean;
  passportImage?: string;

  // Financial fields (production-ready features)
  creditLimit?: number;
  paymentTerms?: string;
  currency?: string;
  currentBalance?: number;
  accountManager?: string;

  // Lifecycle stage (production-ready features)
  lifecycleStage?: CustomerLifecycleStage;

  // Metrics (read-only, calculated by backend)
  totalOrders?: number;
  totalRevenue?: number;
  lastOrderDate?: string;
  firstOrderDate?: string;
  segment?: string;

  // Tags and segmentation
  tags?: string[];
  customerSegment?: 'VIP' | 'REGULAR' | 'HIGH_VALUE' | 'AT_RISK' | 'NEW' | 'DORMANT';
  healthScore?: number;

  // Soft delete fields
  deletedAt?: string;
  deletedBy?: string;

  // Optional, conditionally populated based on type
  companyDetails?: CompanyDetails;
  individualDetails?: IndividualDetails;

  // Use empty array by default
  addresses: any[]; // or use OrderAddress[] if you import it
}
