import type { ApprovalStatus } from './shared/approval-status.model';

export interface CodSettlement {
  id: number;
  dispatchId: number;
  amount?: number;
  currency?: string;
  collectedBy?: number;
  collectedAt?: string;
  status?: ApprovalStatus;
  approvedBy?: number;
  approvedAt?: string;
  createdAt?: string;
  updatedAt?: string;
}
