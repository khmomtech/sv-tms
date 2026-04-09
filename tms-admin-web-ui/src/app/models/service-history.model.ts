export interface ServiceHistory {
  id: number;
  serviceDate: Date;
  description: string;
  cost: number;
  vehicleId: number; // Foreign key reference to Vehicle
}
