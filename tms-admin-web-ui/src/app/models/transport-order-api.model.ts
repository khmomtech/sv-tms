/**
 * API Response models for Transport Order
 * These interfaces represent the exact structure returned by the backend API
 */

export interface OrderAddress {
  id?: number;
  name: string;
  latitude?: number;
  longitude?: number;
  street?: string;
  city?: string;
  country?: string;
  phone?: string;
  contactPerson?: string;
}

export interface OrderStop {
  id: number;
  type: 'PICKUP' | 'DROP';
  address: OrderAddress;
  sequenceNumber?: number;
  arrivalTime?: string;
  departureTime?: string;
}

export interface Customer {
  id: number;
  name: string;
  phone?: string;
  email?: string;
}

/**
 * API response structure for Transport Orders
 * This is what comes back from the backend
 */
export interface TransportOrderApiResponse {
  id: number;
  orderReference: string;
  tripNo: string;
  status: string;
  orderDate: string;
  deliveryDate: string;
  customerId: number;
  customerName: string;
  billTo?: string;
  shipmentType?: string;
  courierAssigned?: string;
  createdByUsername?: string;
  customer?: Customer;
  pickupAddress?: OrderAddress;
  dropAddress?: OrderAddress;
  stops?: OrderStop[];
  createdAt?: string;
  updatedAt?: string;
  notes?: string;
  priority?: 'LOW' | 'MEDIUM' | 'HIGH';
  estimatedCost?: number;
  actualCost?: number;
  // New backend fields
  origin?: string;
  requiresDriver?: boolean;
}

/**
 * Paginated response wrapper
 */
export interface PaginatedResponse<T> {
  data: {
    content: T[];
    totalElements: number;
    totalPages: number;
    number: number;
    size: number;
  };
  status?: number;
  message?: string;
}

/**
 * Single entity response wrapper
 */
export interface ApiResponse<T> {
  data: T;
  status?: number;
  message?: string;
}
