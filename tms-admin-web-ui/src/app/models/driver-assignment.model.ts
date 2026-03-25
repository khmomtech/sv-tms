import type { Driver } from './driver.model';
import type { Vehicle } from './vehicle.model';

export interface DriverAssignment {
  id: number;
  driverId: number;
  driverName?: string | null;
  vehicleId: number | null;
  vehicleLicensePlate?: string | null;
  assignedAt?: string | null;
  completedAt?: string | null;
  unassignedAt?: string | null;
  status: 'ACTIVE' | 'ASSIGNED' | 'CANCELED' | 'COMPLETED' | 'EXPIRED' | 'UNASSIGNED';
  assignmentType?: 'PERMANENT' | 'TEMPORARY' | null;
  reason?: string | null;
  driver?: Driver;
  vehicle?: Vehicle;
}
