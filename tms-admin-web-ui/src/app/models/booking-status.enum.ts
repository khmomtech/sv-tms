export enum BookingStatus {
  BOOKING_CREATED = 'BOOKING_CREATED',
  CONFIRMED = 'CONFIRMED',
  CONVERTED_TO_ORDER = 'CONVERTED_TO_ORDER',
  CANCELLED = 'CANCELLED',
}

export enum BookingServiceType {
  FTL = 'FTL', // Full Truck Load
  LTL = 'LTL', // Less Than Truck Load
  EXPRESS = 'EXPRESS',
  STANDARD = 'STANDARD',
}

export enum BookingPaymentType {
  COD = 'COD', // Cash on Delivery
  CREDIT = 'CREDIT',
  PREPAID = 'PREPAID',
}

export function getBookingStatusLabel(status: BookingStatus): string {
  const labels: Record<BookingStatus, string> = {
    [BookingStatus.BOOKING_CREATED]: 'Booking Created',
    [BookingStatus.CONFIRMED]: 'Confirmed',
    [BookingStatus.CONVERTED_TO_ORDER]: 'Converted to Order',
    [BookingStatus.CANCELLED]: 'Cancelled',
  };
  return labels[status] || status;
}

export function getBookingStatusColor(status: BookingStatus): {
  bg: string;
  text: string;
} {
  const colors: Record<BookingStatus, { bg: string; text: string }> = {
    [BookingStatus.BOOKING_CREATED]: { bg: 'bg-blue-100', text: 'text-blue-700' },
    [BookingStatus.CONFIRMED]: { bg: 'bg-green-100', text: 'text-green-700' },
    [BookingStatus.CONVERTED_TO_ORDER]: { bg: 'bg-purple-100', text: 'text-purple-700' },
    [BookingStatus.CANCELLED]: { bg: 'bg-red-100', text: 'text-red-700' },
  };
  return colors[status] || { bg: 'bg-slate-100', text: 'text-slate-700' };
}
