import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { environment } from '../environments/environment';
import { AuthService } from './auth.service';
import type {
  CustomerActivity,
  CustomerActivityRequest,
  CustomerHealthScore,
  CustomerInsights,
} from '../models/customer-activity.model';
import type { ApiResponse } from '../models/api-response.model';
import type { PageResult } from '../models/api-page-result.model';

@Injectable({
  providedIn: 'root',
})
export class CustomerActivityService {
  private readonly baseUrl = `${environment.baseUrl}/api/admin/customers`;

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      Authorization: token ? `Bearer ${token}` : '',
      'Content-Type': 'application/json',
    });
  }

  /**
   * Get activity timeline for a customer
   */
  getActivities(
    customerId: number,
    page = 0,
    size = 50,
  ): Observable<PageResult<CustomerActivity[]>> {
    const params = new HttpParams().set('page', page.toString()).set('size', size.toString());

    return this.http
      .get<
        ApiResponse<PageResult<CustomerActivity[]>>
      >(`${this.baseUrl}/${customerId}/activities`, { headers: this.getHeaders(), params })
      .pipe(
        map((res) => res.data),
        catchError(this.handleError),
      );
  }

  /**
   * Create a new activity log entry
   */
  createActivity(activity: CustomerActivityRequest): Observable<CustomerActivity> {
    return this.http
      .post<
        ApiResponse<CustomerActivity>
      >(`${this.baseUrl}/${activity.customerId}/activities`, activity, { headers: this.getHeaders() })
      .pipe(
        map((res) => res.data),
        catchError(this.handleError),
      );
  }

  /**
   * Add a note to customer timeline
   */
  addNote(customerId: number, title: string, description: string): Observable<CustomerActivity> {
    return this.createActivity({
      customerId,
      type: 'NOTE',
      title,
      description,
    });
  }

  /**
   * Log a call activity
   */
  logCall(
    customerId: number,
    title: string,
    notes: string,
    duration?: number,
  ): Observable<CustomerActivity> {
    return this.createActivity({
      customerId,
      type: 'CALL',
      title,
      description: notes,
      metadata: { durationMinutes: duration },
    });
  }

  /**
   * Log an email activity
   */
  logEmail(customerId: number, subject: string, body?: string): Observable<CustomerActivity> {
    return this.createActivity({
      customerId,
      type: 'EMAIL',
      title: subject,
      description: body,
    });
  }

  /**
   * Log a meeting activity
   */
  logMeeting(
    customerId: number,
    title: string,
    notes: string,
    attendees?: string[],
  ): Observable<CustomerActivity> {
    return this.createActivity({
      customerId,
      type: 'MEETING',
      title,
      description: notes,
      metadata: { attendees },
    });
  }

  /**
   * Get customer health score
   */
  getHealthScore(customerId: number): Observable<CustomerHealthScore> {
    return this.http
      .get<
        ApiResponse<CustomerHealthScore>
      >(`${this.baseUrl}/${customerId}/health-score`, { headers: this.getHeaders() })
      .pipe(
        map((res) => res.data),
        catchError(this.handleError),
      );
  }

  /**
   * Get customer insights and analytics
   */
  getInsights(customerId: number): Observable<CustomerInsights> {
    return this.http
      .get<
        ApiResponse<CustomerInsights>
      >(`${this.baseUrl}/${customerId}/insights`, { headers: this.getHeaders() })
      .pipe(
        map((res) => res.data),
        catchError(this.handleError),
      );
  }

  /**
   * Delete an activity
   */
  deleteActivity(customerId: number, activityId: number): Observable<void> {
    return this.http
      .delete<void>(`${this.baseUrl}/${customerId}/activities/${activityId}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  private handleError(error: any): Observable<never> {
    console.error('CustomerActivityService error:', error);
    return throwError(() => error);
  }
}
