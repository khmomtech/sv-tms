// src/app/models/vehicle-setup.model.ts

import type { VehicleType, VehicleOwnership, TruckSize } from './enums/vehicle.enums';

export interface VehicleSetupRequest {
  // Basic Vehicle Information
  licensePlate: string;
  vin?: string;
  model: string;
  manufacturer: string;
  yearMade?: number;
  // Legacy alias (kept for backward compatibility)
  year?: number;
  type: VehicleType | string;
  ownership: VehicleOwnership | string;
  truckSize?: TruckSize | string;

  // Capacity Information
  maxWeight?: number;
  maxVolume?: number;
  fuelConsumption: number;
  mileage: number;
  qtyPalletsCapacity?: number;

  // Operational Information
  assignedZoneId?: number;
  assignedZoneName?: string;
  // Legacy alias (kept for backward compatibility)
  assignedZone?: string;
  requiredLicenseClass?: string;
  gpsDeviceId?: string;
  remarks?: string;

  // Documents
  documents?: VehicleDocumentRequest[];

  // Maintenance Policy
  maintenancePolicy?: MaintenancePolicyRequest;
}

export interface VehicleDocumentRequest {
  vehicleId?: number;
  documentType: string;
  documentUrl: string;
  documentNumber?: string;
  issueDate?: string; // ISO date string
  expiryDate?: string; // ISO date string
  approved?: boolean;
  notes?: string;
}

export interface MaintenancePolicyRequest {
  schedules: PMScheduleRequest[];
}

export interface PMScheduleRequest {
  scheduleName: string;
  description?: string;
  triggerType: PMTriggerType | string;
  triggerInterval: number;
  reminderBeforeKm?: number;
  reminderBeforeDays?: number;
  taskTypeId: number;
}

export enum PMTriggerType {
  MILEAGE = 'MILEAGE',
  TIME_BASED = 'TIME_BASED',
  BOTH = 'BOTH',
}
