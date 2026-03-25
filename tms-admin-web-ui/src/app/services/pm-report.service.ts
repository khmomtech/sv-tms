import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';

export interface PmTopCostDto {
  workOrderId?: number;
  workOrderNumber?: string;
  vehicleId?: number;
  vehiclePlate?: string;
  actualCost?: number;
}

export interface PmDowntimeDto {
  vehicleId?: number;
  vehiclePlate?: string;
  startAt?: string;
  endAt?: string;
  reason?: string;
}

export interface PmReportSummaryDto {
  completionRate: number;
  overdueRate: number;
  totalPmCost: number;
  topCosts: PmTopCostDto[];
  downtime: PmDowntimeDto[];
}

@Injectable({ providedIn: 'root' })
export class PmReportService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/pm/reports/summary`;

  constructor(private readonly http: HttpClient) {}

  getSummary() {
    return this.http.get<ApiResponse<PmReportSummaryDto>>(this.apiUrl);
  }
}
