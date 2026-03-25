import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { PagedResponse } from '../models/api-response-page.model';

export type PMIntervalType = 'MILEAGE' | 'TIME' | 'HOURS' | 'COMPLIANCE';

export interface PMTaskDto {
  id?: number;
  pmPlanId?: number;
  taskName: string;
  required?: boolean;
  notes?: string;
  sortOrder?: number;
}

export interface PreventiveMaintenancePlanDto {
  id?: number;
  vehicleId: number;
  planName: string;
  description?: string;
  intervalType: PMIntervalType;
  intervalValue: number;
  lastServiceValue?: number;
  nextDueValue?: number;
  lastServiceDate?: string;
  nextDueDate?: string;
  active?: boolean;
  createdAt?: string;
  updatedAt?: string;
  tasks?: PMTaskDto[];
  vehiclePlate?: string;
}

export interface PMExecutionLogDto {
  id?: number;
  pmPlanId?: number;
  workOrderId?: number;
  executedAt?: string;
  executedById?: number;
  executedByName?: string;
  remarks?: string;
}

@Injectable({ providedIn: 'root' })
export class PmPlanService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/maintenance/pm-plans`;

  constructor(private readonly http: HttpClient) {}

  list(params: { active?: boolean; page?: number; size?: number }) {
    let p = new HttpParams();
    if (typeof params.active === 'boolean') p = p.set('active', String(params.active));
    if (typeof params.page === 'number') p = p.set('page', String(params.page));
    if (typeof params.size === 'number') p = p.set('size', String(params.size));
    return this.http.get<ApiResponse<PagedResponse<PreventiveMaintenancePlanDto>>>(this.apiUrl, {
      params: p,
    });
  }

  get(id: number) {
    return this.http.get<ApiResponse<PreventiveMaintenancePlanDto>>(`${this.apiUrl}/${id}`);
  }

  listByVehicle(vehicleId: number) {
    return this.http.get<ApiResponse<PreventiveMaintenancePlanDto[]>>(
      `${this.apiUrl}/vehicle/${vehicleId}`,
    );
  }

  create(dto: PreventiveMaintenancePlanDto) {
    return this.http.post<ApiResponse<PreventiveMaintenancePlanDto>>(this.apiUrl, dto);
  }

  update(id: number, dto: Partial<PreventiveMaintenancePlanDto>) {
    return this.http.put<ApiResponse<PreventiveMaintenancePlanDto>>(`${this.apiUrl}/${id}`, dto);
  }

  deactivate(id: number) {
    return this.http.post<ApiResponse<void>>(`${this.apiUrl}/${id}/deactivate`, null);
  }

  dueList() {
    return this.http.get<ApiResponse<PreventiveMaintenancePlanDto[]>>(`${this.apiUrl}/due`);
  }

  calendar(from?: string, to?: string) {
    let p = new HttpParams();
    if (from) p = p.set('from', from);
    if (to) p = p.set('to', to);
    return this.http.get<ApiResponse<PreventiveMaintenancePlanDto[]>>(`${this.apiUrl}/calendar`, {
      params: p,
    });
  }

  history(id: number) {
    return this.http.get<ApiResponse<PMExecutionLogDto[]>>(`${this.apiUrl}/${id}/history`);
  }
}
