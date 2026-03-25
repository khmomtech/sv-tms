import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';

export interface PmDashboardDto {
  okCount: number;
  dueSoonCount: number;
  overdueCount: number;
  openWorkOrders: number;
  totalCost: number;
  avgCost: number;
}

@Injectable({ providedIn: 'root' })
export class PmDashboardService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/pm/dashboard`;

  constructor(private readonly http: HttpClient) {}

  getDashboard() {
    return this.http.get<ApiResponse<PmDashboardDto>>(this.apiUrl);
  }
}
