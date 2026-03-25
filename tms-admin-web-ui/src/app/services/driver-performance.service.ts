import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { DriverPerformance } from '../models/driver-performance.model';

@Injectable({
  providedIn: 'root',
})
export class DriverPerformanceService {
  constructor(private readonly http: HttpClient) {}

  private baseUrl(driverId: number): string {
    return `${environment.apiBaseUrl}/admin/drivers/${driverId}/performance`;
  }

  getCurrentPerformance(driverId: number) {
    return this.http.get<ApiResponse<DriverPerformance>>(`${this.baseUrl(driverId)}/current`);
  }

  getPerformanceHistory(driverId: number, months = 6) {
    return this.http.get<ApiResponse<DriverPerformance[]>>(`${this.baseUrl(driverId)}/history`, {
      params: { months: months.toString() },
    });
  }
}
