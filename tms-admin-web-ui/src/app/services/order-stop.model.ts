import { OrderAddressDto } from './order-address.model';

export interface Stop {
  id: number;
  type: 'PICKUP' | 'DROP';
  transportOrderId: number;
  address: {
    id: number;
    name: string;
    address: string;
    city: string;
    country: string;
    longitude: number;
    latitude: number;
    type: string;
    customerId: number;
  };
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
