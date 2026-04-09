import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { PagedResponse } from '../models/api-response-page.model';

export type MaintenanceRequestStatus =
  | 'DRAFT'
  | 'SUBMITTED'
  | 'APPROVED'
  | 'REJECTED'
  | 'CANCELLED';
export type Priority = 'URGENT' | 'HIGH' | 'NORMAL' | 'LOW';
export type MaintenanceRequestType = 'REPAIR' | 'EMERGENCY' | 'PM' | 'INSPECTION';
export type SafetyLevel = 'CRITICAL' | 'MAJOR' | 'MINOR';

export type MaintenanceAttachmentType = 'BEFORE' | 'AFTER' | 'ACCIDENT' | 'INVOICE' | 'OTHER';

export interface MaintenanceRequestAttachmentDto {
  id?: number;
  maintenanceRequestId?: number;
  attachmentType?: MaintenanceAttachmentType;
  fileUrl?: string;
  fileName?: string;
  mimeType?: string;
  fileSizeBytes?: number;
  description?: string;
  uploadedById?: number;
  uploadedByName?: string;
  uploadedAt?: string;
}

export interface MaintenanceRequestDto {
  id?: number;
  mrNumber?: string;
  vehicleId: number;
  vehiclePlate?: string;
  title: string;
  description?: string;
  priority?: Priority;
  status?: MaintenanceRequestStatus;
  requestType?: MaintenanceRequestType;
  safetyLevel?: SafetyLevel;
  pmPlanId?: number;
  pmPlanName?: string;
  failureCodeId?: number;
  failureCode?: string;
  failureCodeDescription?: string;
  requestedAt?: string;
  approvedAt?: string;
  rejectedAt?: string;
  approvalRemarks?: string;
  rejectionReason?: string;
  createdByName?: string;
  approvedByName?: string;
  rejectedByName?: string;
  workOrderId?: number;
  workOrderNumber?: string;
  workOrderStatus?: string;
}

@Injectable({ providedIn: 'root' })
export class MaintenanceRequestService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/maintenance/requests`;

  constructor(private readonly http: HttpClient) {}

  list(params: {
    search?: string;
    status?: MaintenanceRequestStatus;
    vehicleId?: number;
    failureCodeId?: number;
    page?: number;
    size?: number;
  }) {
    let p = new HttpParams();
    if (params.search) p = p.set('search', params.search);
    if (params.status) p = p.set('status', params.status);
    if (params.vehicleId) p = p.set('vehicleId', String(params.vehicleId));
    if (params.failureCodeId) p = p.set('failureCodeId', String(params.failureCodeId));
    if (typeof params.page === 'number') p = p.set('page', String(params.page));
    if (typeof params.size === 'number') p = p.set('size', String(params.size));

    return this.http.get<ApiResponse<PagedResponse<MaintenanceRequestDto>>>(this.apiUrl, {
      params: p,
    });
  }

  get(id: number) {
    return this.http.get<ApiResponse<MaintenanceRequestDto>>(`${this.apiUrl}/${id}`);
  }

  create(dto: MaintenanceRequestDto) {
    return this.http.post<ApiResponse<MaintenanceRequestDto>>(this.apiUrl, dto);
  }

  update(id: number, dto: Partial<MaintenanceRequestDto>) {
    return this.http.put<ApiResponse<MaintenanceRequestDto>>(`${this.apiUrl}/${id}`, dto);
  }

  approve(id: number, remarks?: string) {
    let p = new HttpParams();
    if (remarks) p = p.set('remarks', remarks);
    return this.http.post<ApiResponse<MaintenanceRequestDto>>(
      `${this.apiUrl}/${id}/approve`,
      null,
      { params: p },
    );
  }

  reject(id: number, reason?: string) {
    let p = new HttpParams();
    if (reason) p = p.set('reason', reason);
    return this.http.post<ApiResponse<MaintenanceRequestDto>>(`${this.apiUrl}/${id}/reject`, null, {
      params: p,
    });
  }

  delete(id: number) {
    return this.http.delete<ApiResponse<void>>(`${this.apiUrl}/${id}`);
  }

  listAttachments(requestId: number) {
    return this.http.get<ApiResponse<MaintenanceRequestAttachmentDto[]>>(
      `${environment.apiBaseUrl}/admin/maintenance/requests/${requestId}/attachments`,
    );
  }

  uploadAttachment(
    requestId: number,
    file: File,
    attachmentType: MaintenanceAttachmentType,
    description?: string,
  ) {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('type', attachmentType);
    if (description) formData.append('description', description);
    return this.http.post<ApiResponse<MaintenanceRequestAttachmentDto>>(
      `${environment.apiBaseUrl}/admin/maintenance/requests/${requestId}/attachments`,
      formData,
    );
  }

  deleteAttachment(requestId: number, attachmentId: number) {
    return this.http.delete<ApiResponse<void>>(
      `${environment.apiBaseUrl}/admin/maintenance/requests/${requestId}/attachments/${attachmentId}`,
    );
  }
}
