export interface CustomerContact {
  id?: number;
  customerId: number;
  customerName?: string;
  fullName: string;
  email?: string;
  phone?: string;
  position?: string;
  isPrimary?: boolean;
  isActive?: boolean;
  lastLogin?: string;
  notes?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface CustomerContactRequest {
  customerId: number;
  fullName: string;
  email?: string;
  phone?: string;
  position?: string;
  isPrimary?: boolean;
  isActive?: boolean;
  notes?: string;
}
