/* eslint-disable @typescript-eslint/consistent-type-imports */
import type { HttpErrorResponse } from '@angular/common/http';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { environment } from '../../environments/environment';
import { AuthService } from '../../services/auth.service';
import type { DispatchDayReportRow } from '../models/dispatch-day-report-row';

export interface DispatchDayOpts {
  fromTime?: string; // "HH:mm" or "HH:mm:ss"
  toTime?: string; // "HH:mm" or "HH:mm:ss"
  toExtraDays?: number; // default 2 (server default) when toTime not provided
}

@Injectable({ providedIn: 'root' })
export class ReportsService {
  private readonly apiUrl = `${environment.baseUrl}/api/admin/reports`;

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  // ===== Helpers (match your code style) =====
  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  private setIf(params: HttpParams, key: string, val?: string | number | null): HttpParams {
    if (val === undefined || val === null) return params;
    const s = String(val).trim();
    return s ? params.set(key, s) : params;
  }

  private buildParams(planFrom: string, planTo: string, opts?: DispatchDayOpts): HttpParams {
    let params = new HttpParams();
    params = this.setIf(params, 'planFrom', planFrom);
    params = this.setIf(params, 'planTo', planTo);
    if (opts) {
      params = this.setIf(params, 'fromTime', opts.fromTime);
      params = this.setIf(params, 'toTime', opts.toTime);
      if (opts.toExtraDays != null) params = params.set('toExtraDays', String(opts.toExtraDays));
    }
    return params;
  }

  private handleError(error: HttpErrorResponse) {
    console.error('[ReportsService] API Error:', error);
    const message =
      error?.error?.message || error?.message || 'Something went wrong. Please try again later.';
    return throwError(() => new Error(message));
  }

  // ===== Dispatch Day Report =====

  /**
   * Fetch Dispatch Day Report rows (JSON).
   * @param planFrom yyyy-MM-dd
   * @param planTo   yyyy-MM-dd
   * @param opts     optional time window overrides
   */
  getDispatchDay(
    planFrom: string,
    planTo: string,
    opts?: DispatchDayOpts,
  ): Observable<DispatchDayReportRow[]> {
    const params = this.buildParams(planFrom, planTo, opts);
    return this.http
      .get<DispatchDayReportRow[]>(`${this.apiUrl}/dispatch/day`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError.bind(this)));
  }

  /**
   * Download Dispatch Day Report as CSV.
   */
  exportDispatchDay(planFrom: string, planTo: string, opts?: DispatchDayOpts): Observable<Blob> {
    const params = this.buildParams(planFrom, planTo, opts);
    return this.http
      .get(`${this.apiUrl}/dispatch/day/export`, {
        headers: this.getHeaders(),
        params,
        responseType: 'blob',
      })
      .pipe(catchError(this.handleError.bind(this)));
  }

  /**
   * Download Dispatch Day Report as Excel (.xlsx).
   */
  exportDispatchDayExcel(
    planFrom: string,
    planTo: string,
    opts?: DispatchDayOpts,
  ): Observable<Blob> {
    const params = this.buildParams(planFrom, planTo, opts);
    return this.http
      .get(`${this.apiUrl}/dispatch/day/export.xlsx`, {
        headers: this.getHeaders(),
        params,
        responseType: 'blob',
      })
      .pipe(catchError(this.handleError.bind(this)));
  }
}
