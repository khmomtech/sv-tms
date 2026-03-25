import type { ApprovalStatus } from './shared/approval-status.model';

export interface FuelRequest {
  id: number;
  dispatchId: number;
  driverId?: number;
  vehicleId?: number;
  amount?: number;
  liters?: number;
  station?: string;
  receiptPaths?: string;
  status?: ApprovalStatus;
  approvedBy?: number;
  approvedAt?: string;
  createdAt?: string;
  updatedAt?: string;
}
