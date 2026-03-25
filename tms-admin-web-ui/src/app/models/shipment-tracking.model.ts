/**
 * Shipment Tracking Models
 * Defines interfaces for tracking orders and shipments in real-time
 */

export type ShipmentStatus =
  | 'BOOKING_CREATED'
  | 'ORDER_CONFIRMED'
  | 'PAYMENT_VERIFIED'
  | 'DISPATCHED'
  | 'IN_TRANSIT'
  | 'OUT_FOR_DELIVERY'
  | 'DELIVERED'
  | 'FAILED_DELIVERY'
  | 'RETURNED';

export interface StatusTimeline {
  status: ShipmentStatus;
  displayName: string;
  timestamp?: string;
  notes?: string;
  location?: GeoLocation;
  completed: boolean;
  order?: number;
  rawStatus?: string; // Original dispatch enum status (PENDING, ASSIGNED, etc.)
  updatedBy?: string; // User who triggered this status update
}

export interface GeoLocation {
  latitude: number;
  longitude: number;
  locationName?: string | null;
  lastSeen?: number; // Unix timestamp
  isOnline?: boolean;
  accuracy?: number | null;
  speed?: number | null;
  heading?: number | null;
  // Legacy fields (kept for backward compatibility)
  address?: string;
  city?: string;
  country?: string;
  lastUpdated?: string;
}

export interface DriverInfo {
  id: number;
  name: string;
  phone: string;
  photo?: string;
  rating?: number;
  vehicleNumber?: string;
  // Dispatch-related fields from order details
  dispatchId?: string;
  tripNo?: string;
  route?: string;
  status?: 'IN_QUEUE' | 'ASSIGNED' | 'IN_TRANSIT' | 'COMPLETED';
}

export interface OrderPoint {
  name: string;
  address: string;
  coordinates: {
    latitude: number;
    longitude: number;
  };
  contactName?: string;
  type?: 'PICKUP' | 'DROP';
  sequence?: number;
  count?: number; // number of stops at this exact location
  eta?: string;
  status?: 'PENDING' | 'ARRIVED' | 'DEPARTED' | 'COMPLETED';
  plannedArrival?: string;
  plannedDeparture?: string;
  actualArrival?: string;
  actualDeparture?: string;
  confirmedBy?: string;
  contactPhone?: string;
  remarks?: string;
  proofImageUrl?: string;
}

export interface ShipmentSummary {
  bookingReference: string;
  orderReference: string;
  customerName: string;
  billTo: string;
  pickupLocation: string;
  deliveryLocation: string;
  pickupPoint?: OrderPoint; // Loading point with coordinates
  deliveryPoint?: OrderPoint; // Unloading point with coordinates
  serviceType: 'LTL' | 'FTL' | 'EXPRESS' | 'STANDARD';
  estimatedDelivery: string;
  actualDelivery?: string;
  status: ShipmentStatus;
  transportationOrderStatus?: string; // Raw transport order status (ASSIGNED, IN_TRANSIT, COMPLETED, etc.)
  cost?: number;
  items?: ShipmentItem[];
}

export interface ShipmentItem {
  description: string;
  quantity: number;
  uom?: string;
  pallets?: number;
  loadingPlace?: string;
  unloadingPlace?: string;
  warehouse?: string;
  weight?: number;
  dimension?: {
    length: number;
    width: number;
    height: number;
  };
}

export interface DispatchAssignment {
  dispatchId: string;
  tripNo: string;
  route: string;
  driver: DriverInfo;
  vehicle: {
    vehicleNumber: string;
    model?: string;
    capacity?: number;
  };
  status: 'IN_QUEUE' | 'ASSIGNED' | 'IN_TRANSIT' | 'COMPLETED';
  createdAt?: string;
  completedAt?: string;
}

export interface ProofOfDelivery {
  id: number;
  signature?: string;
  photo?: string;
  recipientName: string;
  deliveryTime: string;
  notes?: string;
}

export interface TrackingResponse {
  shipmentSummary: ShipmentSummary;
  timeline: StatusTimeline[];
  currentLocation?: GeoLocation;
  driver?: DriverInfo;
  proofOfDelivery?: ProofOfDelivery;
  estimatedTimeOfArrival?: string;
  // Additional order details
  pickupPoints?: OrderPoint[]; // Loading Point(s)
  deliveryPoints?: OrderPoint[]; // Unloading Point(s)
  items?: ShipmentItem[]; // Order items
  dispatches?: DispatchAssignment[]; // Multiple dispatch assignments
}

export interface TrackingError {
  code: string;
  message: string;
  details?: string;
}

export const STATUS_TIMELINE_ORDER: ShipmentStatus[] = [
  'BOOKING_CREATED',
  'ORDER_CONFIRMED',
  'PAYMENT_VERIFIED',
  'DISPATCHED',
  'IN_TRANSIT',
  'OUT_FOR_DELIVERY',
  'DELIVERED',
];

export const STATUS_DISPLAY_NAMES: Record<ShipmentStatus, string> = {
  BOOKING_CREATED: 'Booking Created',
  ORDER_CONFIRMED: 'Order Confirmed',
  PAYMENT_VERIFIED: 'Payment Verified',
  DISPATCHED: 'Dispatched',
  IN_TRANSIT: 'In Transit',
  OUT_FOR_DELIVERY: 'Out for Delivery',
  DELIVERED: 'Delivered',
  FAILED_DELIVERY: 'Delivery Failed',
  RETURNED: 'Returned',
};

export const STATUS_COLORS: Record<ShipmentStatus, string> = {
  BOOKING_CREATED: 'bg-blue-600',
  ORDER_CONFIRMED: 'bg-green-600',
  PAYMENT_VERIFIED: 'bg-green-600',
  DISPATCHED: 'bg-blue-600',
  IN_TRANSIT: 'bg-blue-600',
  OUT_FOR_DELIVERY: 'bg-orange-600',
  DELIVERED: 'bg-green-600',
  FAILED_DELIVERY: 'bg-red-600',
  RETURNED: 'bg-red-600',
};
