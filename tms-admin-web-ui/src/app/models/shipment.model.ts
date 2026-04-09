export interface Shipment {
  id?: number; // Optional for new shipments
  trackingNumber: string;
  shipmentStatus: 'PLANNED' | 'IN_TRANSIT' | 'DELIVERED' | 'RETURNED';
  assignedVehicle?: string;
  assignedDriver?: string;
  estimatedDeliveryDate?: string;
  actualDeliveryDate?: string;
  proofOfDelivery?: string; // URL for proof of delivery image or document
  loadingAddresses: Address[];
  dropAddresses: Address[];
}

export interface Address {
  id?: number;
  location: string;
  contactPerson: string;
  contactPhone: string;
  scheduledTime?: string;
}
