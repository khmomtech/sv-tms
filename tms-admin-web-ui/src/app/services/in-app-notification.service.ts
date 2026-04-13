import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import type { Observable } from 'rxjs';
import { BehaviorSubject, interval, map, catchError, of, switchMap, startWith } from 'rxjs';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import { AuthService } from './auth.service';

export interface InAppNotification {
  id: number;
  title: string;
  body: string;
  entityType?: string;
  entityId?: string;
  isRead: boolean;
  createdAt: string;
}

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

@Injectable({
  providedIn: 'root',
})
export class InAppNotificationService {
  private readonly http = inject(HttpClient);
  private readonly authService = inject(AuthService);
  private readonly baseUrl = `${environment.apiBaseUrl}/notifications/admin`;
  private readonly POLL_INTERVAL_MS = 30000;
  private readonly MAX_CONSECUTIVE_FAILURES = 3;
  private readonly FAILURE_COOLDOWN_MS = 60000;

  private readonly _unreadCount = new BehaviorSubject<number>(0);
  readonly unreadCount$ = this._unreadCount.asObservable();
  private consecutiveFailures = 0;
  private suppressedUntilMs = 0;

  constructor() {
    this.pollUnreadCount();
  }

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    });
  }

  list(
    page = 0,
    size = 20,
    filters?: {
      q?: string;
      unreadOnly?: boolean;
      fromDate?: string;
      toDate?: string;
    },
  ): Observable<ApiResponse<PageResponse<InAppNotification>>> {
    const params = new URLSearchParams();
    params.set('page', String(page));
    params.set('size', String(size));
    if (filters?.q) params.set('q', filters.q);
    if (filters?.unreadOnly) params.set('unreadOnly', 'true');
    if (filters?.fromDate) params.set('fromDate', filters.fromDate);
    if (filters?.toDate) params.set('toDate', filters.toDate);
    return this.http.get<ApiResponse<PageResponse<InAppNotification>>>(
      `${this.baseUrl}?${params.toString()}`,
      { headers: this.getHeaders() },
    );
  }

  markRead(id: number): Observable<ApiResponse<string>> {
    return this.http.put<ApiResponse<string>>(
      `${this.baseUrl}/${id}/read`,
      {},
      { headers: this.getHeaders() },
    );
  }

  markAllRead(): Observable<ApiResponse<string>> {
    return this.http.patch<ApiResponse<string>>(
      `${this.baseUrl}/mark-all-read`,
      {},
      { headers: this.getHeaders() },
    );
  }

  countUnread(): Observable<ApiResponse<number>> {
    return this.http.get<ApiResponse<number>>(`${this.baseUrl}/count`, {
      headers: this.getHeaders(),
    });
  }

  private pollUnreadCount(): void {
    interval(this.POLL_INTERVAL_MS)
      .pipe(
        startWith(0),
        switchMap(() => {
          const now = Date.now();
          const token = this.authService.getToken();
          if (!token || this.authService.isTokenExpired(token)) {
            return of(this._unreadCount.value);
          }
          if (this.suppressedUntilMs > now) {
            return of(this._unreadCount.value);
          }
          return this.countUnread().pipe(
            map((res) => {
              this.consecutiveFailures = 0;
              this.suppressedUntilMs = 0;
              return res?.data ?? 0;
            }),
            catchError(() => {
              this.consecutiveFailures += 1;
              if (this.consecutiveFailures >= this.MAX_CONSECUTIVE_FAILURES) {
                this.consecutiveFailures = 0;
                this.suppressedUntilMs = Date.now() + this.FAILURE_COOLDOWN_MS;
                console.warn(
                  `[InAppNotificationService] Pausing unread-count polling for ${Math.round(this.FAILURE_COOLDOWN_MS / 1000)}s after repeated failures.`,
                );
              }
              return of(this._unreadCount.value);
            }),
          );
        }),
      )
      .subscribe((count) => this._unreadCount.next(count));
  }
}
