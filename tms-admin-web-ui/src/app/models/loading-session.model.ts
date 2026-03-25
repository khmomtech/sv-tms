import type { DispatchStatus } from './dispatch-status.enum';
import type { LoadingDocument } from './loading-document.model';
import type { LoadingEmptiesReturn } from './loading-empties-return.model';
import type { LoadingPalletItem } from './loading-pallet-item.model';
import type { LoadingQueueStatus, WarehouseCode } from './loading-queue.model';

export interface LoadingSession {
  id: number;
  dispatchId: number;
  queueId?: number | null;
  warehouseCode: WarehouseCode;
  bay?: string | null;
  startedAt?: string | null;
  endedAt?: string | null;
  remarks?: string | null;
  dispatchStatus?: DispatchStatus;
  queueStatus?: LoadingQueueStatus | null;
  palletItems: LoadingPalletItem[];
  emptiesReturns: LoadingEmptiesReturn[];
  documents: LoadingDocument[];
}
