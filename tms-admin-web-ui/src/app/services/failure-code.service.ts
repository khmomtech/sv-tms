import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { PagedResponse } from '../models/api-response-page.model';

export interface FailureCodeDto {
  id?: number;
  code: string;
  description?: string;
  category?: string;
  active?: boolean;
}

@Injectable({ providedIn: 'root' })
export class FailureCodeService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/maintenance/failure-codes`;

  constructor(private readonly http: HttpClient) {}

  list(params: { active?: boolean; page?: number; size?: number }) {
    let p = new HttpParams();
    if (typeof params.active === 'boolean') p = p.set('active', String(params.active));
    if (typeof params.page === 'number') p = p.set('page', String(params.page));
    if (typeof params.size === 'number') p = p.set('size', String(params.size));
    return this.http.get<ApiResponse<PagedResponse<FailureCodeDto>>>(this.apiUrl, { params: p });
  }

  listActive() {
    return this.http.get<ApiResponse<FailureCodeDto[]>>(`${this.apiUrl}/active`);
  }

  get(id: number) {
    return this.http.get<ApiResponse<FailureCodeDto>>(`${this.apiUrl}/${id}`);
  }

  create(dto: FailureCodeDto) {
    return this.http.post<ApiResponse<FailureCodeDto>>(this.apiUrl, dto);
  }

  update(id: number, dto: Partial<FailureCodeDto>) {
    return this.http.put<ApiResponse<FailureCodeDto>>(`${this.apiUrl}/${id}`, dto);
  }

  deactivate(id: number) {
    return this.http.post<ApiResponse<void>>(`${this.apiUrl}/${id}/deactivate`, null);
  }
}
