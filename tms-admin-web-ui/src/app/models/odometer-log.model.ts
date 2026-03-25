import type { ApprovalStatus } from './shared/approval-status.model';

export interface OdometerLog {
  id: number;
  dispatchId: number;
  driverId?: number;
  vehicleId?: number;
  startKm?: number;
  endKm?: number;
  recordedAt?: string;
  approvalStatus?: ApprovalStatus;
  approvedBy?: number;
  approvedAt?: string;
  createdAt?: string;
  updatedAt?: string;
}
