import type { DispatchStatus } from './dispatch-status.enum';

export type LoadingQueueStatus = 'WAITING' | 'CALLED' | 'LOADING' | 'LOADED' | string;
export type WarehouseCode = 'KHB' | 'W1' | 'W2' | 'W3';

export interface LoadingQueue {
  id: number;
  dispatchId: number;
  routeCode?: string;
  deliveryDate?: string | null;
  driverName?: string | null;
  driverPhone?: string | null;
  driverLicense?: string | null;
  truckPlate?: string | null;
  from?: string | null;
  to?: string | null;
  eta?: string | null;
  route?: string | null;
  statusText?: string | null;
  safetyStatus?: 'PASSED' | 'FAILED' | 'PENDING' | null;
  warehouseCode: WarehouseCode;
  status: LoadingQueueStatus;
  dispatchStatusRaw?: string | null;
  queuePosition?: number;
  bay?: string | null;
  remarks?: string | null;
  calledAt?: string | null;
  loadingStartedAt?: string | null;
  loadingCompletedAt?: string | null;
  dispatchStatus?: DispatchStatus;
  customerName?: string | null;
  createdDate?: string;
  updatedDate?: string;
}
