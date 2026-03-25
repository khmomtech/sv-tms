import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type {
  PreLoadingSafetyCheck,
  PreLoadingSafetyCheckRequest,
} from '../models/pre-loading-safety-check.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class SafetyCheckService {
  private readonly apiUrl = `${environment.baseUrl}/api/pre-loading-safety`;

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  private headers(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  submitCheck(
    payload: PreLoadingSafetyCheckRequest,
  ): Observable<ApiResponse<PreLoadingSafetyCheck>> {
    return this.http.post<ApiResponse<PreLoadingSafetyCheck>>(this.apiUrl, payload, {
      headers: this.headers(),
    });
  }

  latest(dispatchId: number): Observable<PreLoadingSafetyCheck> {
    return this.http
      .get<ApiResponse<PreLoadingSafetyCheck>>(`${this.apiUrl}/latest/${dispatchId}`, {
        headers: this.headers(),
      })
      .pipe(map((res) => res.data));
  }

  downloadPdf(dispatchId: number): Observable<Blob> {
    const token = this.authService.getToken();
    return this.http.get(`${this.apiUrl}/pdf/${dispatchId}`, {
      headers: new HttpHeaders({
        Authorization: `Bearer ${token}`,
      }),
      responseType: 'blob',
    });
  }
}
