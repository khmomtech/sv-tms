import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { PagedResponse } from '../models/api-response-page.model';

export type PmRunStatus =
  | 'DUE'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'SKIPPED'
  | 'RESCHEDULED'
  | 'CANCELLED';

export type PmRunTriggeredBy = 'KM' | 'DATE' | 'MONTHLY' | 'ANNUAL' | 'FIXED_DATE' | 'EVENT';
export type PmDueStatus = 'OK' | 'DUE_SOON' | 'OVERDUE';

export interface PmRunChecklistResultDto {
  id?: number;
  pmRunId?: number;
  checklistItemId: number;
  checkedBool?: boolean;
  valueText?: string;
  valueNumber?: number;
  photoUrl?: string;
  createdAt?: string;
}

export interface PmRunAttachmentDto {
  id?: number;
  pmRunId?: number;
  fileUrl: string;
  fileType?: string;
  uploadedById?: number;
  uploadedByName?: string;
  uploadedAt?: string;
}

export interface PmChecklistItemDto {
  checklistItemId: number;
  templateId?: number;
  seq?: number;
  label: string;
  required?: boolean;
  inputType?: 'CHECK' | 'TEXT' | 'NUMBER' | 'PHOTO';
}

export interface PmStatusLogDto {
  id?: number;
  entityType?: string;
  entityId?: string;
  oldStatus?: string;
  newStatus?: string;
  changedById?: number;
  changedByName?: string;
  changedAt?: string;
  note?: string;
}

export interface PmRunDto {
  pmRunId?: number;
  pmPlanId?: number;
  planName?: string;
  itemCode?: string;
  itemName?: string;
  vehicleId?: number;
  vehiclePlate?: string;
  triggeredBy?: PmRunTriggeredBy;
  dueDate?: string;
  dueKm?: number;
  generatedAt?: string;
  status?: PmRunStatus;
  performedAt?: string;
  performedById?: number;
  performedByName?: string;
  notes?: string;
  skipReason?: string;
  rescheduledToDate?: string;
  rescheduledToKm?: number;
  relatedWoId?: number;
  relatedWoNumber?: string;
  attachmentsCount?: number;
  createdAt?: string;
  updatedAt?: string;
  overdue?: boolean;
  daysOverdue?: number;
  kmOverdue?: number;
  dueStatus?: PmDueStatus;
  triggerExplanation?: string;
  checklistItems?: PmChecklistItemDto[];
  checklistResults?: PmRunChecklistResultDto[];
  attachments?: PmRunAttachmentDto[];
  statusLogs?: PmStatusLogDto[];
}

export interface PmRunCompleteRequest {
  performedAt?: string;
  performedKm?: number;
  notes?: string;
  checklistResults?: PmRunChecklistResultDto[];
  attachments?: PmRunAttachmentDto[];
}

export interface PmRunRescheduleRequest {
  rescheduledToDate?: string;
  rescheduledToKm?: number;
  note?: string;
}

export interface PmRunSkipRequest {
  skipReason: string;
}

@Injectable({ providedIn: 'root' })
export class PmRunService {
  private readonly adminUrl = `${environment.apiBaseUrl}/admin/pm/runs`;
  private readonly workshopUrl = `${environment.apiBaseUrl}/workshop/pm/runs`;

  constructor(private readonly http: HttpClient) {}

  list(params: {
    status?: PmRunStatus;
    vehicleId?: number;
    from?: string;
    to?: string;
    overdue?: boolean;
    page?: number;
    size?: number;
  }) {
    let p = new HttpParams();
    if (params.status) p = p.set('status', params.status);
    if (params.vehicleId) p = p.set('vehicleId', params.vehicleId);
    if (params.from) p = p.set('from', params.from);
    if (params.to) p = p.set('to', params.to);
    if (typeof params.overdue === 'boolean') p = p.set('overdue', String(params.overdue));
    if (typeof params.page === 'number') p = p.set('page', String(params.page));
    if (typeof params.size === 'number') p = p.set('size', String(params.size));
    return this.http.get<ApiResponse<PagedResponse<PmRunDto>>>(this.adminUrl, { params: p });
  }

  generate(lookaheadDays = 7) {
    return this.http.post<ApiResponse<PmRunDto[]>>(`${this.adminUrl}/generate`, { lookaheadDays });
  }

  get(id: number) {
    return this.http.get<ApiResponse<PmRunDto>>(`${this.adminUrl}/${id}`);
  }

  createWorkOrder(id: number) {
    return this.http.post<ApiResponse<PmRunDto>>(`${this.adminUrl}/${id}/create-wo`, null);
  }

  start(id: number) {
    return this.http.post<ApiResponse<PmRunDto>>(`${this.workshopUrl}/${id}/start`, null);
  }

  complete(id: number, payload: PmRunCompleteRequest) {
    return this.http.post<ApiResponse<PmRunDto>>(`${this.workshopUrl}/${id}/complete`, payload);
  }

  skip(id: number, payload: PmRunSkipRequest) {
    return this.http.post<ApiResponse<PmRunDto>>(`${this.workshopUrl}/${id}/skip`, payload);
  }

  reschedule(id: number, payload: PmRunRescheduleRequest) {
    return this.http.post<ApiResponse<PmRunDto>>(`${this.workshopUrl}/${id}/reschedule`, payload);
  }

  uploadAttachment(id: number, file: File, fileType?: string) {
    const form = new FormData();
    form.append('file', file);
    if (fileType) form.append('fileType', fileType);
    return this.http.post<ApiResponse<PmRunAttachmentDto>>(
      `${this.workshopUrl}/${id}/attachments`,
      form,
    );
  }
}
