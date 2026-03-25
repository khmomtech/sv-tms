export interface Inspection {
  id: number;
  date: Date;
  inspectorName: string;
  remarks: string;
  vehicleId: number; // Foreign key reference to Vehicle
}
