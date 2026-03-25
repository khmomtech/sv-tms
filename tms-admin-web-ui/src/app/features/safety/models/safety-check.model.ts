export interface SafetyCheckItem {
  id?: number;
  category?: string;
  itemKey?: string;
  itemLabelKm?: string;
  result?: string;
  severity?: string;
  remark?: string;
  createdAt?: string;
}

export interface SafetyCheckAttachment {
  id?: number;
  itemId?: number;
  fileUrl?: string;
  fileName?: string;
  mimeType?: string;
  createdAt?: string;
}

export interface SafetyCheckAudit {
  id?: number;
  action?: string;
  actorRole?: string;
  message?: string;
  createdAt?: string;
}

export interface SafetyCheck {
  id?: number;
  checkDate?: string;
  shift?: string;
  driverId?: number;
  driverName?: string;
  vehicleId?: number;
  vehiclePlate?: string;
  status?: string;
  riskLevel?: string;
  riskOverride?: string;
  submittedAt?: string;
  approvedAt?: string;
  approvedBy?: number;
  approvedByName?: string;
  rejectReason?: string;
  notes?: string;
  gpsLat?: number;
  gpsLng?: number;
  createdAt?: string;
  updatedAt?: string;
  items?: SafetyCheckItem[];
  attachments?: SafetyCheckAttachment[];
  audits?: SafetyCheckAudit[];
}

export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
}

export interface PagedResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}
