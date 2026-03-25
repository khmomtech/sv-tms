import type { OrderAddressDto } from './order-address.model';

export interface OrderItemDto {
  id: number;
  itemId: number;
  itemCode?: string; // Optional, for display/tracking
  itemName: string;
  itemNameKh?: string;
  quantity: number;
  unitOfMeasurement: string;
  palletType?: string;
  size?: string;
  weight?: string; // Keep as string to match DB model
  dimensions?: string; // Optional: custom transport dimensions
  pickupAddress?: OrderAddressDto | null;
  dropAddress?: OrderAddressDto | null;
  fromDestination?: string;
  toDestination?: string;
  warehouse?: string;
  department?: string;
}
