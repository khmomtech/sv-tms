import type { DispatchItem } from './dispatch-item.model';
import type { DispatchStatus } from './dispatch-status.enum';
import type { DispatchStop } from './dispatch-stop.model';

export interface Dispatch {
  showMenu: boolean;
  transportOrder: any;

  // Basic Info
  id?: number;
  routeCode?: string;
  tripNo?: string;
  startTime: Date | string;
  estimatedArrival: Date | string;
  expectedDelivery?: Date | string;
  status: DispatchStatus;
  tripType?: string;
  loadingTypeCode?: string;
  safetyStatus?: string;
  preEntrySafetyRequired?: boolean;
  preEntrySafetyStatus?: string;

  // Transport Order Info
  transportOrderId: number;
  orderReference: string;

  // Customer Info (Short)
  customerId?: number;
  customerName?: string;
  customerPhone?: string;

  // Driver Info
  driverId: number;
  driverName: string;
  driverPhone: string;

  // Vehicle Info
  vehicleId: number;
  licensePlate: string;

  // User Info
  createdBy: number;
  createdByUsername: string;
  createdDate: Date | string;
  updatedDate?: Date | string;
  deliveryDate?: Date | string;

  // Pickup Details
  pickupName?: string;
  pickupLocation?: string;
  pickupLat?: number;
  pickupLng?: number;

  // Drop-off Details
  dropoffName?: string;
  dropoffLocation?: string;
  dropoffLat?: number;
  dropoffLng?: number;
  // Flattened labels for UI
  from?: any;
  to?: any;

  // Route & Items
  stops?: DispatchStop[];
  items?: DispatchItem[];

  // Cancellation
  cancelReason?: string;

  // Proofs: Load
  loadingProofImages?: string[];
  loadingSignature?: string;
  loadingUploadedBy?: string;
  loadingUploadedAt?: Date | string;

  // Proofs: Unload
  unloadingProofImages?: string[];
  unloadingSignature?: string;
  unloadingUploadedBy?: string;
  unloadingUploadedAt?: Date | string;

  // Tracking
  lastLocation?: {
    lat: number;
    lng: number;
    timestamp: string;
  };
  locationLogs?: {
    lat: number;
    lng: number;
    timestamp: string;
  }[];
}
