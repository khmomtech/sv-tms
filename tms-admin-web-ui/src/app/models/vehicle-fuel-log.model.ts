export interface VehicleFuelLog {
  id?: number;
  vehicleId: number;
  vehiclePlate?: string;
  filledAt?: string;
  odometerKm?: number;
  liters?: number;
  amount?: number;
  station?: string;
  notes?: string;
  createdById?: number;
  createdByName?: string;
  createdAt?: string;
  updatedAt?: string;
}
