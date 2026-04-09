import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { catchError, throwError } from 'rxjs';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { MaintenanceTaskType } from '../models/maintenance-task-type.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

export interface PagedResult<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

@Injectable({
  providedIn: 'root',
})
export class MaintenanceTaskTypeService {
  private readonly apiUrl = `${environment.baseUrl}/api/admin/maintenance-task-types`;
  private readonly defaultErrorMessage = 'Something went wrong. Please try again later.';

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  /** 🔐 Auth headers */
  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  // ─────────────────────────────────────────────
  // CRUD OPERATIONS
  // ─────────────────────────────────────────────

  /** 🌍 Get paginated + filtered task types */
  getAllPaged(
    search: string = '',
    page: number = 0,
    size: number = 10,
  ): Observable<ApiResponse<PagedResult<MaintenanceTaskType>>> {
    const params = new HttpParams()
      .set('search', search)
      .set('page', page.toString())
      .set('size', size.toString());

    return this.http
      .get<ApiResponse<PagedResult<MaintenanceTaskType>>>(`${this.apiUrl}/list`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  /** 🌍 Get all without pagination */
  getAll(): Observable<ApiResponse<MaintenanceTaskType[]>> {
    return this.http
      .get<ApiResponse<MaintenanceTaskType[]>>(`${this.apiUrl}/all`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** 🔍 Get by ID */
  getById(id: number): Observable<ApiResponse<MaintenanceTaskType>> {
    return this.http
      .get<ApiResponse<MaintenanceTaskType>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** ➕ Create new task type */
  create(data: Partial<MaintenanceTaskType>): Observable<ApiResponse<MaintenanceTaskType>> {
    return this.http
      .post<ApiResponse<MaintenanceTaskType>>(this.apiUrl, data, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** ✏️ Update task type */
  update(
    id: number,
    data: Partial<MaintenanceTaskType>,
  ): Observable<ApiResponse<MaintenanceTaskType>> {
    return this.http
      .put<ApiResponse<MaintenanceTaskType>>(`${this.apiUrl}/${id}`, data, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** 🗑️ Delete task type */
  delete(id: number): Observable<ApiResponse<void>> {
    return this.http
      .delete<ApiResponse<void>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  // ─────────────────────────────────────────────
  // ⚠️ Error Handling
  // ─────────────────────────────────────────────

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
          errorMessage = 'Cannot connect to server. Please check your internet connection.';
          break;
        case 400:
          errorMessage = 'Invalid input. Please correct the form.';
          break;
        case 401:
          errorMessage = 'Unauthorized. Please log in.';
          break;
        case 403:
          errorMessage = 'Access denied.';
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
