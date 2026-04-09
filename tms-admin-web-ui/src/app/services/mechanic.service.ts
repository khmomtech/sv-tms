import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { PagedResponse } from '../models/api-response-page.model';

export interface MechanicDto {
  id?: number;
  userId?: number;
  staffId?: number;
  fullName: string;
  phone?: string;
  active?: boolean;
}

@Injectable({ providedIn: 'root' })
export class MechanicService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/maintenance/mechanics`;

  constructor(private readonly http: HttpClient) {}

  list(params: { search?: string; active?: boolean; page?: number; size?: number }) {
    let p = new HttpParams();
    if (params.search) p = p.set('search', params.search);
    if (typeof params.active === 'boolean') p = p.set('active', String(params.active));
    if (typeof params.page === 'number') p = p.set('page', String(params.page));
    if (typeof params.size === 'number') p = p.set('size', String(params.size));
    return this.http.get<ApiResponse<PagedResponse<MechanicDto>>>(this.apiUrl, { params: p });
  }

  create(dto: MechanicDto) {
    return this.http.post<ApiResponse<MechanicDto>>(this.apiUrl, dto);
  }

  update(id: number, dto: Partial<MechanicDto>) {
    return this.http.put<ApiResponse<MechanicDto>>(`${this.apiUrl}/${id}`, dto);
  }

  deactivate(id: number) {
    return this.http.delete<ApiResponse<void>>(`${this.apiUrl}/${id}`);
  }
}
