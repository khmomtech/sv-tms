import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { retry, timeout } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { VehicleDocument } from '../models/document.model';
import type { PagedResponse } from '../models/api-response-page.model';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root',
})
export class DocumentService {
  private readonly apiUrl = `${environment.baseUrl}/api/admin/documents`;
  private readonly REQUEST_TIMEOUT_MS = 30000;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  createDocument(payload: Partial<VehicleDocument>): Observable<ApiResponse<VehicleDocument>> {
    return this.http
      .post<ApiResponse<VehicleDocument>>(this.apiUrl, payload, { headers: this.getHeaders() })
      .pipe(timeout(this.REQUEST_TIMEOUT_MS), retry(1));
  }

  updateDocument(
    id: number,
    payload: Partial<VehicleDocument>,
  ): Observable<ApiResponse<VehicleDocument>> {
    return this.http
      .put<
        ApiResponse<VehicleDocument>
      >(`${this.apiUrl}/${id}`, payload, { headers: this.getHeaders() })
      .pipe(timeout(this.REQUEST_TIMEOUT_MS), retry(1));
  }

  deleteDocument(id: number): Observable<ApiResponse<string>> {
    return this.http
      .delete<ApiResponse<string>>(`${this.apiUrl}/${id}`, { headers: this.getHeaders() })
      .pipe(timeout(this.REQUEST_TIMEOUT_MS), retry(1));
  }

  getDocumentReport(params: {
    dateField?: string;
    from?: string;
    to?: string;
    vehicleId?: number;
    documentType?: string;
    search?: string;
    page?: number;
    size?: number;
  }): Observable<ApiResponse<PagedResponse<VehicleDocument>>> {
    const query = new URLSearchParams();
    if (params.dateField) query.append('dateField', params.dateField);
    if (params.from) query.append('from', params.from);
    if (params.to) query.append('to', params.to);
    if (params.vehicleId) query.append('vehicleId', String(params.vehicleId));
    if (params.documentType) query.append('documentType', params.documentType);
    if (params.search) query.append('search', params.search);
    if (typeof params.page === 'number') query.append('page', String(params.page));
    if (typeof params.size === 'number') query.append('size', String(params.size));

    const url = `${this.apiUrl}/report?${query.toString()}`;
    return this.http
      .get<ApiResponse<PagedResponse<VehicleDocument>>>(url, { headers: this.getHeaders() })
      .pipe(timeout(this.REQUEST_TIMEOUT_MS), retry(1));
  }
}
