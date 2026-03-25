// src/app/models/vehicle.model.ts

import type { Document } from './document.model';
import type { DriverSimple } from './driver-simple.model';
import type {
  VehicleType,
  VehicleStatus,
  TruckSize,
  VehicleOwnership,
} from './enums/vehicle.enums';
import type { Inspection } from './inspection.model';
import type { ServiceHistory } from './service-history.model';

export interface Vehicle {
  // 🆔 Identity
  id?: number;
  licensePlate: string;
  vin?: string; // Vehicle Identification Number
  model: string;
  manufacturer: string;
  // Normalized field name
  yearMade?: number;
  // Legacy alias (kept for backward compatibility)
  year?: number;

  //  Specifications
  // Accept string as well to keep compatibility with older tests/fixtures
  type: VehicleType | string;
  status: VehicleStatus | string;
  ownership?: VehicleOwnership | string; // Vehicle ownership type
  // legacy alias used in some tests/fixtures
  plateNumber?: string;
  mileage: number;
  engineHours?: number;
  fuelConsumption: number;

  truckSize?: TruckSize;
  qtyPalletsCapacity?: number;

  // Zone & GPS
  assignedZoneId?: number;
  assignedZoneName?: string;
  // Legacy alias (kept for backward compatibility)
  assignedZone?: string;
  gpsDeviceId?: string;

  // 🛠 Maintenance
  lastInspectionDate?: Date;
  lastServiceDate?: Date;
  nextServiceDue?: Date;

  //  Routing
  availableRoutes?: string;
  unavailableRoutes?: string;

  // 📝 Notes
  remarks?: string;

  // 🔧 Related records (optional)
  inspections?: Inspection[];
  serviceRecords?: ServiceHistory[];
  documents?: Document[];

  //  Capacity (future expansion)
  maxWeight?: number;
  maxVolume?: number;
  palletCapacity?: number;

  // 🧑‍✈️ Optional reference
  assignedDriver?: DriverSimple;
  parentVehicleId?: number;
  // Legacy alias (kept for backward compatibility)
  assignedVehicleId?: number;
}
