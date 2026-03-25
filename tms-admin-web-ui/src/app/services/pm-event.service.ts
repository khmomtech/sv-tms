import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';

export type PmEventCode = 'FLOOD' | 'ACCIDENT' | 'OVERLOAD' | 'OTHER';

export interface PmEventRequest {
  vehicleId: number;
  eventCode: PmEventCode;
  occurredAt?: string;
  notes?: string;
}

@Injectable({ providedIn: 'root' })
export class PmEventService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/pm/events`;

  constructor(private readonly http: HttpClient) {}

  recordEvent(payload: PmEventRequest) {
    return this.http.post<ApiResponse<any>>(this.apiUrl, payload);
  }
}
