export interface CustomerBillToAddress {
  id?: number;
  customerId: number;
  name?: string;
  address?: string;
  city?: string;
  state?: string;
  zip?: string;
  country?: string;
  contactName?: string;
  contactPhone?: string;
  email?: string;
  taxId?: string;
  notes?: string;
  isPrimary?: boolean;
  createdAt?: string;
  updatedAt?: string;
}
