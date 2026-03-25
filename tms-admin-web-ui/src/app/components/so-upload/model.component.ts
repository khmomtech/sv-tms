// File: src/app/components/so-upload/transport.models.ts

export interface TruckPlan {
  truckNo: string;
  dropOff: string;
  items: number;
  qty: number;
  weight: number;
  volume: number;
  truckType: string;
  driver: string;
  contact: string;
  status: 'Ready' | 'Pending';
  estPallets: number;
  maxPallets: number;
  palletUtilization: number;
}

export interface DriverTruck {
  name: string;
  phone: string;
  licensePlate: string;
  truckType: string;
  maxWeight: number;
  maxVolume: number;
  availablePallets: number;
  status: 'Available' | 'Pending';
}

export interface SoRow {
  [key: string]: any;
  Description: string;
  'Remaining Qty': number;
  'Weight (kg)'?: number;
  'Volume (m3)'?: number;
  'Ship to Party Name'?: string;
  isError?: boolean;
}
