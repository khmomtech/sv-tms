import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { PmRunDto } from './pm-run.service';

export interface PmCalendarItemDto {
  date: string;
  runs: PmRunDto[];
}

@Injectable({ providedIn: 'root' })
export class PmCalendarService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/pm/calendar`;

  constructor(private readonly http: HttpClient) {}

  getCalendar(month: string) {
    const params = new HttpParams().set('month', month);
    return this.http.get<ApiResponse<PmCalendarItemDto[]>>(this.apiUrl, { params });
  }
}
