import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { MatSnackBar } from '@angular/material/snack-bar';
import { catchError, map, Observable, throwError } from 'rxjs';
import { environment } from '../../../environments/environment';

import type {
  DriverAlertsDto,
  DriverStatsDto,
  DriverSummaryDto,
  DriverStatusFilter,
  PermissionsDto,
} from './driver-overview.models';

import type { DriverComplianceDto } from './driver-compliance.dto';
import type { UncompliantDriverDto } from './uncompliant-driver.dto';
import type { ApiResponse } from '../../../models/api-response.model';

@Injectable({
  providedIn: 'root',
})
export class DriverOverviewService {
  private readonly http = inject(HttpClient);
  private readonly snackBar = inject(MatSnackBar);
  private readonly baseUrl = `${environment.apiBaseUrl}/admin/drivers/overview`;

  /* =====================================================
     DRIVER STATS (KPI)
  ===================================================== */
  getStats(): Observable<DriverStatsDto> {
    return this.http.get<ApiResponse<DriverStatsDto>>(`${this.baseUrl}/stats`).pipe(
      map((res) => this.normalizeStats(res.data)),
      catchError((error) => this.handleError('stats', error)),
    );
  }

  /* =====================================================
     DRIVER LIST (Supports Pagination + Filter + Search)
  ===================================================== */
  getDriverSummaries(
    status: DriverStatusFilter = 'ALL',
    query = '',
    page = 0,
    size = 20,
  ): Observable<DriverSummaryDto[]> {
    let params = new HttpParams().set('page', page).set('size', size);

    if (status && status !== 'ALL') {
      params = params.set('status', status);
    }

    if (query?.trim()) {
      params = params.set('q', query.trim());
    }

    return this.http.get<ApiResponse<DriverSummaryDto[]>>(`${this.baseUrl}/list`, { params }).pipe(
      map((res) => res.data),
      catchError((error) => this.handleError('driver list', error)),
    );
  }

  /* =====================================================
     DRIVER ALERTS
  ===================================================== */
  getAlerts(): Observable<DriverAlertsDto> {
    return this.http.get<ApiResponse<DriverAlertsDto>>(`${this.baseUrl}/alerts`).pipe(
      map((res) => res.data),
      catchError((error) => this.handleError('alerts', error)),
    );
  }

  /* =====================================================
     PERMISSIONS
  ===================================================== */
  getPermissions(): Observable<PermissionsDto> {
    return this.http.get<ApiResponse<PermissionsDto>>(`${this.baseUrl}/permissions`).pipe(
      map((res) => res.data),
      catchError((error) => this.handleError('permissions', error)),
    );
  }

  /* =====================================================
     DRIVER COMPLIANCE STATUS
  ===================================================== */
  getComplianceStatus(): Observable<DriverComplianceDto[]> {
    return this.http
      .get<ApiResponse<DriverComplianceDto[]>>(`${this.baseUrl}/compliance-status`)
      .pipe(
        map((res) => res.data),
        catchError((error) => this.handleError('compliance status', error)),
      );
  }

  getUncompliantDrivers(limit = 100): Observable<UncompliantDriverDto[]> {
    const params = new HttpParams().set('limit', limit);
    return this.http
      .get<ApiResponse<UncompliantDriverDto[]>>(`${this.baseUrl}/uncompliant-drivers`, { params })
      .pipe(
        map((res) => res.data),
        catchError((error) => this.handleError('uncompliant drivers', error)),
      );
  }

  /* =====================================================
     CENTRALIZED ERROR HANDLER
  ===================================================== */
  private handleError(operation: string, error: any) {
    console.error(`DriverOverviewService ${operation} error`, error);

    const message =
      error?.error?.message ||
      error?.error?.detail ||
      error?.message ||
      'Unexpected error occurred';

    this.snackBar.open(`Failed to load ${operation}: ${message}`, 'Close', { duration: 4000 });

    return throwError(() => error);
  }

  private normalizeStats(stats: DriverStatsDto): DriverStatsDto {
    return {
      totalDrivers: stats.totalDrivers ?? 0,
      svEmployees: stats.svEmployees ?? 0,
      partnerDrivers: stats.partnerDrivers ?? 0,
      exitDrivers: stats.exitDrivers ?? 0,
      activeDrivers: stats.activeDrivers ?? 0,
      suspendedDrivers: stats.suspendedDrivers ?? 0,
      onlineDrivers: stats.onlineDrivers ?? 0,
      onTripDrivers: stats.onTripDrivers ?? 0,
      offlineDrivers: stats.offlineDrivers ?? 0,
      expiredDocuments: stats.expiredDocuments ?? 0,
      nearExpiryDocuments: stats.nearExpiryDocuments ?? 0,
      utilizationRate: stats.utilizationRate ?? 0,
    };
  }
}
