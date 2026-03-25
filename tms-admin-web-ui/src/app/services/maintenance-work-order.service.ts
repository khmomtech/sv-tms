import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';

export type RepairType = 'OWN' | 'VENDOR';
export type WorkOrderType = 'PREVENTIVE' | 'REPAIR' | 'EMERGENCY' | 'INSPECTION';
export type WorkOrderStatus = 'OPEN' | 'IN_PROGRESS' | 'WAITING_PARTS' | 'COMPLETED' | 'CANCELLED';
export type Priority = 'URGENT' | 'HIGH' | 'NORMAL' | 'LOW';

export interface WorkOrderDto {
  id?: number;
  woNumber?: string;
  vehicleId?: number;
  vehiclePlate?: string;
  type?: WorkOrderType;
  priority?: Priority;
  status?: WorkOrderStatus;
  title?: string;
  description?: string;
  notes?: string;
  createdAt?: string;
  scheduledDate?: string;
  completedAt?: string;
  estimatedCost?: number;
  actualCost?: number;
  laborCost?: number;
  partsCost?: number;
  requiresApproval?: boolean;
  approved?: boolean;
  approvedAt?: string;
  approvedByName?: string;

  maintenanceRequestId?: number;
  maintenanceRequestNumber?: string;
  repairType?: RepairType;
  pmPlanId?: number;
  pmPlanName?: string;
  failureCodeId?: number;
  failureCode?: string;
  failureCodeDescription?: string;

  tasks?: WorkOrderTaskDto[];
  parts?: WorkOrderPartDto[];
  photos?: WorkOrderPhotoDto[];

  vendorQuotation?: VendorQuotationDto;
  invoice?: InvoiceDto;
}

export interface WorkOrderTaskDto {
  id?: number;
  workOrderId: number;
  taskName: string;
  description?: string;
  status?: string;
  assignedTechnicianId?: number;
  assignedTechnicianName?: string;
  estimatedHours?: number;
  actualHours?: number;
  diagnosisResult?: string;
  actionsTaken?: string;
  completedAt?: string;
  startedAt?: string;
  updatedAt?: string;
  notes?: string;
}

export interface WorkOrderPartDto {
  id?: number;
  workOrderId: number;
  taskId?: number;
  partId: number;
  partCode?: string;
  partName?: string;
  quantity?: number;
  unitPrice?: number;
  totalCost?: number;
  notes?: string;
  addedAt?: string;
  addedById?: number;
  addedByName?: string;
}

export interface WorkOrderPhotoDto {
  id?: number;
  workOrderId?: number;
  taskId?: number;
  photoUrl?: string;
  photoType?: 'BEFORE' | 'AFTER' | 'DIAGNOSTIC' | 'ACCIDENT' | 'OTHER' | string;
  description?: string;
  uploadedAt?: string;
  uploadedById?: number;
  uploadedByName?: string;
}

export interface VendorQuotationDto {
  id?: number;
  workOrderId?: number;
  vendorId: number;
  vendorName?: string;
  quotationNumber?: string;
  amount?: string; // backend uses BigDecimal; send as string to preserve precision
  status?: 'DRAFT' | 'SUBMITTED' | 'APPROVED' | 'REJECTED';
  notes?: string;
}

export interface InvoiceDto {
  id?: number;
  transportOrderId?: number;
  workOrderId?: number;
  invoiceDate?: string;
  totalAmount?: string;
  paymentStatus?: 'PAID' | 'UNPAID' | 'PARTIAL';
}

export interface InvoiceAttachmentDto {
  id?: number;
  invoiceId?: number;
  attachmentType?: 'INVOICE' | 'OTHER';
  fileUrl?: string;
  fileName?: string;
  mimeType?: string;
  fileSizeBytes?: number;
  description?: string;
  uploadedById?: number;
  uploadedByName?: string;
  uploadedAt?: string;
}

export interface PaymentDto {
  id?: number;
  invoiceId?: number;
  amount: string;
  method?: string;
  referenceNo?: string;
  notes?: string;
}

