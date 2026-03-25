import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { PagedResponse } from '../models/api-response-page.model';

export type PmPlanTriggerType = 'KILOMETER' | 'DATE' | 'ENGINE_HOUR';
export type PmPlanStatus = 'ACTIVE' | 'INACTIVE';

export interface PmPlanDto {
  id?: number;
  pmName: string;
  description?: string;
  vehicleId: number;
  vehiclePlate?: string;
  vehicleType?: string;
  triggerType: PmPlanTriggerType;
  intervalKm?: number | null;
  intervalDays?: number | null;
  intervalEngineHours?: number | null;
  nextDueKm?: number | null;
  nextDueDate?: string | null;
  nextDueEngineHours?: number | null;
  lastPerformedKm?: number | null;
  lastPerformedDate?: string | null;
  lastPerformedEngineHours?: number | null;
  active?: boolean;
  maintenanceTaskTypeId?: number | null;
  maintenanceTaskTypeName?: string | null;
  createdById?: number | null;
  createdByName?: string | null;
  isDueNow?: boolean | null;
  isDueSoon?: boolean | null;
}

@Injectable({ providedIn: 'root' })
export class PmPlanV2Service {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/pm-schedules`;

  constructor(private readonly http: HttpClient) {}

  list(params: {
    vehicleId?: number;
    status?: PmPlanStatus;
    q?: string;
    page?: number;
    size?: number;
  }) {
    let p = new HttpParams();
    if (params.vehicleId) p = p.set('vehicleId', params.vehicleId);
    if (params.status) p = p.set('active', params.status === 'ACTIVE' ? 'true' : 'false');
    if (params.q) p = p.set('q', params.q);
    if (typeof params.page === 'number') p = p.set('page', String(params.page));
    if (typeof params.size === 'number') p = p.set('size', String(params.size));
    return this.http.get<PagedResponse<PmPlanDto>>(this.apiUrl, { params: p });
  }

  get(id: number) {
    return this.http.get<PmPlanDto>(`${this.apiUrl}/${id}`);
  }

  listByVehicle(vehicleId: number) {
    return this.http.get<PmPlanDto[]>(`${this.apiUrl}/vehicle/${vehicleId}`);
  }

  create(dto: PmPlanDto) {
    return this.http.post<PmPlanDto>(this.apiUrl, dto);
  }

  update(id: number, dto: Partial<PmPlanDto>) {
    return this.http.put<PmPlanDto>(`${this.apiUrl}/${id}`, dto);
  }
}
