import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';

@Injectable({ providedIn: 'root' })
export class MaintenanceReportService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/maintenance`;

  constructor(private readonly http: HttpClient) {}

  dashboard() {
    return this.http.get<ApiResponse<Record<string, any>>>(`${this.apiUrl}/dashboard`);
  }

  vehicleHistory(vehicleId: number, params: { page?: number; size?: number }) {
    let p = new HttpParams();
    if (typeof params.page === 'number') p = p.set('page', String(params.page));
    if (typeof params.size === 'number') p = p.set('size', String(params.size));
    return this.http.get<ApiResponse<Record<string, any>>>(
      `${this.apiUrl}/vehicles/${vehicleId}/history`,
      { params: p },
    );
  }

  costPerVehicle(limit = 20) {
    return this.http.get<ApiResponse<any[]>>(`${this.apiUrl}/reports/cost-per-vehicle`, {
      params: new HttpParams().set('limit', String(limit)),
    });
  }

  pmVsCorrective() {
    return this.http.get<ApiResponse<Record<string, any>>>(
      `${this.apiUrl}/reports/pm-vs-corrective`,
    );
  }

  breakdownsAfterPm(days = 30) {
    return this.http.get<ApiResponse<Record<string, any>>>(
      `${this.apiUrl}/reports/breakdowns-after-pm`,
      {
        params: new HttpParams().set('days', String(days)),
      },
    );
  }

  costByRepairType() {
    return this.http.get<ApiResponse<Record<string, any>>>(
      `${this.apiUrl}/reports/cost-by-repair-type`,
    );
  }

  costPerVehicleKm(limit = 20) {
    return this.http.get<ApiResponse<any[]>>(`${this.apiUrl}/reports/cost-per-vehicle-km`, {
      params: new HttpParams().set('limit', String(limit)),
    });
  }
}
