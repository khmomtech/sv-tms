import { BookingStatus, BookingServiceType, BookingPaymentType } from './booking-status.enum';

export interface BookingAddress {
  addressLine: string;
  city?: string;
  province?: string;
  postalCode?: string;
  country?: string;
  contactName?: string;
  contactPhone?: string;
  companyName?: string;
}

export interface BookingPackage {
  itemType: string;
  quantity: number;
  weightKg?: number;
  volumeCbm?: number;
  cod?: number;
  description?: string;
}

export interface Booking {
  id?: number;
  bookingReference: string;
  customerId: number;
  customerName: string;
  customerPhone?: string;

  // Route information
  pickupAddress: BookingAddress;
  deliveryAddress: BookingAddress;
  routeSummary?: string; // e.g., "Phnom Penh → Siem Reap"

  // Service details
  serviceType: BookingServiceType;
  truckType?: string;
  capacity?: number;

  // Packages
  packages?: BookingPackage[];
  totalWeightTons?: number;
  totalVolumeCbm?: number;
  palletCount?: number;

  // Schedule
  pickupDate: Date | string;
  deliveryDate?: Date | string;

  // Payment
  paymentType: BookingPaymentType;
  estimatedCost?: number;

  // Status
  status: BookingStatus;

  // Special handling
  specialHandlingNotes?: string;
  requiresInsurance?: boolean;

  // Tracking
  orderId?: number; // Set when converted to order
  orderReference?: string;

  // Metadata
  createdAt?: Date | string;
  updatedAt?: Date | string;
  createdBy?: string;
  notes?: string;
}

export interface CreateBookingDto {
  customerId: number;
  pickupAddress: BookingAddress;
  deliveryAddress: BookingAddress;
  serviceType: BookingServiceType;
  pickupDate: Date | string;
  deliveryDate?: Date | string;
  paymentType: BookingPaymentType;
  packages?: BookingPackage[];
  truckType?: string;
  capacity?: number;
  totalWeightTons?: number;
  totalVolumeCbm?: number;
  palletCount?: number;
  specialHandlingNotes?: string;
  requiresInsurance?: boolean;
  estimatedCost?: number;
  notes?: string;
}

export interface UpdateBookingDto extends Partial<CreateBookingDto> {
  status?: BookingStatus;
}

export interface BookingFilter {
  searchQuery?: string;
  status?: BookingStatus;
  serviceType?: BookingServiceType;
  fromDate?: Date | string;
  toDate?: Date | string;
  customerId?: number;
}
