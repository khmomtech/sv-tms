import { HttpClient } from '@angular/common/http';
import { HttpHeaders } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import type { Observable } from 'rxjs';
import { BehaviorSubject, interval, switchMap, map, tap, catchError, of } from 'rxjs';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';

import { AuthService } from './auth.service';
import { SocketService } from './socket.service';

export interface AdminNotification {
  targetUrl: any;
  id: number;
  title: string;
  message: string;
  type: string;
  topic?: string;
  referenceId?: string;
  severity?: string;
  sender?: string;
  actionUrl?: string; //  New
  actionLabel?: string; //  New
  read: boolean;
  createdAt: string;
}

@Injectable({
  providedIn: 'root',
})
export class AdminNotificationService {
  private readonly baseUrl = `${environment.apiBaseUrl}/notifications/admin`;

  private readonly _unreadCount = new BehaviorSubject<number>(0);
  readonly unreadCount$ = this._unreadCount.asObservable();

  private readonly _realtimeNotification = new BehaviorSubject<AdminNotification | null>(null);
  readonly realtimeNotification$ = this._realtimeNotification.asObservable();

  // Use inject() to break circular dependency
  private readonly http = inject(HttpClient);
  private readonly authService = inject(AuthService);
  private readonly socketService = inject(SocketService);

  constructor() {
    this.pollUnreadCount();
    this.listenToWebSocket();
  }

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    });
  }

  getAll(): Observable<AdminNotification[]> {
    return this.http.get<AdminNotification[]>(this.baseUrl, {
      headers: this.getHeaders(),
    });
  }

  getUnreadList(): Observable<AdminNotification[]> {
    return this.http.get<AdminNotification[]>(`${this.baseUrl}/unread`, {
      headers: this.getHeaders(),
    });
  }

  markAsRead(id: number): Observable<any> {
    return this.http.put(
      `${this.baseUrl}/${id}/read`,
      {},
      {
        headers: this.getHeaders(),
      },
    );
  }

  markAll(): Observable<any> {
    return this.http.patch(
      `${this.baseUrl}/mark-all-read`,
      {},
      {
        headers: this.getHeaders(),
      },
    );
  }

  delete(id: number): Observable<any> {
    return this.http.delete(`${this.baseUrl}/${id}`, {
      headers: this.getHeaders(),
    });
  }

  clearAll(): Observable<any> {
    return this.http.delete(`${this.baseUrl}/all`, {
      headers: this.getHeaders(),
    });
  }

  /**  Create Admin Notification (includes target URL & label) */
  createNotification(payload: {
    title: string;
    message: string;
    type: string;
    topic?: string;
    referenceId?: string;
    severity?: string;
    sender?: string;
    actionUrl?: string; //  Used for clickable link
    actionLabel?: string; //  Label for the button/link
  }): Observable<any> {
    return this.http.post(`${this.baseUrl}/create`, payload, {
      headers: this.getHeaders(),
    });
  }

  /**  Shortcut method to send actionable notifications */
  sendActionableNotification(payload: {
    title: string;
    message: string;
    actionUrl: string;
    actionLabel?: string;
    type?: string;
    topic?: string;
    severity?: string;
    sender?: string;
  }): Observable<any> {
    return this.createNotification({
      ...payload,
      type: payload.type || 'admin',
      severity: payload.severity || 'info',
      sender: payload.sender || 'ADMIN_UI',
    });
  }

  /**  Driver-specific send methods */
  sendNotificationToDriver(payload: {
    driverId: number;
    title: string;
    message: string;
    type: string;
    severity: string;
    sender: string;
    referenceId?: string;
  }): Observable<any> {
    return this.http.post(`${environment.apiBaseUrl}/notifications/driver/send`, payload, {
      headers: this.getHeaders(),
    });
  }

  sendNotificationToAllDrivers(payload: {
    title: string;
    message: string;
    type: string;
    severity: string;
    topic: string;
    sender: string;
  }): Observable<any> {
    return this.http.post(`${environment.apiBaseUrl}/notifications/driver/broadcast`, payload, {
      headers: this.getHeaders(),
    });
  }

  /**  Poll unread count every 30s */
  private pollUnreadCount(): void {
    interval(30000)
      .pipe(
        switchMap(() => {
          const token = this.authService.getToken();
          if (!token || this.authService.isTokenExpired(token)) {
            // Don't make request if not authenticated
            return of(0);
          }
          return this.http
            .get<ApiResponse<number>>(`${this.baseUrl}/count`, {
              headers: this.getHeaders(),
            })
            .pipe(
              map((res) => res.data || 0),
              catchError((err) => {
                // Handle auth errors silently - the auth interceptor will handle token refresh
                if (err.status === 401 || err.status === 403) {
                  console.warn('🔕 Auth error during polling, skipping...');
                } else {
                  console.warn('🔕 Polling failed', err.message || err);
                }
                return of(0);
              }),
            );
        }),
        tap((count) => this._unreadCount.next(count)),
      )
      .subscribe();
  }

  /** 🔄 Manual refresh of unread count */
  public refreshUnreadCount(): void {
    const token = this.authService.getToken();
    if (!token) return;

    this.http
      .get<ApiResponse<number>>(`${this.baseUrl}/count`, {
        headers: this.getHeaders(),
      })
      .pipe(
        map((res) => res.data),
        catchError((err) => {
          console.warn('🔕 Manual refresh failed', err);
          return of(0);
        }),
        tap((count) => this._unreadCount.next(count)),
      )
      .subscribe();
  }

  /** 📡 Listen to WebSocket push notifications */
  private listenToWebSocket(): void {
    this.socketService.notification$.subscribe((notif: AdminNotification | null) => {
      if (notif) {
        this._realtimeNotification.next(notif);
        this._unreadCount.next(this._unreadCount.value + 1);
      }
    });
  }
}
