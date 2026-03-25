import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import type { Observable } from 'rxjs';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import { AuthService } from './auth.service';

export interface NotificationSetting {
  id?: number;
  channel: 'TELEGRAM' | 'EMAIL' | 'IN_APP';
  enabled: boolean;
  thresholdDays?: number;
  thresholdKm?: number;
  recipientsJson?: string;
}

@Injectable({
  providedIn: 'root',
})
export class NotificationSettingsService {
  private readonly http = inject(HttpClient);
  private readonly authService = inject(AuthService);
  private readonly baseUrl = `${environment.apiBaseUrl}/admin/notification-settings`;

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    });
  }

  list(): Observable<ApiResponse<NotificationSetting[]>> {
    return this.http.get<ApiResponse<NotificationSetting[]>>(this.baseUrl, {
      headers: this.getHeaders(),
    });
  }

  update(
    channel: string,
    payload: NotificationSetting,
  ): Observable<ApiResponse<NotificationSetting>> {
    return this.http.put<ApiResponse<NotificationSetting>>(`${this.baseUrl}/${channel}`, payload, {
      headers: this.getHeaders(),
    });
  }
}
