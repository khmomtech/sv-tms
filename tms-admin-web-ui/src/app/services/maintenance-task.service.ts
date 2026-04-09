import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { MaintenanceTask } from '../models/maintenance-task.model';
import type { Page } from '../models/page.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root',
})
export class MaintenanceTaskService {
  private apiUrl = `${environment.baseUrl}/api/admin/maintenance-tasks`;
  private defaultErrorMessage = 'Something went wrong. Please try again later.';

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  /** 🔐 Get auth token headers */
  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  // ────────────────────────────────────────────────────────────────────────────────
  //  CRUD METHODS
  // ────────────────────────────────────────────────────────────────────────────────

  /** 📄 Get paginated + filtered task list */
  getTasks(
    page: number = 0,
    size: number = 10,
    filters: {
      keyword?: string;
      status?: string;
      vehicleId?: number;
      dueBefore?: string;
      dueAfter?: string;
    } = {},
  ): Observable<ApiResponse<Page<MaintenanceTask>>> {
    let params = new HttpParams().set('page', String(page)).set('size', String(size));

    if (filters.keyword) params = params.set('keyword', filters.keyword);
    if (filters.status) params = params.set('status', filters.status);
    if (filters.vehicleId) params = params.set('vehicleId', filters.vehicleId.toString());
    if (filters.dueBefore) params = params.set('dueBefore', filters.dueBefore);
    if (filters.dueAfter) params = params.set('dueAfter', filters.dueAfter);

    return this.http
      .get<ApiResponse<Page<MaintenanceTask>>>(this.apiUrl, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  /** 📄 Get a single task by ID */
  getTaskById(id: number): Observable<ApiResponse<MaintenanceTask>> {
    return this.http
      .get<ApiResponse<MaintenanceTask>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** ➕ Create a new task */
  createTask(task: MaintenanceTask): Observable<ApiResponse<MaintenanceTask>> {
    return this.http
      .post<ApiResponse<MaintenanceTask>>(this.apiUrl, task, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** ✏️ Update an existing task */
  updateTask(id: number, task: MaintenanceTask): Observable<ApiResponse<MaintenanceTask>> {
    return this.http
      .put<ApiResponse<MaintenanceTask>>(`${this.apiUrl}/${id}`, task, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** 🗑 Delete task by ID */
  deleteTask(id: number): Observable<ApiResponse<void>> {
    return this.http
      .delete<ApiResponse<void>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  // ────────────────────────────────────────────────────────────────────────────────
  // ⚠️ Error Handling
  // ────────────────────────────────────────────────────────────────────────────────

  private handleError(error: HttpErrorResponse): Observable<never> {
    console.error(' API Error:', error);
    let errorMessage = this.defaultErrorMessage;

    if (error.error) {
      if (typeof error.error === 'string') {
        errorMessage = error.error;
      } else if (error.error.message) {
        errorMessage = error.error.message;
      } else if (error.error.errors) {
        errorMessage = Object.values(error.error.errors).join(', ');
      }
    } else {
      switch (error.status) {
        case 0:
          errorMessage = 'Unable to connect to the server.';
          break;
        case 400:
          errorMessage = 'Bad request.';
          break;
        case 401:
          errorMessage = 'Unauthorized.';
          break;
        case 403:
          errorMessage = 'Forbidden. You don’t have permission.';
          break;
        case 404:
          errorMessage = 'Not found.';
          break;
        case 500:
          errorMessage = 'Internal server error.';
          break;
      }
    }

    return throwError(() => new Error(errorMessage));
  }
}