@Injectable({ providedIn: 'root' })
export class MaintenanceWorkOrderService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/maintenance/work-orders`;
  private readonly maintenanceBaseUrl = `${environment.apiBaseUrl}/admin/maintenance`;
  private readonly legacyWorkOrdersUrl = `${environment.apiBaseUrl}/admin/work-orders`;
  private readonly maintenanceQueryUrl = `${environment.apiBaseUrl}/maintenance/work-orders`;

  constructor(private readonly http: HttpClient) {}

  // List work orders using existing SV endpoint (pagination-ready).
  listLegacy(params: {
    status?: WorkOrderStatus;
    type?: WorkOrderType;
    priority?: Priority;
    vehicleId?: number;
    technicianId?: number;
    page?: number;
    size?: number;
  }) {
    let p = new HttpParams();
    if (params.status) p = p.set('status', params.status);
    if (params.type) p = p.set('type', params.type);
    if (params.priority) p = p.set('priority', params.priority);
    if (params.vehicleId) p = p.set('vehicleId', String(params.vehicleId));
    if (params.technicianId) p = p.set('technicianId', String(params.technicianId));
    if (typeof params.page === 'number') p = p.set('page', String(params.page));
    if (typeof params.size === 'number') p = p.set('size', String(params.size));
    return this.http.get<any>(`${this.maintenanceQueryUrl}/filter`, { params: p });
  }

  getLegacy(id: number) {
    return this.http.get<any>(`${this.legacyWorkOrdersUrl}/${id}`);
  }

  addTask(workOrderId: number, dto: WorkOrderTaskDto) {
    return this.http.post<any>(`${this.legacyWorkOrdersUrl}/${workOrderId}/tasks`, dto);
  }

  updateTask(workOrderId: number, taskId: number, dto: Partial<WorkOrderTaskDto>) {
    return this.http.put<any>(`${this.legacyWorkOrdersUrl}/${workOrderId}/tasks/${taskId}`, dto);
  }

  deleteTask(workOrderId: number, taskId: number) {
    return this.http.delete<any>(`${this.legacyWorkOrdersUrl}/${workOrderId}/tasks/${taskId}`);
  }

  addPart(workOrderId: number, dto: WorkOrderPartDto) {
    return this.http.post<any>(`${this.legacyWorkOrdersUrl}/${workOrderId}/parts`, dto);
  }

  deletePart(workOrderId: number, partId: number) {
    return this.http.delete<any>(`${this.legacyWorkOrdersUrl}/${workOrderId}/parts/${partId}`);
  }

  addPhoto(workOrderId: number, dto: WorkOrderPhotoDto) {
    return this.http.post<any>(`${this.legacyWorkOrdersUrl}/${workOrderId}/photos`, dto);
  }

  uploadPhoto(
    workOrderId: number,
    file: File,
    photoType: WorkOrderPhotoDto['photoType'],
    description?: string,
    taskId?: number,
  ) {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('photoType', photoType || 'OTHER');
    if (description) formData.append('description', description);
    if (typeof taskId === 'number') formData.append('taskId', String(taskId));
    return this.http.post<any>(
      `${this.legacyWorkOrdersUrl}/${workOrderId}/photos/upload`,
      formData,
    );
  }

  deletePhoto(workOrderId: number, photoId: number) {
    return this.http.delete<any>(`${this.legacyWorkOrdersUrl}/${workOrderId}/photos/${photoId}`);
  }

  updateLegacy(id: number, dto: Partial<WorkOrderDto>) {
    return this.http.put<WorkOrderDto>(`${this.legacyWorkOrdersUrl}/${id}`, dto);
  }

  createFromMaintenanceRequest(maintenanceRequestId: number, dto: WorkOrderDto) {
    return this.http.post<ApiResponse<WorkOrderDto>>(
      `${this.apiUrl}/from-request/${maintenanceRequestId}`,
      dto,
    );
  }

  assignMechanics(workOrderId: number, mechanicIds: number[]) {
    return this.http.post<ApiResponse<WorkOrderDto>>(`${this.apiUrl}/${workOrderId}/mechanics`, {
      mechanicIds,
    });
  }

  upsertVendorQuotation(workOrderId: number, dto: VendorQuotationDto) {
    return this.http.post<ApiResponse<VendorQuotationDto>>(
      `${this.apiUrl}/${workOrderId}/vendor-quotation`,
      dto,
    );
  }

  approveVendorQuotation(workOrderId: number) {
    return this.http.post<ApiResponse<VendorQuotationDto>>(
      `${this.apiUrl}/${workOrderId}/vendor-quotation/approve`,
      null,
    );
  }

  rejectVendorQuotation(workOrderId: number, reason?: string) {
    let p = new HttpParams();
    if (reason) p = p.set('reason', reason);
    return this.http.post<ApiResponse<VendorQuotationDto>>(
      `${this.apiUrl}/${workOrderId}/vendor-quotation/reject`,
      null,
      { params: p },
    );
  }

  createInvoice(workOrderId: number, dto: InvoiceDto) {
    return this.http.post<ApiResponse<InvoiceDto>>(`${this.apiUrl}/${workOrderId}/invoice`, dto);
  }

  listInvoiceAttachments(invoiceId: number) {
    return this.http.get<ApiResponse<InvoiceAttachmentDto[]>>(
      `${this.maintenanceBaseUrl}/invoices/${invoiceId}/attachments`,
    );
  }

  uploadInvoiceAttachment(
    invoiceId: number,
    file: File,
    attachmentType: 'INVOICE' | 'OTHER' = 'INVOICE',
    description?: string,
  ) {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('type', attachmentType);
    if (description) formData.append('description', description);
    return this.http.post<ApiResponse<InvoiceAttachmentDto>>(
      `${this.maintenanceBaseUrl}/invoices/${invoiceId}/attachments`,
      formData,
    );
  }

  deleteInvoiceAttachment(invoiceId: number, attachmentId: number) {
    return this.http.delete<ApiResponse<void>>(
      `${this.maintenanceBaseUrl}/invoices/${invoiceId}/attachments/${attachmentId}`,
    );
  }

  recordPayment(invoiceId: number, dto: PaymentDto) {
    return this.http.post<ApiResponse<PaymentDto>>(
      `${this.apiUrl}/invoices/${invoiceId}/payments`,
      dto,
    );
  }

  complete(workOrderId: number) {
    return this.http.post<ApiResponse<WorkOrderDto>>(
      `${this.apiUrl}/${workOrderId}/complete`,
      null,
    );
  }
}
