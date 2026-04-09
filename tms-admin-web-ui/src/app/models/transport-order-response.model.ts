import type { OrderAddressDto } from '../services/order-address.model';
import type { OrderItemDto } from '../services/order-item.model';

import type { Dispatch } from './dispatch.model';
import type { InvoiceDto } from './invoice.model';

export interface AssignedDriver {
  id: number;
  name: string;
  contact: string;
  vehicleNumber: string;
}

export interface TrackingInfo {
  status: string;
  lastUpdated: string; // ISO string format (e.g., "2025-03-15T10:30:00Z")
  currentLocation: {
    latitude: number;
    longitude: number;
  };
  eta?: string; // Estimated Time of Arrival
  liveTrackingUrl?: string; // External tracking URL
  events?: Array<{
    timestamp?: string;
    status?: string;
    location?: string;
    note?: string;
    [key: string]: any;
  }>;
}

export interface OrderStopDto {
  id: number;
  type: 'PICKUP' | 'DROP';
  transportOrderId: number;
  address: OrderAddressDto;
  sequence: number;
  eta: string | null;
  arrivalTime: string | null;
  departureTime: string | null;
  remarks: string | null;
  proofImageUrl: string | null;
  confirmedBy: string | null;
  contactPhone: string | null;
  addressId: number;
}

export interface TransportOrderResponseDto {
  id: number;
  orderReference: string;
  customerId: string;
  customerName: string;
  billTo: string;
  orderDate: string;
  deliveryDate: string;
  shipmentType: string;
  courierAssigned: string;
  status: string;

  createdBy: { username: string };
  items: OrderItemDto[];

  pickupAddress: OrderAddressDto | null;
  dropAddress: OrderAddressDto | null;

  pickupAddresses: OrderAddressDto[];
  dropAddresses: OrderAddressDto[];

  dispatches: Dispatch[];
  invoice: InvoiceDto | null;

  assignedDriver?: AssignedDriver;
  tracking?: TrackingInfo;

  //  Add this field to match backend
  stops?: OrderStopDto[];
  /** Backend-provided origin for the order */
  origin?: string;

  /** Indicates whether the order requires a driver (true/false) */
  requiresDriver?: boolean;
}
