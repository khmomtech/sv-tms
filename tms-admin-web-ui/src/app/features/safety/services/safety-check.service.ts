import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import type { ApiResponse, PagedResponse, SafetyCheck } from '../models/safety-check.model';

export interface SafetyListFilter {
  search?: string;
  from?: string;
  to?: string;
  status?: string;
  risk?: string;
  page?: number;
  size?: number;
}

@Injectable({
  providedIn: 'root',
})
export class SafetyCheckService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiBaseUrl}/admin/safety-checks`;

  list(filter: SafetyListFilter): Observable<ApiResponse<PagedResponse<SafetyCheck>>> {
    let params = new HttpParams();
    if (filter.search) params = params.set('search', filter.search);
    if (filter.from) params = params.set('from', filter.from);
    if (filter.to) params = params.set('to', filter.to);
    if (filter.status) params = params.set('status', filter.status);
    if (filter.risk) params = params.set('risk', filter.risk);
    params = params.set('page', String(filter.page ?? 0));
    params = params.set('size', String(filter.size ?? 20));

    return this.http.get<ApiResponse<PagedResponse<SafetyCheck>>>(this.baseUrl, { params });
  }

  getById(id: number): Observable<ApiResponse<SafetyCheck>> {
    return this.http.get<ApiResponse<SafetyCheck>>(`${this.baseUrl}/${id}`);
  }

  approve(id: number, riskOverride?: string): Observable<ApiResponse<SafetyCheck>> {
    return this.http.post<ApiResponse<SafetyCheck>>(`${this.baseUrl}/${id}/approve`, {
      riskOverride: riskOverride || null,
    });
  }

  reject(id: number, reason: string): Observable<ApiResponse<SafetyCheck>> {
    return this.http.post<ApiResponse<SafetyCheck>>(`${this.baseUrl}/${id}/reject`, {
      reason,
    });
  }

  exportCsv(filter: Omit<SafetyListFilter, 'page' | 'size'>): Observable<Blob> {
    let params = new HttpParams();
    if (filter.search) params = params.set('search', filter.search);
    if (filter.from) params = params.set('from', filter.from);
    if (filter.to) params = params.set('to', filter.to);
    if (filter.status) params = params.set('status', filter.status);
    if (filter.risk) params = params.set('risk', filter.risk);

    return this.http.get(`${this.baseUrl}/export/csv`, { params, responseType: 'blob' });
  }

  exportExcel(filter: Omit<SafetyListFilter, 'page' | 'size'>): Observable<Blob> {
    let params = new HttpParams();
    if (filter.search) params = params.set('search', filter.search);
    if (filter.from) params = params.set('from', filter.from);
    if (filter.to) params = params.set('to', filter.to);
    if (filter.status) params = params.set('status', filter.status);
    if (filter.risk) params = params.set('risk', filter.risk);

    return this.http.get(`${this.baseUrl}/export/xlsx`, { params, responseType: 'blob' });
  }
}
